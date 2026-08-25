# Internal helpers. Not exported.

#' @keywords internal
.welfare_domains <- c("Nutrition", "Environment", "Health",
                      "Behaviour", "Affective state")

#' @keywords internal
.foundation_domains <- c("Subjects", "Procedures", "Ethics & Compliance")

#' @keywords internal
.palette <- list(
  welfare    = "#3F7A3A",
  foundation = "#2E5F8E",
  text       = "#1f1f1f",
  label      = "#5a5a5a",
  muted      = "#a8a8a8",
  na         = "#7a7a7a",
  rule       = "#cccccc",
  panel_edge = "#d0d0d0"
)

#' Reserved item id carrying the usage note
#'
#' A single row at the top of the fillable CSV explaining the file's
#' conventions. It travels with the file, so someone handed the sheet by
#' a co-author, or pulling it out of a repository years later, does not
#' need the paper open to know what a blank cell means. [read_items()]
#' drops it.
#'
#' @keywords internal
.HELP_FIELDS <- "_how_to_use"


#' Content of the usage-note row
#' @keywords internal
.HELP_ROWS <- list(
  `_how_to_use` = c(
    "How to fill this in",
    paste(
      "Write a sentence or two in the `report` column for each item your",
      "study reports; leave it blank if the study does not report it;",
      "write NA if the item does not apply. Do not edit the other columns,",
      "or add or remove rows. Upload the completed file at",
      "https://thomas-white.shinyapps.io/instar/ to generate the summary",
      "figure (save as CSV first if you are in a spreadsheet)."
    )
  )
)


#' Reserved item ids carrying paper metadata
#'
#' The fillable CSV template carries the paper's own details as four
#' reserved rows at the top of the item table, so that a single deposited
#' file identifies the study it belongs to. [read_items()] splits these
#' out into a `paper` attribute; they are never treated as framework
#' items.
#'
#' @keywords internal
.PAPER_FIELDS <- c("title", "authors", "journal", "doi")


#' Human-facing labels for the reserved metadata rows
#' @keywords internal
.PAPER_LABELS <- c(
  title   = "Title",
  authors = "Authors",
  journal = "Journal or venue",
  doi     = "DOI"
)


#' Prompts for the reserved metadata rows
#' @keywords internal
.PAPER_PROMPTS <- c(
  title   = "Title of the paper this report accompanies.",
  authors = "Author list, as it appears on the paper.",
  journal = "Journal or venue, with volume and pages if known.",
  doi     = "DOI of the paper, if it has one."
)


#' Canonical item status levels
#'
#' Every item is in exactly one of three states. `status` is the single
#' source of truth; `value` carries only substantive content and is `NA`
#' whenever `status` is not `"reported"`.
#'
#' @keywords internal
.STATUS_LEVELS <- c("reported", "not_reported", "not_applicable")


#' Derive item status from a value column
#'
#' Used when reading items from sources that carry no explicit `status`
#' column (CSV templates, hand-built data frames). Empty or `NA` values
#' become `"not_reported"`. The strings `"NA"` and `"N/A"` are honoured
#' as an input shorthand for `"not_applicable"`, but are never used as
#' the internal representation.
#'
#' @param value A character vector.
#' @return A factor with levels [.STATUS_LEVELS].
#' @keywords internal
.derive_status <- function(value) {
  value <- as.character(value)
  trimmed <- trimws(value)
  out <- rep("reported", length(value))
  out[is.na(value) | !nzchar(trimmed)] <- "not_reported"
  shorthand <- !is.na(value) & toupper(trimmed) %in% c("NA", "N/A")
  out[shorthand] <- "not_applicable"
  factor(out, levels = .STATUS_LEVELS)
}


#' Coerce a status vector to the canonical factor
#' @keywords internal
.as_status <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- "not_reported"
  bad <- setdiff(unique(x), .STATUS_LEVELS)
  if (length(bad) > 0) {
    stop("Invalid `status` value(s): ", paste(bad, collapse = ", "),
         ". Must be one of: ", paste(.STATUS_LEVELS, collapse = ", "),
         call. = FALSE)
  }
  factor(x, levels = .STATUS_LEVELS)
}


#' Rendering attributes for a single item
#'
#' @param value Character; substantive content, or `NA`.
#' @param status One of [.STATUS_LEVELS].
#' @return A list with `display`, `colour`, and `face`.
#' @keywords internal
.render_attrs <- function(value, status) {
  switch(
    as.character(status),
    not_reported   = list(display = "Not reported",
                          colour  = .palette$muted,
                          face    = "italic"),
    not_applicable = list(display = "Not applicable",
                          colour  = .palette$na,
                          face    = "italic"),
    list(display = value, colour = .palette$text, face = "plain")
  )
}


#' Compute a coverage summary from a status vector
#'
#' @param status A factor or character vector of item statuses.
#' @return A list with counts and the percentage of applicable items
#'   reported. Not-applicable items are excluded from the denominator.
#' @keywords internal
.coverage <- function(status) {
  status <- .as_status(status)
  n_reported <- sum(status == "reported")
  n_missing  <- sum(status == "not_reported")
  n_na       <- sum(status == "not_applicable")
  applicable <- n_reported + n_missing
  pct <- if (applicable == 0) NA_real_ else 100 * n_reported / applicable
  list(reported = n_reported, not_reported = n_missing,
       not_applicable = n_na, applicable = applicable,
       percent_reported = pct)
}
