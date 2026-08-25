#' instarreport: an R implementation of the INSTAR framework
#'
#' `instarreport` is the R implementation of **INSTAR** (INvertebrate
#' Standards for Treatment And Reporting; White et al., in prep), an
#' 18-item reporting standard for invertebrate welfare in research.
#' The package produces a standardised,
#' publication-ready summary figure in which each cell carries the
#' substantive content for the corresponding item (species and
#' provenance, housing conditions, ethics review and permits, and so
#' on), in the same spirit as the PRISMA and ROSES flow diagrams for
#' evidence synthesis.
#'
#' @section Three ways to fill out the framework:
#'
#' **Interactive prompt** (see [instar_fill()]):
#' ```r
#' items <- instar_fill(save_to = "my_study.csv")
#' ```
#'
#' **CSV template** (see [write_template()], [read_items()]):
#' ```r
#' write_template("my_study.csv")
#' # ...edit the value column in Excel...
#' items <- read_items("my_study.csv")
#' ```
#'
#' **Programmatic**:
#' ```r
#' items <- instar_template()
#' items$value[items$item_id == "subjects_taxon"] <-
#'   "Bombus terrestris (worker female); morphology + COI"
#' ```
#'
#' @section Building the figure:
#' ```r
#' report <- instar_report(
#'   paper = list(title = "My study", authors = "Smith et al. (2026)"),
#'   items = items
#' )
#' instar_save(report, "fig_S1_welfare_reporting.pdf")
#' ```
#'
#' @section Web tool:
#' [instar_app()] launches a local web interface for filling out the
#' framework with a live preview.
#'
#' @keywords internal
"_PACKAGE"


#' @importFrom ggplot2 autoplot
#' @export
ggplot2::autoplot
