#' Launch the instarreport web tool
#'
#' Starts a local Shiny app that lets users fill in the 18 framework items
#' interactively, preview the figure, and download the result as PDF or PNG.
#'
#' @param launch.browser Logical. If `TRUE` (the default), opens a browser
#'   window. Passed to [shiny::runApp()].
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return Called for its side effect.
#'
#' @examples
#' \dontrun{
#' instar_app()
#' }
#'
#' @export
instar_app <- function(launch.browser = TRUE, ...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cli::cli_abort(c(
      "The {.pkg shiny} package is required to run the web tool locally.",
      "i" = 'Install it with {.run install.packages("shiny")},',
      "i" = "or use the hosted copy at {.url https://instar-statement.org/app/}."
    ))
  }
  app_dir <- system.file("shiny", package = "instarreport")
  if (!nzchar(app_dir)) {
    cli::cli_abort("Shiny app directory not found. Try reinstalling {.pkg instarreport}.")
  }
  shiny::runApp(app_dir, launch.browser = launch.browser, ...)
}
