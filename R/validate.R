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
#' @param strict Logical. If `TRUE` (the default), unknown `item_id`s
#'   raise an error. If `FALSE`, they are warned about and dropped.
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
                           strict = TRUE) {
  if (!is.data.frame(items)) {
    stop("`items` must be a data frame.", call. = FALSE)
  }
  required <- c("item_id", "value")
  missing_cols <- setdiff(required, names(items))
  if (length(missing_cols) > 0) {
    stop("`items` is missing required column(s): ",
         paste(missing_cols, collapse = ", "), call. = FALSE)
  }
  # Reserved metadata ids are stripped by read_items(), but tolerate them
  # here so a hand-built table carrying them does not trip the check.
  unknown <- setdiff(items$item_id, c(items_ref$item_id, .RESERVED_FIELDS))
  if (length(unknown) > 0) {
    msg <- paste0("Unknown item_id(s): ", paste(unknown, collapse = ", "),
                  ". Run `instar_items$item_id` to see the canonical list.")
    if (strict) stop(msg, call. = FALSE) else {
      warning(msg, call. = FALSE)
      items <- items[items$item_id %in% items_ref$item_id, , drop = FALSE]
    }
  }
  duplicated_ids <- items$item_id[duplicated(items$item_id)]
  if (length(duplicated_ids) > 0) {
    stop("Duplicate item_id(s) in `items`: ",
         paste(unique(duplicated_ids), collapse = ", "), call. = FALSE)
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
    stop("`paper` must be a named list.", call. = FALSE)
  }
  required <- c("title", "authors")
  missing <- setdiff(required, names(paper))
  if (length(missing) > 0) {
    stop("`paper` must contain at least: ",
         paste(required, collapse = ", "),
         ". Missing: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  invisible(TRUE)
}
