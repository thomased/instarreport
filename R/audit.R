# Coverage across a corpus of studies.
#
# Two ways in. Prospectively, studies deposit completed INSTAR sheets and
# a corpus is just those files: instar_audit("supplements/"). Retrospect-
# ively, someone scores a set of papers that predate the framework and
# has no sheets at all, only a wide matrix of one row per paper and one
# column per item; audit_from_matrix() turns that into the same object.

#' Audit reporting coverage across many studies
#'
#' Summarises how consistently a set of studies reported each framework
#' item. This is the corpus-level view: [instar_report()] describes one
#' study, `instar_audit()` describes a literature.
#'
#' @param x What to audit. Any of:
#'   * a path to a directory of sheets, or a vector of file paths, which
#'     are read with [read_instar()];
#'   * an `instar_corpus`;
#'   * a list of `instar_report` objects, or of items tables;
#'   * a data frame of scores in wide form, passed to
#'     [audit_from_matrix()].
#' @param ... Passed to [read_instar()] when `x` is a path, or to
#'   [audit_from_matrix()] when `x` is a data frame.
#'
#' @return An object of class `instar_audit`: a list with
#'   * `items`, one row per framework item with counts and the percentage
#'     of applicable studies that reported it;
#'   * `studies`, one row per study with its own coverage (as
#'     [summary.instar_corpus()] returns);
#'   * `long`, one row per study-item pair, the tidy form to compute on;
#'   * `n`, the number of studies.
#'
#' @seealso [read_instar()] to build a corpus, [audit_from_matrix()] for
#'   retrospective scoring.
#'
#' @examples
#' \dontrun{
#' # Prospective: a folder of deposited sheets
#' audit <- instar_audit("supplements/")
#' audit
#' summary(audit)
#' plot(audit)
#'
#' # Which items does the literature handle worst?
#' head(summary(audit)[order(summary(audit)$percent_reported), ])
#' }
#'
#' @export
instar_audit <- function(x, ...) {
  if (is.data.frame(x)) return(audit_from_matrix(x, ...))
  corpus <- as_instar_corpus(x, ...)
  if (length(corpus) == 0L) {
    cli::cli_abort("Nothing to audit: the corpus is empty.")
  }

  long <- do.call(rbind, lapply(seq_along(corpus), function(i) {
    d <- as.data.frame(corpus[[i]]$items)
    data.frame(
      study   = names(corpus)[i],
      item_id = d$item_id,
      item    = d$item,
      domain  = d$domain,
      group   = d$group,
      status  = .as_status(d$status),
      stringsAsFactors = FALSE
    )
  }))
  rownames(long) <- NULL

  .new_audit(long = long,
             studies = summary(corpus),
             meta = NULL,
             corpus = corpus)
}


#' Build an audit from a wide matrix of scores
#'
#' For auditing studies that never completed an INSTAR sheet, which is
#' every study published before the framework existed. The usual shape is
#' one row per paper, one column per framework item, scored by a reader.
#'
#' Columns whose names match an `item_id` in [instar_items] are treated
#' as items. Every other column is carried through as study metadata, so
#' a `journal` or `year` column in the input becomes a grouping variable
#' in `summary(audit, by = )` without any further work.
#'
#' Cell values are read leniently, because scoring sheets are made by
#' people: `Y`, `yes`, `TRUE`, and `1` all mean reported; `N`, `no`,
#' `FALSE`, and `0` mean not reported; `NA`, `N/A`, `-`, and empty cells
#' mean not applicable. `C` (conditional) counts as reported, matching
#' the framework's applicability codes.
#'
#' @param scores A data frame in wide form.
#' @param id Optional name of the column identifying each study. If
#'   omitted, the first non-item column is used, and failing that the row
#'   number.
#'
#' @return An object of class `instar_audit`.
#'
#' @examples
#' scores <- data.frame(
#'   doi = c("10.1/a", "10.1/b"),
#'   journal = c("J Exp Biol", "Behav Ecol"),
#'   subjects_taxon = c("Y", "Y"),
#'   subjects_n = c("Y", "N"),
#'   env_field = c("NA", "Y")
#' )
#' audit <- audit_from_matrix(scores, id = "doi")
#' summary(audit)
#'
#' @export
audit_from_matrix <- function(scores, id = NULL) {
  scores <- as.data.frame(scores, stringsAsFactors = FALSE)
  item_cols <- intersect(names(scores), instar_items$item_id)
  if (length(item_cols) == 0L) {
    cli::cli_abort(c(
      "None of the columns in {.arg scores} match a framework {.field item_id}.",
      "i" = "Expected names drawn from {.code instar_items$item_id}, for
             example {.val {utils::head(instar_items$item_id, 3)}}."
    ))
  }
  meta_cols <- setdiff(names(scores), item_cols)

  if (!is.null(id)) {
    if (!id %in% names(scores)) {
      cli::cli_abort(c(
        "{.arg id} column not found: {.val {id}}.",
        "i" = "Available: {.val {names(scores)}}."
      ))
    }
    study <- as.character(scores[[id]])
  } else if (length(meta_cols) > 0L) {
    study <- as.character(scores[[meta_cols[1]]])
  } else {
    study <- as.character(seq_len(nrow(scores)))
  }

  # Say so before disambiguating. A repeated id usually means either the
  # same study scored twice, or a column that does not actually identify
  # a study (a DOI that failed to extract for some rows, say). Both are
  # worth knowing about; silently suffixing them is not.
  study[is.na(study)] <- ""
  dup <- unique(study[duplicated(study)])
  if (length(dup) > 0L) {
    id_col <- id %||% meta_cols[1]
    shown <- utils::head(ifelse(nzchar(dup), dup, "<blank>"), 5)
    more <- if (length(dup) > 5L) length(dup) - 5L else 0L
    hint <- if (any(!nzchar(dup))) {
      "A blank id usually means the column is incomplete rather than that
       those rows are duplicates: pick a column that identifies every row."
    } else {
      "Check they are not the same study scored twice."
    }
    cli::cli_warn(c(
      "{cli::qty(dup)}Duplicate study identifier{?s} in {.field {id_col}}: {.val {shown}}.",
      if (more > 0L) c("i" = "...and {more} more."),
      "i" = "They have been made unique, so each row still counts as its own study.",
      "!" = hint
    ))
  }
  study <- make.unique(study, sep = "_")

  meta <- if (length(meta_cols) > 0L) {
    cbind(data.frame(study = study, stringsAsFactors = FALSE),
          scores[, meta_cols, drop = FALSE])
  } else {
    data.frame(study = study, stringsAsFactors = FALSE)
  }
  rownames(meta) <- NULL

  ref <- instar_items[, c("item_id", "item", "domain", "group")]
  long <- do.call(rbind, lapply(item_cols, function(col) {
    data.frame(
      study   = study,
      item_id = col,
      status  = .score_status(scores[[col]]),
      stringsAsFactors = FALSE
    )
  }))
  long <- merge(long, ref, by = "item_id", all.x = TRUE, sort = FALSE)
  long$status <- .as_status(long$status)
  long <- long[, c("study", "item_id", "item", "domain", "group", "status")]
  rownames(long) <- NULL

  # Items absent from the matrix were not scored at all. Leaving them out
  # is right: recording them as not-reported would assert something the
  # scoring never checked.
  unscored <- setdiff(instar_items$item_id, item_cols)
  if (length(unscored) > 0L) {
    cli::cli_inform(c(
      "i" = "{length(unscored)} framework item{?s} not present in {.arg scores}
             and left out of the audit: {.field {unscored}}."
    ))
  }

  studies <- .studies_from_long(long, meta)
  .new_audit(long = long, studies = studies, meta = meta, corpus = NULL)
}


#' Coerce a scoring column to canonical statuses
#' @keywords internal
.score_status <- function(x) {
  v <- toupper(trimws(as.character(x)))
  out <- rep(NA_character_, length(v))
  out[v %in% c("Y", "YES", "TRUE", "T", "1", "C", "REPORTED")] <- "reported"
  out[v %in% c("N", "NO", "FALSE", "F", "0", "NOT_REPORTED")] <- "not_reported"
  out[is.na(v) | v %in% c("", "NA", "N/A", "-", "NOT_APPLICABLE")] <-
    "not_applicable"
  bad <- unique(v[is.na(out)])
  if (length(bad) > 0L) {
    cli::cli_warn(c(
      "{cli::qty(bad)}Unrecognised score value{?s}: {.val {bad}}.",
      "!" = "Treated as not reported. Check the scoring table."
    ))
    out[is.na(out)] <- "not_reported"
  }
  factor(out, levels = .STATUS_LEVELS)
}


#' Per-study coverage from the long table
#' @keywords internal
.studies_from_long <- function(long, meta = NULL) {
  parts <- split(long, long$study)
  rows <- lapply(names(parts), function(s) {
    cov <- .coverage(parts[[s]]$status)
    data.frame(study = s, reported = cov$reported,
               not_reported = cov$not_reported,
               not_applicable = cov$not_applicable,
               applicable = cov$applicable,
               percent_reported = cov$percent_reported,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  if (!is.null(meta)) out <- merge(meta, out, by = "study", sort = FALSE)
  rownames(out) <- NULL
  out
}


#' Assemble an instar_audit from its parts
#' @keywords internal
.new_audit <- function(long, studies, meta, corpus) {
  parts <- split(long, long$item_id)
  rows <- lapply(names(parts), function(id) {
    p <- parts[[id]]
    cov <- .coverage(p$status)
    data.frame(
      item_id          = id,
      item             = p$item[1],
      domain           = p$domain[1],
      group            = p$group[1],
      n_studies        = nrow(p),
      reported         = cov$reported,
      not_reported     = cov$not_reported,
      not_applicable   = cov$not_applicable,
      applicable       = cov$applicable,
      percent_reported = cov$percent_reported,
      stringsAsFactors = FALSE
    )
  })
  items <- do.call(rbind, rows)
  # Canonical framework order, so the audit reads like the figure.
  items <- items[order(match(items$item_id, instar_items$item_id)), ,
                 drop = FALSE]
  rownames(items) <- NULL

  structure(
    list(items = items, studies = studies, long = long,
         meta = meta, corpus = corpus,
         n = length(unique(long$study))),
    class = "instar_audit"
  )
}


#' Print an audit
#'
#' @param x An `instar_audit`.
#' @param n Number of worst-reported items to list. Defaults to 5.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.instar_audit <- function(x, n = 5, ...) {
  cat("<instar_audit>\n")
  cat(sprintf("  %d studies, %d framework items\n",
              x$n, nrow(x$items)))

  pct <- x$studies$percent_reported
  pct <- pct[!is.na(pct)]
  if (length(pct) > 0L) {
    cat(sprintf("  median study coverage %.0f%% (range %.0f-%.0f%%)\n",
                stats::median(pct), min(pct), max(pct)))
  }

  worst <- x$items[order(x$items$percent_reported), , drop = FALSE]
  worst <- utils::head(worst[!is.na(worst$percent_reported), , drop = FALSE], n)
  if (nrow(worst) > 0L) {
    cat(sprintf("\n  Least often reported:\n"))
    for (i in seq_len(nrow(worst))) {
      cat(sprintf("    %5.0f%%  %s\n",
                  worst$percent_reported[i], worst$item[i]))
    }
  }
  cat("\n  summary() for all items; summary(by = ) to group; plot() to draw.\n")
  invisible(x)
}


#' Summarise an audit
#'
#' With no `by`, returns one row per framework item. With `by`, returns
#' one row per item per group, where `by` names a column of study
#' metadata: `"journal"` for a corpus read from sheets, or any column
#' that came along in the scoring matrix.
#'
#' @param object An `instar_audit`.
#' @param by Optional name of a study-level column to group by.
#' @param ... Unused.
#'
#' @return A data frame.
#'
#' @examples
#' \dontrun{
#' summary(audit)
#' summary(audit, by = "journal")
#' }
#'
#' @export
summary.instar_audit <- function(object, by = NULL, ...) {
  if (is.null(by)) return(object$items)

  if (!by %in% names(object$studies)) {
    cli::cli_abort(c(
      "No study-level column called {.field {by}}.",
      "i" = "Available: {.field {setdiff(names(object$studies),
             c(\"reported\", \"not_reported\", \"not_applicable\",
               \"applicable\", \"percent_reported\"))}}."
    ))
  }

  key <- object$studies[, unique(c("study", by)), drop = FALSE]
  d <- merge(object$long, key, by = "study", sort = FALSE)

  # Studies missing the grouping value still belong in the audit; give
  # them a visible label rather than dropping them out of the split.
  grp <- d[[by]]
  if (anyNA(grp)) {
    grp <- as.character(grp)
    grp[is.na(grp)] <- "(not given)"
  }
  d[[by]] <- grp

  parts <- split(d, list(d[[by]], d$item_id), drop = TRUE)
  rows <- lapply(parts, function(p) {
    cov <- .coverage(p$status)
    out <- data.frame(
      item_id          = p$item_id[1],
      item             = p$item[1],
      domain           = p$domain[1],
      n_studies        = nrow(p),
      reported         = cov$reported,
      applicable       = cov$applicable,
      percent_reported = cov$percent_reported,
      stringsAsFactors = FALSE
    )
    out[[by]] <- p[[by]][1]
    out[, c(by, setdiff(names(out), by))]
  })
  out <- do.call(rbind, rows)
  out <- out[order(out[[by]], match(out$item_id, instar_items$item_id)), ,
             drop = FALSE]
  rownames(out) <- NULL
  out
}


#' Plot reporting coverage across a corpus
#'
#' A horizontal bar for each framework item, showing the percentage of
#' applicable studies that reported it, in canonical framework order and
#' coloured by group. This is the corpus-level counterpart to the
#' single-study figure drawn by [plot.instar_report()].
#'
#' @param x An `instar_audit`.
#' @param ... Passed to [autoplot()][autoplot.instar_audit].
#' @return `x`, invisibly.
#' @export
plot.instar_audit <- function(x, ...) {
  print(ggplot2::autoplot(x, ...))
  invisible(x)
}


#' Return an audit's figure as a plot object
#'
#' @param object An `instar_audit`.
#' @param by Optional study-level column to facet by.
#' @param ... Unused.
#' @return A ggplot object.
#' @importFrom ggplot2 autoplot
#' @export
autoplot.instar_audit <- function(object, by = NULL, ...) {
  d <- summary(object, by = by)
  # droplevels so a partial audit (a scoring matrix covering only some
  # items) does not draw eighteen rows with fifteen of them empty.
  d$item <- droplevels(factor(d$item, levels = rev(instar_items$item)))
  if (is.null(d$group)) {
    d$group <- instar_items$group[match(d$item_id, instar_items$item_id)]
  }

  p <- ggplot2::ggplot(
    d,
    ggplot2::aes(x = percent_reported, y = item, fill = group)
  ) +
    ggplot2::geom_col(width = 0.7) +
    ggplot2::scale_fill_manual(
      values = c(welfare = .palette$welfare, foundation = .palette$foundation),
      labels = c(welfare = "Welfare domain", foundation = "Foundation"),
      name = NULL
    ) +
    ggplot2::scale_x_continuous(
      limits = c(0, 100), expand = ggplot2::expansion(mult = c(0, 0.02)),
      labels = function(v) paste0(v, "%")
    ) +
    ggplot2::labs(
      x = "Studies reporting the item (% of applicable)",
      y = NULL,
      title = sprintf("INSTAR reporting coverage across %d studies", object$n)
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),
      legend.position    = "bottom",
      plot.title.position = "plot"
    )

  if (!is.null(by)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", by)))
  }
  p
}

# Silence R CMD check NOTEs about non-standard evaluation in aes()
utils::globalVariables(c("percent_reported", "item", "group"))
