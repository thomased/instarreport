# Bulk loading of INSTAR sheets.
#
# The design follows pavo's getspec() / lightr's lr_get_spec(): one entry
# point that takes a file, a directory, or a vector of either, works out
# the format itself, and returns a single type-stable object whatever it
# was pointed at. The behaviour that makes that usable on real corpora is
# tolerance -- one malformed file in two hundred warns and is skipped
# rather than aborting the run.

#' Read INSTAR sheets from disk
#'
#' Reads one or many completed INSTAR sheets and returns them as a single
#' `instar_corpus`. Point it at a file, a directory, or any mix of both:
#' the format is worked out from the file extension, and the result has
#' the same class whether it found one sheet or two hundred.
#'
#' A file that cannot be read does not stop the run. It is reported in a
#' warning, left out of the corpus, and recorded with its error message
#' in the `failed` attribute, so a single corrupt supplement in a large
#' corpus is a thing to go and look at rather than a dead end.
#'
#' ```r
#' corpus <- read_instar("supplements/")
#' attr(corpus, "failed")     # what could not be read, and why
#' ```
#'
#' # Naming
#'
#' Sheets are named by their DOI where the reserved rows carry one, and
#' by file name otherwise. Duplicate DOIs are warned about but kept: the
#' same study reaching a corpus twice through different routes will
#' otherwise inflate coverage estimates silently.
#'
#' # Framework versions
#'
#' Each sheet declares the framework version it was completed against.
#' A corpus mixing versions is warned about, because coverage is not
#' comparable across them: an item absent from half the sheets because it
#' did not exist yet is not the same as an item those studies failed to
#' report. Sheets written before versioning declare nothing and read as
#' `NA`.
#'
#' @param where A file path, a directory, or a character vector of
#'   either. Directories are searched for readable sheets.
#' @param pattern Optional regular expression to filter file names within
#'   directories. Applied after the extension filter.
#' @param recursive Logical; search directories recursively. Defaults to
#'   `FALSE`.
#' @param subdir_names Logical; when recursing, prefix each sheet's name
#'   with its directory path relative to `where`. Useful when a corpus is
#'   organised into folders that mean something (by journal, by year), as
#'   the prefix then survives into [instar_audit()] as a grouping
#'   variable. Defaults to `FALSE`.
#' @param ext File extensions to accept. Defaults to `c("csv", "xlsx")`.
#'   Reading `.xlsx` requires the \pkg{readxl} package.
#' @param quiet Logical; suppress the progress messages. Defaults to
#'   `FALSE`.
#' @param unknown Passed to [instar_report()]. Defaults to `"drop"`, so
#'   that a sheet carrying an unrecognised `item_id` (a hand-edited row,
#'   a later framework version) warns rather than failing the whole
#'   corpus.
#'
#' @return An object of class `instar_corpus`: a named list of
#'   `instar_report` objects, with attributes `failed` (a data frame of
#'   unreadable files and their error messages) and `path` (what was
#'   asked for).
#'
#' @seealso [read_items()] for a single sheet as an items table,
#'   [instar_audit()] for coverage across a corpus.
#'
#' @examples
#' \dontrun{
#' # A directory of deposited supplements
#' corpus <- read_instar("supplements/")
#'
#' # Organised by journal, with the folder kept as a grouping variable
#' corpus <- read_instar("corpus/", recursive = TRUE, subdir_names = TRUE)
#'
#' # A single sheet, still a corpus of one
#' corpus <- read_instar("INSTAR.csv")
#' }
#'
#' @export
read_instar <- function(where,
                        pattern = NULL,
                        recursive = FALSE,
                        subdir_names = FALSE,
                        ext = c("csv", "xlsx"),
                        quiet = FALSE,
                        unknown = c("drop", "error")) {
  unknown <- rlang::arg_match(unknown)
  if (!is.character(where) || length(where) == 0L) {
    cli::cli_abort("{.arg where} must be a character vector of file or
                    directory paths, not {.obj_type_friendly {where}}.")
  }
  ext <- tolower(sub("^\\.", "", ext))

  files <- .collect_files(where, pattern = pattern, recursive = recursive,
                          ext = ext)
  if (length(files$path) == 0L) {
    cli::cli_abort(c(
      "No INSTAR sheets found in {.file {where}}.",
      "i" = "Looked for files ending in {.val {paste0(\".\", ext)}}.",
      if (!recursive) c("i" = "Use {.code recursive = TRUE} to search
                              subdirectories.")
    ))
  }

  n <- length(files$path)
  if (!quiet) {
    cli::cli_inform("Reading {n} file{?s}...")
  }
  pb <- if (!quiet && n > 1L) {
    utils::txtProgressBar(min = 0, max = n, style = 3)
  } else NULL
  on.exit(if (!is.null(pb)) close(pb), add = TRUE)

  reports <- vector("list", n)
  failed  <- vector("list", n)
  n_warned <- 0L

  for (i in seq_len(n)) {
    warned <- FALSE
    # A warning while reading one sheet (an unrecognised item_id under
    # unknown = "drop", say) is information about that sheet, not a reason
    # to drop it. Muffle it here so the read completes, and report the
    # count at the end rather than emitting one per file.
    res <- withCallingHandlers(
      tryCatch(
        .read_one(files$path[i], unknown = unknown),
        error = function(e) {
          structure(conditionMessage(e), class = "instar_fail")
        }
      ),
      warning = function(w) {
        warned <<- TRUE
        invokeRestart("muffleWarning")
      }
    )
    if (warned) n_warned <- n_warned + 1L
    if (inherits(res, "instar_fail")) {
      failed[[i]] <- data.frame(file = files$path[i], error = as.character(res),
                                stringsAsFactors = FALSE)
    } else {
      reports[[i]] <- res
    }
    if (!is.null(pb)) utils::setTxtProgressBar(pb, i)
  }
  if (!is.null(pb)) { close(pb); pb <- NULL; cat("\n") }

  ok <- !vapply(reports, is.null, logical(1))
  failed_df <- do.call(rbind, failed[!ok])
  if (is.null(failed_df)) {
    failed_df <- data.frame(file = character(0), error = character(0),
                            stringsAsFactors = FALSE)
  }

  reports <- reports[ok]
  labels  <- if (subdir_names) files$label[ok] else basename(files$label[ok])

  # Where each sheet was found, relative to `where`. Attached whatever
  # `subdir_names` says, because it is the useful part: a corpus filed
  # into folders that mean something (by journal, by year) can then be
  # grouped on it with summary(audit, by = "folder") without the reader
  # building a lookup table. `subdir_names` only controls the names.
  folders <- dirname(files$label[ok])
  folders[folders == "."] <- NA_character_
  for (i in seq_along(reports)) reports[[i]]$folder <- folders[i]

  names(reports) <- .corpus_names(reports, labels)

  n_failed <- nrow(failed_df)
  if (n_failed > 0L) {
    bad_names <- basename(failed_df$file)
    cli::cli_warn(c(
      "{n_failed} of {n} file{?s} could not be read: {.file {bad_names}}.",
      "i" = "See {.code attr(x, \"failed\")} for the error from each."
    ))
  }
  if (!quiet) {
    n_ok <- length(reports)
    cli::cli_inform(c(
      "v" = "Imported {n_ok} sheet{?s}.",
      if (n_failed > 0L) c("x" = "{n_failed} failed."),
      if (n_warned > 0L) {
        c("!" = "{n_warned} read with warnings; re-read individually with
                 {.fn read_items} to see them.")
      }
    ))
  }

  out <- structure(reports, class = "instar_corpus",
                   failed = failed_df, path = where)
  .warn_version_mix(out)
  .warn_duplicate_dois(out)
  out
}


#' Expand paths into a list of readable sheet files
#'
#' @return A list with `path` (full paths) and `label` (paths relative to
#'   the directory they were found in, for naming).
#' @keywords internal
.collect_files <- function(where, pattern, recursive, ext) {
  rx <- paste0("\\.(", paste(ext, collapse = "|"), ")$")

  paths  <- character(0)
  labels <- character(0)

  for (w in where) {
    if (dir.exists(w)) {
      found <- list.files(w, pattern = rx, recursive = recursive,
                          full.names = FALSE, ignore.case = TRUE)
      if (length(found) == 0L) next
      paths  <- c(paths, file.path(w, found))
      labels <- c(labels, found)
    } else if (file.exists(w)) {
      paths  <- c(paths, w)
      labels <- c(labels, basename(w))
    } else {
      cli::cli_warn("No such file or directory: {.file {w}}.")
    }
  }

  # An explicit `pattern` filters on the file name, not the directory
  # part, so "smith" matches the file rather than a parent folder.
  if (!is.null(pattern)) {
    keep <- grepl(pattern, basename(paths))
    paths  <- paths[keep]
    labels <- labels[keep]
  }

  keep <- grepl(rx, paths, ignore.case = TRUE)
  list(path = paths[keep], label = tools::file_path_sans_ext(labels[keep]))
}


#' Read one sheet of any supported format into a report
#' @keywords internal
.read_one <- function(path, unknown = "drop") {
  ext <- tolower(tools::file_ext(path))
  items <- switch(
    ext,
    csv  = read_items(path),
    xlsx = .read_items_xlsx(path),
    xls  = .read_items_xlsx(path),
    cli::cli_abort("Unsupported file type {.val {ext}}.")
  )
  paper <- attr(items, "paper")
  # A sheet with no title row still belongs in the corpus: for an audit
  # the items are the point, and the file name identifies it well enough.
  if (is.null(paper) || is.null(paper$title) || is.null(paper$authors)) {
    paper <- utils::modifyList(
      list(title = tools::file_path_sans_ext(basename(path)),
           authors = "Not given"),
      paper %||% list()
    )
  }
  instar_report(items, paper = paper, unknown = unknown)
}


#' Read an INSTAR sheet from a spreadsheet file
#'
#' The xlsx and csv forms of the sheet carry identical rows, so this
#' rewrites the sheet to a temporary CSV and hands it to [read_items()]
#' rather than duplicating the reserved-row logic.
#'
#' @keywords internal
.read_items_xlsx <- function(path) {
  if (!requireNamespace("readxl", quietly = TRUE)) {
    cli::cli_abort(c(
      "Reading {.file .xlsx} sheets needs the {.pkg readxl} package.",
      "i" = 'Install it with {.run install.packages("readxl")}, or save the
             sheet as CSV.'
    ))
  }
  df <- as.data.frame(
    readxl::read_excel(path, col_types = "text", .name_repair = "minimal"),
    stringsAsFactors = FALSE
  )
  # read_excel gives real NAs for blank cells; the CSV path deliberately
  # keeps them as "" so that the literal string "NA" retains its
  # not-applicable meaning. Match that before handing over.
  df[] <- lapply(df, function(col) {
    col <- as.character(col)
    col[is.na(col)] <- ""
    col
  })
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(df, tmp, row.names = FALSE)
  read_items(tmp)
}


#' Name a corpus, preferring DOIs over file names
#' @keywords internal
.corpus_names <- function(reports, labels) {
  nm <- vapply(seq_along(reports), function(i) {
    doi <- reports[[i]]$paper$doi
    if (!is.null(doi) && !is.na(doi) && nzchar(trimws(doi))) trimws(doi)
    else labels[i]
  }, character(1))
  make.unique(nm, sep = "_")
}


#' Warn when a corpus mixes framework versions
#' @keywords internal
.warn_version_mix <- function(x) {
  v <- vapply(x, function(r) {
    out <- r$version
    if (is.null(out) || is.na(out)) NA_character_ else as.character(out)
  }, character(1))
  known <- unique(stats::na.omit(v))
  if (length(known) > 1L) {
    cli::cli_warn(c(
      "This corpus mixes INSTAR framework versions: {.val {sort(known)}}.",
      "!" = "Coverage is not comparable across versions: an item that did not
             exist in an earlier version is not an item those studies failed
             to report.",
      "i" = "Split the corpus by version before auditing."
    ))
  }
  invisible(x)
}


#' Warn when the same DOI appears more than once
#' @keywords internal
.warn_duplicate_dois <- function(x) {
  dois <- vapply(x, function(r) {
    d <- r$paper$doi
    if (is.null(d) || is.na(d) || !nzchar(trimws(d))) NA_character_
    else tolower(trimws(d))
  }, character(1))
  dup <- unique(dois[duplicated(dois) & !is.na(dois)])
  if (length(dup) > 0L) {
    cli::cli_warn(c(
      "{cli::qty(dup)}Duplicate DOI{?s} in this corpus: {.val {dup}}.",
      "!" = "The same study counted twice will skew any audit."
    ))
  }
  invisible(x)
}
