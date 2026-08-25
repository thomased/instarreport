# Methods for instar_corpus, the type-stable result of read_instar().
#
# A corpus is a named list of instar_report objects. Keeping it a plain
# list means lapply(), Filter(), Map() and friends all work on it without
# any special handling; these methods exist so that the class survives
# subsetting and so printing one is informative.

#' Build a corpus from a list of reports
#'
#' @param x A list of `instar_report` objects.
#' @return An `instar_corpus`.
#' @keywords internal
new_instar_corpus <- function(x) {
  bad <- !vapply(x, inherits, logical(1), "instar_report")
  if (any(bad)) {
    stop("All elements must be instar_report objects. Offending element(s): ",
         paste(which(bad), collapse = ", "), call. = FALSE)
  }
  # Guard the empty case: paste0() recycles a zero-length argument to "",
  # so paste0("study_", seq_along(list())) is "study_" -- length 1, which
  # will not fit a length-0 vector.
  if (is.null(names(x)) && length(x) > 0L) {
    names(x) <- paste0("study_", seq_along(x))
  }
  structure(x, class = "instar_corpus",
            failed = attr(x, "failed") %||%
              data.frame(file = character(0), error = character(0),
                         stringsAsFactors = FALSE))
}


#' Coerce to an instar_corpus
#'
#' Accepts anything [instar_audit()] will take as a corpus: an existing
#' corpus, a list of reports or items tables, or a path to read.
#'
#' @param x An object to coerce.
#' @param ... Passed to [read_instar()] when `x` is a path.
#' @return An `instar_corpus`.
#' @keywords internal
as_instar_corpus <- function(x, ...) {
  if (inherits(x, "instar_corpus")) return(x)
  if (inherits(x, "instar_report")) return(new_instar_corpus(list(x)))
  if (is.character(x)) return(read_instar(x, ...))
  if (is.list(x)) {
    # A list of items tables is a reasonable thing to hand in; promote
    # each to a report so the corpus is homogeneous.
    x <- lapply(seq_along(x), function(i) {
      el <- x[[i]]
      if (inherits(el, "instar_report")) return(el)
      nm <- names(x)[i] %||% paste0("study_", i)
      paper <- attr(el, "paper") %||% list()
      paper <- utils::modifyList(list(title = nm, authors = "Not given"), paper)
      instar_report(el, paper = paper, strict = FALSE)
    })
    return(new_instar_corpus(x))
  }
  stop("Cannot treat this as a corpus of INSTAR sheets. Supply a path, ",
       "a list of reports, or the result of read_instar().", call. = FALSE)
}


#' Print an INSTAR corpus
#'
#' @param x An `instar_corpus`.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.instar_corpus <- function(x, ...) {
  n <- length(x)
  cat("<instar_corpus>\n")
  if (n == 0L) {
    cat("  empty\n")
    return(invisible(x))
  }
  vers <- .corpus_versions(x)
  cat(sprintf("  %d sheet%s, INSTAR %s\n", n, if (n == 1L) "" else "s",
              paste(vers, collapse = " + ")))

  pct <- vapply(x, function(r) r$coverage$percent_reported, numeric(1))
  pct <- pct[!is.na(pct)]
  if (length(pct) > 0L) {
    cat(sprintf("  median coverage %.0f%% (range %.0f-%.0f%%)\n",
                stats::median(pct), min(pct), max(pct)))
  }

  failed <- attr(x, "failed")
  if (!is.null(failed) && nrow(failed) > 0L) {
    cat(sprintf("  %d file%s failed to read; see attr(., \"failed\")\n",
                nrow(failed), if (nrow(failed) == 1L) "" else "s"))
  }
  cat("  summary() for per-sheet coverage; instar_audit() for item-level.\n")
  invisible(x)
}


#' Per-sheet summary of a corpus
#'
#' One row per sheet, with its coverage. For coverage broken down by
#' framework item across the whole corpus, use [instar_audit()].
#'
#' @param object An `instar_corpus`.
#' @param ... Unused.
#'
#' @return A data frame with columns `study`, `title`, `journal`, `doi`,
#'   `version`, `folder` (the directory the sheet was read from, relative
#'   to what was asked for), `reported`, `not_reported`,
#'   `not_applicable`, `applicable`, and `percent_reported`.
#'
#' @examples
#' \dontrun{
#' corpus <- read_instar("supplements/")
#' head(summary(corpus))
#' }
#'
#' @export
summary.instar_corpus <- function(object, ...) {
  if (length(object) == 0L) {
    return(data.frame(study = character(0), title = character(0),
                      journal = character(0), doi = character(0),
                      version = character(0), folder = character(0),
                      reported = integer(0),
                      not_reported = integer(0), not_applicable = integer(0),
                      applicable = integer(0), percent_reported = numeric(0),
                      stringsAsFactors = FALSE))
  }
  chr <- function(v) if (is.null(v) || is.na(v)) NA_character_ else as.character(v)
  rows <- lapply(seq_along(object), function(i) {
    r <- object[[i]]
    cov <- r$coverage
    data.frame(
      study            = names(object)[i],
      title            = chr(r$paper$title),
      journal          = chr(r$paper$journal),
      doi              = chr(r$paper$doi),
      version          = chr(r$version),
      folder           = chr(r$folder),
      reported         = cov$reported,
      not_reported     = cov$not_reported,
      not_applicable   = cov$not_applicable,
      applicable       = cov$applicable,
      percent_reported = cov$percent_reported,
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}


#' Subset a corpus
#'
#' Keeps the `instar_corpus` class, so that `corpus[1:10]` and
#' `corpus[sapply(corpus, f)]` still print and audit as corpora.
#'
#' @param x An `instar_corpus`.
#' @param i Index.
#' @return An `instar_corpus`.
#' @export
`[.instar_corpus` <- function(x, i) {
  out <- NextMethod()
  structure(out, class = "instar_corpus",
            failed = attr(x, "failed"), path = attr(x, "path"))
}


#' Combine corpora
#'
#' Concatenates corpora read from different places, re-checking for
#' duplicate DOIs and mixed framework versions across the combined set.
#'
#' @param ... `instar_corpus` objects, or anything [as_instar_corpus()]
#'   accepts.
#' @return An `instar_corpus`.
#'
#' @examples
#' \dontrun{
#' corpus <- c(read_instar("2025/"), read_instar("2026/"))
#' }
#'
#' @export
c.instar_corpus <- function(...) {
  parts <- lapply(list(...), as_instar_corpus)
  reports <- do.call(c, lapply(parts, function(p) unclass(p)))
  failed <- do.call(rbind, lapply(parts, attr, "failed"))
  if (is.null(failed)) {
    failed <- data.frame(file = character(0), error = character(0),
                         stringsAsFactors = FALSE)
  }
  names(reports) <- make.unique(names(reports), sep = "_")
  out <- structure(reports, class = "instar_corpus", failed = failed)
  .warn_version_mix(out)
  .warn_duplicate_dois(out)
  out
}


#' Distinct framework versions in a corpus, for display
#' @keywords internal
.corpus_versions <- function(x) {
  v <- vapply(x, function(r) {
    out <- r$version
    if (is.null(out) || is.na(out)) NA_character_ else as.character(out)
  }, character(1))
  known <- sort(unique(stats::na.omit(v)))
  if (length(known) == 0L) return("version not declared")
  if (anyNA(v)) c(paste0("v", known), "some not declared")
  else paste0("v", known)
}
