# The framework version stamped into every sheet.
#
# The point of the row is that a corpus audit can tell a v1.0 sheet from
# a later one. If it silently went missing, or a round-trip silently
# upgraded an old sheet to the current version, coverage across a mixed
# corpus would be wrong in a way nothing else would catch.

test_that("write_template stamps the current framework version", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))

  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  expect_true(.VERSION_FIELD %in% df$item_id)
  expect_equal(df$report[df$item_id == .VERSION_FIELD], .INSTAR_VERSION)
  # It sits in the reserved block at the top, not among the items.
  expect_equal(df$item_id[seq_along(.RESERVED_FIELDS)], .RESERVED_FIELDS)
})

test_that("read_items peels the version into an attribute", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))

  items <- read_items(tmp)
  expect_equal(attr(items, "version"), .INSTAR_VERSION)
  # ...and does not leave it lying around as a framework item.
  expect_false(.VERSION_FIELD %in% items$item_id)
  expect_equal(nrow(items), nrow(instar_items))
})

test_that("a sheet with no version row reads as NA, not as current", {
  # Sheets written before versioning existed. Assuming they are v1.0
  # would be a guess; the audit needs to know the difference between
  # "declared 1.0" and "did not say".
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(
    data.frame(item_id = c("subjects_taxon", "subjects_n"),
               report  = c("Apis mellifera", "n=24"),
               stringsAsFactors = FALSE),
    tmp, row.names = FALSE
  )
  items <- read_items(tmp)
  expect_true(is.na(attr(items, "version")))
})

test_that("a round-trip preserves a declared version rather than upgrading", {
  tmp <- tempfile(fileext = ".csv")
  out <- tempfile(fileext = ".csv")
  on.exit(unlink(c(tmp, out)), add = TRUE)

  suppressMessages(write_template(tmp))
  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  df$report[df$item_id == .VERSION_FIELD] <- "0.9"
  df$report[df$item_id == "title"]        <- "An older study"
  df$report[df$item_id == "authors"]      <- "Smith (2024)"
  utils::write.csv(df, tmp, row.names = FALSE)

  items <- read_items(tmp)
  expect_equal(attr(items, "version"), "0.9")

  rep <- instar_report(items)
  expect_equal(rep$version, "0.9")

  write_report(rep, out)
  back <- read.csv(out, stringsAsFactors = FALSE, na.strings = character(0),
                   colClasses = "character")
  expect_equal(back$report[back$item_id == .VERSION_FIELD], "0.9")
})

test_that("the bundled INSTAR.csv carries a version row", {
  path <- system.file("extdata", "INSTAR.csv", package = "instarreport")
  skip_if(!nzchar(path), "bundled sheet not installed")
  items <- read_items(path)
  expect_equal(attr(items, "version"), .INSTAR_VERSION)
})
