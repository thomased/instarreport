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
