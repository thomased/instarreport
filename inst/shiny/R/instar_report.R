#' Build an invertebrate welfare report
#'
#' Joins a study's filled-in items against the canonical [instar_items]
#' framework and returns a report object. The result is *data*, not a
#' plot: it carries the paper metadata, the resolved item table, and a
#' coverage summary. Call [plot()][plot.instar_report] to draw the
#' standardised figure, [save_figure()] to write that figure to disk, or
#' [write_report()] to write the deposit-ready CSV. If you want the
#' figure as an object to modify further, use
#' [autoplot()][autoplot.instar_report].
#'
#' @param items A data frame with at least `item_id` and a `report` (or
#'   `value`) column, optionally a `status` column. Use
#'   [instar_template()] for an in-session template, [write_template()]
#'   for a fillable CSV, and [instar_na()] to mark items that do not
#'   apply.
#' @param paper A named list of paper metadata. Required: `title`,
#'   `authors`. Optional: `journal`, `version`, `doi`. May be omitted if
#'   `items` came from [read_items()] on a file carrying the reserved
#'   metadata rows, in which case those details are used.
#' @param value_wrap Integer; approximate characters per line for the
#'   value text when the report is plotted. Defaults to `75`.
#' @param unknown What to do with `item_id`s in `items` that are not in
#'   the framework. `"error"` (the default) stops; `"drop"` warns and
#'   ignores them. Passed to [validate_items()].
#'
#' @return An object of class `instar_report`: a list with elements
#'   `paper`, `items` (one row per framework item, with `value` and
#'   `status`), `coverage`, `version` (the framework version the items
#'   declared, or `NA`), and `value_wrap`.
#'
#' @examples
#' tmpl <- instar_template()
#' tmpl$value[tmpl$item_id == "subjects_taxon"] <-
#'   "Bombus terrestris (worker female); morphology + COI"
#' tmpl$status[tmpl$item_id == "subjects_taxon"] <- "reported"
#' tmpl <- instar_na(tmpl, "proc_anaesthesia")
#'
#' rep <- instar_report(
#'   tmpl,
#'   paper = list(title = "Demo", authors = "Smith et al. (2026)")
#' )
#' rep
#' summary(rep)
#'
#' @export
instar_report <- function(items, paper = NULL, value_wrap = 75,
                          unknown = c("error", "drop")) {
  unknown <- rlang::arg_match(unknown)
  # A file written by write_template() carries the paper's own details in
  # reserved rows, which read_items() peels off into an attribute. Fall
  # back to those when `paper` is not supplied.
  if (is.null(paper)) paper <- attr(items, "paper")
  if (is.null(paper)) {
    cli::cli_abort(c(
      "No paper metadata.",
      "i" = "Pass {.code paper = list(title = , authors = )},",
      "i" = "or read items from a sheet whose title and authors rows are
             filled in, which {.fn read_items} picks up automatically."
    ))
  }
  validate_paper(paper)
  version <- attr(items, "version")
  if (is.null(version)) version <- NA_character_
  items <- validate_items(items, unknown = unknown)
  items <- items[!items$item_id %in% .RESERVED_FIELDS, , drop = FALSE]

  # Join onto the canonical framework so every item has exactly one row,
  # in canonical order, whether or not the user supplied it.
  meta <- instar_items[, c("order", "group", "domain", "item_id", "item")]
  supplied <- as.data.frame(items)[, c("item_id", "value", "status")]
  data <- merge(meta, supplied, by = "item_id", all.x = TRUE, sort = FALSE)
  data <- data[order(data$order), , drop = FALSE]
  data$status <- .as_status(data$status)   # unsupplied rows -> not_reported
  data$value[data$status != "reported"] <- NA_character_
  rownames(data) <- NULL

  structure(
    list(
      paper      = paper,
      items      = new_instar_items(data),
      coverage   = .coverage(data$status),
      version    = version,
      value_wrap = value_wrap
    ),
    class = "instar_report"
  )
}


#' Print method for instar_report
#'
#' Prints a one-line coverage summary.
#'
#' @param x An object of class `instar_report`.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.instar_report <- function(x, ...) {
  cov <- x$coverage
  cat("<instar_report>\n")
  cat("  ", x$paper$title %||% "(untitled)", "\n", sep = "")
  cat(sprintf(
    "  %d of %d applicable items reported (%.0f%%); %d not applicable.\n",
    cov$reported, cov$applicable, cov$percent_reported, cov$not_applicable
  ))
  cat("  plot() to draw it; save_figure() for a PDF/PNG;",
      "write_report() for a depositable CSV.\n")
  invisible(x)
}


#' Coverage summary for a report, as a data frame
#'
#' Returns one row per framework item with its domain, group, and status.
#' Use this rather than reaching into the object to compute on coverage.
#'
#' @param object An object of class `instar_report`.
#' @param ... Unused.
#'
#' @return A data frame with columns `item_id`, `item`, `domain`,
#'   `group`, and `status`.
#'
#' @examples
#' rep <- instar_report(
#'   paper = list(title = "Demo", authors = "A"),
#'   items = instar_template()
#' )
#' summary(rep)
#'
#' @export
summary.instar_report <- function(object, ...) {
  out <- as.data.frame(object$items)
  out[, c("item_id", "item", "domain", "group", "status")]
}


#' Draw the standardised INSTAR figure
#'
#' Renders a report to the current graphics device. This is the usual way
#' to look at a report. To capture the figure as an object you can modify
#' or compose with, use [autoplot()][autoplot.instar_report] instead; to
#' write it straight to a file, use [save_figure()].
#'
#' @param x An object of class `instar_report`.
#' @param ... Passed to [autoplot()][autoplot.instar_report].
#'
#' @return `x`, invisibly.
#'
#' @examples
#' \dontrun{
#' rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
#' plot(rep)
#' }
#'
#' @export
plot.instar_report <- function(x, ...) {
  print(ggplot2::autoplot(x, ...))
  invisible(x)
}


#' Return a report's figure as a plot object
#'
#' The [ggplot2::autoplot()] method for `instar_report` objects. Unlike
#' [plot()][plot.instar_report], which draws to the device, this returns
#' the patchwork composition so you can modify it before rendering:
#'
#' ```r
#' autoplot(rep) + patchwork::plot_annotation(caption = "Figure S1")
#' ```
#'
#' @param object An object of class `instar_report`.
#' @param ... Unused.
#'
#' @return A patchwork object.
#'
#' @examples
#' \dontrun{
#' rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
#' p <- autoplot(rep)
#' }
#'
#' @importFrom ggplot2 autoplot
#' @export
autoplot.instar_report <- function(object, ...) {
  .build_figure(object$paper, .render_data(object),
                value_wrap = object$value_wrap)
}


#' Add rendering columns to a report's item table
#'
#' Derives the display string, colour, and font face for each item from
#' its `value` and `status`. Kept separate from [instar_report()] so that
#' the report object stays free of presentation detail.
#'
#' @param report An object of class `instar_report`.
#' @return A data frame ready for [.build_figure()].
#' @keywords internal
.render_data <- function(report) {
  d <- as.data.frame(report$items)
  attrs <- Map(.render_attrs, d$value, d$status)
  d$display_value <- vapply(attrs, `[[`, character(1), "display")
  d$colour        <- vapply(attrs, `[[`, character(1), "colour")
  d$face          <- vapply(attrs, `[[`, character(1), "face")
  d
}


#' Save a report's figure to disk
#'
#' Renders a report's figure and writes it via [ggplot2::ggsave()]. For
#' the report as a depositable CSV instead, use [write_report()].
#'
#' The default page height is computed from the figure's natural content
#' size, so the saved file is as compact as the content allows with no
#' large blank regions. Pass an explicit `height` to override.
#'
#' @param report An object of class `instar_report`.
#' @param filename Output file path (extension determines format; .pdf or
#'   .png are recommended).
#' @param width Page width in inches. Defaults to 8.5".
#' @param height Page height in inches. If `NULL` (the default), a
#'   compact height is chosen from the content, clamped to `[6, 11]`.
#' @param dpi Resolution for raster formats. Defaults to 300.
#' @param ... Additional arguments passed to [ggplot2::ggsave()].
#'
#' @return The filename, invisibly.
#'
#' @examples
#' \dontrun{
#' rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
#' save_figure(rep, "welfare_reporting.pdf")
#' }
#'
#' @export
save_figure <- function(report, filename, width = 8.5, height = NULL,
                        dpi = 300, ...) {
  if (!inherits(report, "instar_report")) {
    cli::cli_abort("{.arg report} must come from {.fn instar_report}, not
                    {.obj_type_friendly {report}}.")
  }
  fig <- ggplot2::autoplot(report)
  if (is.null(height)) {
    # ~0.18" per line at body text size, clamped to a sensible range.
    nat <- attr(fig, "natural_lines")
    height <- if (is.null(nat)) 9.5 else max(6, min(11, nat * 0.18))
  }
  ggplot2::ggsave(filename, plot = fig,
                  width = width, height = height, dpi = dpi,
                  bg = "white", ...)
  invisible(filename)
}
