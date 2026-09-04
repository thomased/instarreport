# --------------------------------------------------------------------
# Regenerate the two sheets shipped in inst/extdata.
#
#   Rscript data-raw/extdata.R
#
# `instar_items` in R/items.R is the single source of truth for the
# framework. Both sheets are derived from it, so neither can drift:
#
#   INSTAR.csv   the canonical sheet, written by write_template()
#   INSTAR.xlsx  the same rows, formatted so a human can read and fill
#                it in a spreadsheet
#
# Run after any change to the framework, then copy both into the
# manuscript repository (see its README).
#
# data-raw/ is in .Rbuildignore, so openxlsx is a developer dependency
# only and deliberately not declared in Suggests.
# --------------------------------------------------------------------

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("openxlsx is needed to build INSTAR.xlsx: install.packages(\"openxlsx\")")
}
pkgload::load_all(".", quiet = TRUE)

extdata <- file.path("inst", "extdata")
csv     <- file.path(extdata, "INSTAR.csv")
xlsx    <- file.path(extdata, "INSTAR.xlsx")

# ---- the canonical sheet ---------------------------------------------

write_template(csv)
d <- utils::read.csv(csv, stringsAsFactors = FALSE, colClasses = "character",
                     na.strings = character(0))

# ---- the same rows, formatted ----------------------------------------

# Row groups are tinted so the eye can find the framework proper among
# the reserved metadata rows above it. The tints are derived from the
# figure palette rather than written out, so the sheet and Figure 1 stay
# the same colours if the palette is ever changed.
tint <- function(hex, factor = 0.90) {
  v <- as.integer(grDevices::col2rgb(hex)[, 1])
  v <- as.integer(v + (255 - v) * factor)   # lighten towards white
  grDevices::rgb(v[1], v[2], v[3], maxColorValue = 255)
}

FOUNDATIONS <- c("Subjects", "Procedures", "Ethics & Compliance")
row_fill <- function(domain) {
  if (domain == "How to use")    return("#FFF8E1")
  # Reserved, machine-written rows: neutral, not a domain colour.
  if (domain == "Framework")     return(tint(.palette$label, 0.96))
  if (domain == "Paper details") return(tint(.palette$label, 0.93))
  if (domain %in% FOUNDATIONS)   return(tint(.palette$foundation))
  tint(.palette$welfare)
}

SHEET  <- "INSTAR v1.0"
BORDER <- .palette$panel_edge

wb <- openxlsx::createWorkbook()
openxlsx::addWorksheet(wb, SHEET)
openxlsx::writeData(wb, SHEET, d)

n <- nrow(d)
body <- 2:(n + 1)

openxlsx::addStyle(wb, SHEET, rows = 1, cols = seq_along(d), gridExpand = TRUE,
  style = openxlsx::createStyle(
    fontColour = "#FFFFFF", fgFill = "#333333", textDecoration = "bold",
    fontSize = 11, halign = "left", valign = "center",
    border = "TopBottomLeftRight", borderColour = BORDER))

for (i in seq_len(n)) {
  fill <- row_fill(d$domain[i])
  base <- function(...) openxlsx::createStyle(
    fgFill = fill, valign = "top", wrapText = TRUE,
    border = "TopBottomLeftRight", borderColour = BORDER, ...)
  r <- i + 1
  openxlsx::addStyle(wb, SHEET, r, 1, style = base(fontSize = 10, textDecoration = "bold"))
  openxlsx::addStyle(wb, SHEET, r, c(2, 4, 7), gridExpand = TRUE, style = base())
  openxlsx::addStyle(wb, SHEET, r, 3, style = base(fontSize = 9, fontColour = "#777777"))
  # lab/field carry a single character, so no wrapping.
  openxlsx::addStyle(wb, SHEET, r, c(5, 6), gridExpand = TRUE,
    style = openxlsx::createStyle(
      fgFill = fill, valign = "top", halign = "center",
      border = "TopBottomLeftRight", borderColour = BORDER))
}

# item_id is machine-facing: kept in the file so the sheet round-trips
# through read_items(), hidden so it does not distract.
openxlsx::setColWidths(wb, SHEET, cols = 1:7,
                       widths = c(20, 34, 20, 78, 6, 6, 56),
                       hidden = c(FALSE, FALSE, TRUE, rep(FALSE, 4)))
openxlsx::setRowHeights(wb, SHEET, rows = 1, heights = 22)
openxlsx::setRowHeights(wb, SHEET, rows = body, heights = 58)
# Freeze the header and everything left of `report`, so the column you
# type into stays beside the description you are answering.
openxlsx::freezePane(wb, SHEET, firstActiveRow = 2, firstActiveCol = 4)

openxlsx::saveWorkbook(wb, xlsx, overwrite = TRUE)

# ---- check the two agree ---------------------------------------------

back <- openxlsx::read.xlsx(xlsx, sheet = SHEET, colNames = TRUE)
stopifnot(
  identical(names(back), names(d)),
  nrow(back) == nrow(d),
  identical(as.character(back$item_id), as.character(d$item_id))
)
message("wrote ", csv, " and ", xlsx, " (", n, " rows)")
