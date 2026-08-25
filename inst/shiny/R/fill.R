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


#' Save items to a CSV file
#'
#' Writes a CSV with at minimum `item_id` and `value` columns, suitable for
#' loading later with [read_items()].
#'
#' @param items A data frame of items.
#' @param path Output file path.
#'
#' @return The path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_items(items, "my_study_items.csv")
#' }
#'
#' @export
write_items <- function(items, path) {
  items <- validate_items(items)
  out <- as.data.frame(items)[, c("item_id", "value", "status"), drop = FALSE]
  out$value <- ifelse(is.na(out$value), "", out$value)
  out$status <- as.character(out$status)
  utils::write.csv(out, path, row.names = FALSE)
  invisible(path)
}


#' Write a blank CSV template for the framework
#'
#' Writes a CSV file with one row per framework item, with `item_id`,
#' `item`, `domain`, `description`, and an empty `value` column. Hand
#' this to a collaborator, fill it in in Excel or any spreadsheet, then
#' load it back with [read_items()]. Extra columns (`item`, `domain`,
#' `description`) are ignored on load and exist only as in-spreadsheet
#' reminders of what each item asks for.
#'
#' @param path Output file path.
#' @param study_type Optional. One of `"both"`, `"lab"`, or `"field"`.
#'   If supplied, items not applicable in that context have their
#'   `value` pre-set to `"NA"`.
#'
#' @return The path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_template("my_study_template.csv", study_type = "field")
#' # ...fill in the value column in Excel...
#' items <- read_items("my_study_template.csv")
#' }
#'
#' @export
write_template <- function(path, study_type = c("both", "lab", "field")) {
  study_type <- match.arg(study_type)
  tmpl <- instar_template(study_type)
  out <- data.frame(
    item_id     = tmpl$item_id,
    item        = tmpl$item,
    domain      = tmpl$domain,
    description = tmpl$description,
    value       = ifelse(is.na(tmpl$value), "", tmpl$value),
    status      = as.character(tmpl$status),
    stringsAsFactors = FALSE
  )
  utils::write.csv(out, path, row.names = FALSE)
  message(sprintf("Wrote template to %s", path))
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
