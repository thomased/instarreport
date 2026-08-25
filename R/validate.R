#' Validate user inputs to instar_report()
#'
#' Checks that the items table is well-formed, that every `item_id` it
#' references exists in [instar_items], and that any `status` column uses
#' the canonical levels. Returns the table in canonical form, with
#' `status` derived from `value` if it was absent.
#'
#' @param items A data frame with at least `item_id` and `value` columns.
#' @param items_ref The framework to validate against. Defaults to
#'   [instar_items].
#' @param unknown What to do with `item_id`s that are not in the
#'   framework. `"error"` (the default) stops; `"drop"` warns and
#'   discards them, which is what you want when reading sheets in bulk
#'   and one bad row should not fail the batch.
#'
#' @return The validated items table, with the `instar_items` class and a
#'   canonical `status` column. Errors if validation fails.
#'
#' @examples
#' tmpl <- instar_template()
#' validate_items(tmpl)
#'
#' @export
validate_items <- function(items, items_ref = instar_items,
                           unknown = c("error", "drop")) {
  unknown <- rlang::arg_match(unknown)

  if (!is.data.frame(items)) {
    cli::cli_abort("{.arg items} must be a data frame, not {.obj_type_friendly {items}}.")
  }
  required <- c("item_id", "value")
  missing_cols <- setdiff(required, names(items))
  if (length(missing_cols) > 0) {
    cli::cli_abort(c(
      "{.arg items} is missing {cli::qty(missing_cols)}required column{?s}: {.field {missing_cols}}.",
      "i" = "An items table needs an {.field item_id} column and a
             {.field report} (or {.field value}) column."
    ))
  }

  # Reserved metadata ids are stripped by read_items(), but tolerate them
  # here so a hand-built table carrying them does not trip the check.
  bad <- setdiff(items$item_id, c(items_ref$item_id, .RESERVED_FIELDS))
  if (length(bad) > 0) {
    if (identical(unknown, "error")) {
      cli::cli_abort(c(
        "{cli::qty(bad)}Unknown item_id{?s}: {.val {bad}}.",
        "i" = "Run {.code instar_items$item_id} for the canonical list.",
        "i" = "Use {.code unknown = \"drop\"} to discard unrecognised items
               instead of failing."
      ))
    }
    cli::cli_warn("{cli::qty(bad)}Dropping unknown item_id{?s}: {.val {bad}}.")
    items <- items[items$item_id %in% items_ref$item_id, , drop = FALSE]
  }

  dups <- unique(items$item_id[duplicated(items$item_id)])
  if (length(dups) > 0) {
    cli::cli_abort(c(
      "{cli::qty(dups)}Duplicate item_id{?s} in {.arg items}: {.val {dups}}.",
      "i" = "Each framework item may appear at most once."
    ))
  }
  new_instar_items(items)
}


#' Validate paper metadata
#'
#' @param paper A named list.
#' @return Invisibly, `TRUE` if valid. Errors otherwise.
#' @keywords internal
validate_paper <- function(paper) {
  if (!is.list(paper) || is.null(names(paper))) {
    cli::cli_abort("{.arg paper} must be a named list.")
  }
  missing <- setdiff(c("title", "authors"), names(paper))
  if (length(missing) > 0) {
    cli::cli_abort(c(
      "{.arg paper} is missing {.field {missing}}.",
      "i" = "At minimum: {.code paper = list(title = , authors = )}."
    ))
  }
  invisible(TRUE)
}
