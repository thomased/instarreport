# Interactive and CSV-template workflows for filling out the framework.

.HELP_TEXT <- c(
  "Commands at any prompt:",
  "  [enter]      keep current value and move on",
  "  any text     set this as the value",
  "  NA           mark as 'not applicable' to this study",
  "  skip         leave blank (will render as 'Not reported')",
  "  back         go to the previous item",
  "  save [path]  save progress to CSV (uses the last path if omitted)",
  "  show         print current state of all items",
  "  quit         stop and return what you have",
  "  help         show this help"
)

#' Interactively fill in the reporting items at the R console
#'
#' Walks through the 18 framework items in canonical order, prompting for a
#' value for each. Designed for use at the R or RStudio console. You can
#' stop at any point with `quit`, save with `save path/to/file.csv`, and
#' resume later by passing the saved file back in (via [read_items()]) or
#' the returned object directly.
#'
#' Each prompt shows the item's domain, name, and description so you do
#' not need to remember `item_id`s or indexing.
#'
#' @param items A data frame of items to start from. If `NULL`, starts from
#'   a blank [instar_template()]. Pass an existing fill in to resume.
#' @param study_type Passed to [instar_template()] if `items` is `NULL`.
#' @param save_to Optional path to save to on `save` (without an argument)
#'   and on normal exit.
#'
#' @return The (possibly partially) filled items data frame, invisibly.
#'
#' @examples
#' \dontrun{
#' # Start fresh
#' items <- instar_fill()
#'
#' # Save partway and resume later
#' items <- instar_fill(save_to = "my_study.csv")
#' # ...later...
#' items <- instar_fill(read_items("my_study.csv"), save_to = "my_study.csv")
#' }
#'
#' @export
instar_fill <- function(items = NULL,
                       study_type = c("both", "lab", "field"),
                       save_to = NULL) {
  if (!interactive()) {
    stop("instar_fill() requires an interactive R session.", call. = FALSE)
  }
  if (is.null(items)) {
    study_type <- match.arg(study_type)
    items <- instar_template(study_type)
  } else {
    items <- validate_items(items)
  }

  # Build the working table with description metadata for prompts.
  full <- merge(
    instar_items[, c("order", "domain", "item_id", "item", "description")],
    as.data.frame(items)[, c("item_id", "value", "status")],
    by = "item_id", all.x = TRUE, sort = FALSE
  )
  full <- full[order(full$order), , drop = FALSE]
  full$status <- .as_status(full$status)

  .show_help()

  i <- 1
  last_path <- save_to
  repeat {
    if (i > nrow(full)) break

    row <- full[i, ]
    cat(sprintf("\n[%d/%d] %s -- %s\n", i, nrow(full), row$domain, row$item))
    cat(paste(strwrap(row$description, width = 76, prefix = "    "),
              collapse = "\n"), "\n\n", sep = "")
    cat("  current: ", .describe_current(row$value, row$status), "\n",
        sep = "")

    inp <- readline("  value > ")
    inp_trim <- trimws(inp)
    cmd <- tolower(inp_trim)

    if (identical(inp, "")) {
      i <- i + 1
      next
    }
    if (cmd == "help" || cmd == "?") { .show_help(); next }
    if (cmd == "show")               { .print_state(full); next }
    if (cmd == "quit" || cmd == "q") { break }
    if (cmd == "back" || cmd == "b") { i <- max(1L, i - 1L); next }
    if (cmd == "skip" || cmd == "s") {
      full$value[i]  <- NA_character_
      full$status[i] <- "not_reported"
      i <- i + 1L; next
    }
    if (cmd == "na" || cmd == "n/a") {
      full$value[i]  <- NA_character_
      full$status[i] <- "not_applicable"
      i <- i + 1L; next
    }
    if (startsWith(cmd, "save")) {
      parts <- strsplit(inp_trim, "\\s+", perl = TRUE)[[1]]
      path <- if (length(parts) > 1) parts[2] else last_path
      if (is.null(path) || !nzchar(path)) {
        cat("  ! No save path. Use: save my_study.csv\n")
      } else {
        write_items(full[, c("item_id", "value", "status")], path)
        last_path <- path
        cat(sprintf("  saved -> %s\n", path))
      }
      next
    }

    # Treat anything else as the new value
    full$value[i]  <- inp_trim
    full$status[i] <- "reported"
    i <- i + 1L
  }

  out <- new_instar_items(full[, c("item_id", "value", "status")])
  if (!is.null(last_path) && nzchar(last_path)) {
    write_items(out, last_path)
    cat(sprintf("\nSaved to %s\n", last_path))
  }
  .print_summary(out)
  invisible(out)
}


#' Edit a single item
#'
#' Pops up a one-item prompt for the named `item_id`. If `item_id` is
#' `NULL`, prints a numbered menu of all 18 items and asks you to pick one.
#' Useful for tweaking a single field after a full fill.
#'
#' @param items A data frame of items.
#' @param item_id Optional. The canonical `item_id` to edit. If omitted,
#'   you'll be shown a numbered menu.
#'
#' @return The updated items data frame, invisibly.
#'
#' @examples
#' \dontrun{
#' items <- instar_edit(items, "subjects_taxon")
#' items <- instar_edit(items)   # numbered menu
#' }
#'
#' @export
instar_edit <- function(items, item_id = NULL) {
  if (!interactive()) {
    stop("instar_edit() requires an interactive R session.", call. = FALSE)
  }
  items <- validate_items(items)

  if (is.null(item_id)) {
    cat("Pick an item to edit:\n")
    last_domain <- ""
    for (i in seq_len(nrow(instar_items))) {
      if (instar_items$domain[i] != last_domain) {
        cat(sprintf("\n  %s\n", instar_items$domain[i]))
        last_domain <- instar_items$domain[i]
      }
      cat(sprintf("    %2d. %s\n", i, instar_items$item[i]))
    }
    sel <- readline("\n  number > ")
    n <- suppressWarnings(as.integer(trimws(sel)))
    if (is.na(n) || n < 1 || n > nrow(instar_items)) {
      cat("  ! Invalid choice. No change.\n")
      return(invisible(items))
    }
    item_id <- instar_items$item_id[n]
  }
  if (!item_id %in% instar_items$item_id) {
    stop("Unknown item_id: ", item_id, call. = FALSE)
  }

  meta <- instar_items[instar_items$item_id == item_id, ]
  cat(sprintf("\n[%s] %s\n", meta$domain, meta$item))
  cat(paste(strwrap(meta$description, width = 76, prefix = "    "),
            collapse = "\n"), "\n\n", sep = "")

  cur_val <- items$value[items$item_id == item_id]
  cur_st  <- items$status[items$item_id == item_id]
  if (length(cur_val) == 0L) { cur_val <- NA_character_; cur_st <- "not_reported" }
  cat("  current: ", .describe_current(cur_val, cur_st), "\n", sep = "")
  cat("  ([enter] keeps current, 'skip' clears, 'NA' marks not applicable)\n")
  inp <- readline("  new value > ")
  inp_trim <- trimws(inp)

  if (identical(inp, "")) return(invisible(items))
  if (tolower(inp_trim) == "skip") {
    new_val <- NA_character_; new_st <- "not_reported"
  } else if (tolower(inp_trim) %in% c("na", "n/a")) {
    new_val <- NA_character_; new_st <- "not_applicable"
  } else {
    new_val <- inp_trim;      new_st <- "reported"
  }

  if (item_id %in% items$item_id) {
    items$value[items$item_id == item_id]  <- new_val
    items$status[items$item_id == item_id] <- new_st
  } else {
    items <- new_instar_items(rbind(
      as.data.frame(items)[, c("item_id", "value", "status")],
      data.frame(item_id = item_id, value = new_val, status = new_st,
                 stringsAsFactors = FALSE)
    ))
  }
  cat("  updated.\n")
  invisible(items)
}


#' Build the INSTAR CSV as a data frame
#'
#' The single on-disk shape, used by [write_template()], [write_items()]
#' and [write_report()]: the reserved rows (usage note, framework
#' version, paper details), then one row per framework item, with the
#' free-text `report` column last.
#'
#' @param items An items table, or `NULL` for a blank sheet.
#' @param paper Optional named list of paper details.
#' @param version Framework version to stamp. If `NULL`, a version
#'   declared by `items` is preserved, and failing that the current
#'   [.INSTAR_VERSION] is written. Round-tripping an older sheet keeps
#'   its declared version rather than silently upgrading it: the content
#'   was written against that framework, not this one.
#' @param study_type Used only when `items` is `NULL`.
#' @return A data frame ready to write with [utils::write.csv()].
#' @keywords internal
.instar_csv <- function(items = NULL, paper = NULL, version = NULL,
                        study_type = c("both", "lab", "field")) {
  if (is.null(items)) {
    study_type <- match.arg(study_type)
    items <- instar_template(study_type)
  } else {
    items <- validate_items(items)
    if (is.null(paper)) paper <- attr(items, "paper")
    if (is.null(version)) version <- attr(items, "version")
  }
  if (is.null(version) || is.na(version) || !nzchar(as.character(version))) {
    version <- .INSTAR_VERSION
  }
  items <- items[!items$item_id %in% .RESERVED_FIELDS, , drop = FALSE]

  help <- data.frame(
    domain      = "How to use",
    item        = vapply(.HELP_ROWS, `[`, character(1), 1L, USE.NAMES = FALSE),
    item_id     = .HELP_FIELDS,
    description = vapply(.HELP_ROWS, `[`, character(1), 2L, USE.NAMES = FALSE),
    lab         = "",
    field       = "",
    report      = "",
    stringsAsFactors = FALSE
  )

  ver <- data.frame(
    domain      = "Framework",
    item        = .VERSION_ROW[1],
    item_id     = .VERSION_FIELD,
    description = .VERSION_ROW[2],
    lab         = "",
    field       = "",
    report      = as.character(version),
    stringsAsFactors = FALSE
  )

  meta_report <- vapply(.PAPER_FIELDS, function(f) {
    v <- if (is.null(paper)) NULL else paper[[f]]
    if (is.null(v) || is.na(v)) "" else as.character(v)
  }, character(1), USE.NAMES = FALSE)

  meta <- data.frame(
    domain      = "Paper details",
    item        = unname(.PAPER_LABELS[.PAPER_FIELDS]),
    item_id     = .PAPER_FIELDS,
    description = unname(.PAPER_PROMPTS[.PAPER_FIELDS]),
    lab         = "",
    field       = "",
    report      = meta_report,
    stringsAsFactors = FALSE
  )

  # One row per framework item, in canonical order, whatever was supplied.
  ref <- instar_items
  idx <- match(ref$item_id, items$item_id)
  status <- .as_status(ifelse(is.na(idx), "not_reported",
                              as.character(items$status)[idx]))
  value  <- ifelse(is.na(idx), NA_character_, items$value[idx])
  report <- ifelse(status == "not_applicable", "NA",
                   ifelse(status == "reported" & !is.na(value), value, ""))

  body <- data.frame(
    domain      = ref$domain,
    item        = ref$item,
    item_id     = ref$item_id,
    description = ref$description,
    lab         = ref$lab,
    field       = ref$field,
    report      = report,
    stringsAsFactors = FALSE
  )
  rbind(help, ver, meta, body)
}


#' Write a filled-in items table to an INSTAR CSV
#'
#' Writes the same file shape as [write_template()], with your content in
#' the `report` column. Use this to save and resume a partly-finished
#' table; use [write_report()] when you have a full report object and
#' want the paper's details written in too.
#'
#' @param items A data frame of items.
#' @param path Output file path.
#'
#' @return The path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_items(items, "INSTAR.csv")
#' }
#'
#' @export
write_items <- function(items, path) {
  utils::write.csv(.instar_csv(items), path, row.names = FALSE)
  invisible(path)
}


#' Write a completed INSTAR report to CSV
#'
#' Writes the deposit-ready INSTAR report: the same CSV an author would
#' have filled in by hand, with their content in the `report` column and
#' the paper's own details in the four reserved rows at the top. This is
#' the file to lodge as supplementary material.
#'
#' Use [save_figure()] for the graphical version of the same report.
#'
#' @param report An object of class `instar_report`.
#' @param path Output file path. `INSTAR.csv` is the suggested name.
#'
#' @return The path, invisibly.
#'
#' @examples
#' \dontrun{
#' rep <- instar_report(read_items("INSTAR.csv"))
#' write_report(rep, "INSTAR_completed.csv")
#' }
#'
#' @export
write_report <- function(report, path) {
  if (!inherits(report, "instar_report")) {
    stop("`report` must be an object created by instar_report().",
         call. = FALSE)
  }
  utils::write.csv(.instar_csv(report$items, report$paper, report$version),
                   path, row.names = FALSE)
  invisible(path)
}


#' Write a blank CSV for authors to fill in
#'
#' Writes the fillable INSTAR report: one row per framework item, with a
#' `description` of what to report and an empty `report` column at the
#' far right to type into. Reserved rows at the top carry a usage note
#' and the paper's own details, so a completed file explains itself and
#' identifies the study it belongs to.
#'
#' The file is a plain CSV and is meant to be opened in a spreadsheet,
#' filled in, and deposited alongside the paper as supplementary
#' material. Read it back with [read_items()].
#'
#' Conventions for the `report` column:
#' * write a sentence or two of substantive content for items the study
#'   reports;
#' * leave it blank for items the study does not report;
#' * write `NA` for items that do not apply to the study.
#'
#' There is deliberately no `status` column: status is derived from what
#' you write, so the two can never disagree. [write_items()] does include
#' it, for saving and resuming your own work.
#'
#' @param path Output file path. `INSTAR.csv` is the suggested name.
#' @param study_type Optional. One of `"both"`, `"lab"`, or `"field"`.
#'   If supplied, items that do not apply in that context are pre-filled
#'   with `NA` in the `report` column.
#'
#' @return The path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_template("INSTAR.csv", study_type = "field")
#' # ...fill in the report column in Excel, Numbers, or any editor...
#' items <- read_items("INSTAR.csv")
#' }
#'
#' @export
write_template <- function(path, study_type = c("both", "lab", "field")) {
  study_type <- match.arg(study_type)
  utils::write.csv(.instar_csv(NULL, study_type = study_type), path,
                   row.names = FALSE)
  message(sprintf("Wrote INSTAR template to %s", path))
  invisible(path)
}


# ---------- internal helpers ----------

.describe_current <- function(value, status) {
  switch(as.character(status),
         not_applicable = "(not applicable)",
         not_reported   = "(empty)",
         if (is.na(value)) "(empty)" else value)
}

.show_help <- function() cat(paste(.HELP_TEXT, collapse = "\n"), "\n", sep = "")

merge_for_state <- function(items) {
  items <- new_instar_items(items)
  full <- merge(
    instar_items[, c("order", "domain", "item", "item_id")],
    as.data.frame(items)[, c("item_id", "value", "status")],
    by = "item_id", all.x = TRUE, sort = FALSE
  )
  full <- full[order(full$order), , drop = FALSE]
  full$status <- .as_status(full$status)
  full
}

.STATUS_GLYPH <- c(reported = "*", not_reported = "o", not_applicable = "-")

.print_state <- function(full) {
  last_domain <- ""
  for (i in seq_len(nrow(full))) {
    if (full$domain[i] != last_domain) {
      cat(sprintf("\n  %s\n", full$domain[i]))
      last_domain <- full$domain[i]
    }
    glyph <- .STATUS_GLYPH[[as.character(full$status[i])]]
    cat(sprintf("    %s  %s\n", glyph, full$item[i]))
    if (identical(as.character(full$status[i]), "reported") &&
        !is.na(full$value[i])) {
      lines <- strwrap(full$value[i], width = 70, prefix = "         ")
      cat(paste(lines, collapse = "\n"), "\n", sep = "")
    }
  }
  cat("\n")
}

.print_summary <- function(items) {
  cov <- .coverage(new_instar_items(items)$status)
  cat(sprintf("\nDone. %d items filled, %d not applicable, %d blank.\n",
              cov$reported, cov$not_applicable, cov$not_reported))
}
