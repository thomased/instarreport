# Row counts and the reserved-row block are derived from the package
# constants, so adding or removing a reserved row updates these tests
# rather than staling them.
.reserved_ids <- function() .RESERVED_FIELDS
.n_csv_rows   <- function() length(.reserved_ids()) + nrow(instar_items)

test_that("write_items writes the INSTAR CSV shape and round-trips", {
  tmpl <- instar_template()
  tmpl$value[tmpl$item_id == "subjects_taxon"]  <- "Apis mellifera"
  tmpl$status[tmpl$item_id == "subjects_taxon"] <- "reported"
  tmpl$value[tmpl$item_id == "subjects_n"]      <- "n=24"
  tmpl$status[tmpl$item_id == "subjects_n"]     <- "reported"
  tmpl <- instar_na(tmpl, "env_field")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write_items(tmpl, tmp)

  raw <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  expect_equal(names(raw),
               c("domain", "item", "item_id", "description",
                 "lab", "field", "report"))
  expect_equal(nrow(raw), .n_csv_rows())

  loaded <- read_items(tmp)
  expect_equal(loaded$value[loaded$item_id == "subjects_taxon"],
               "Apis mellifera")
  expect_equal(loaded$value[loaded$item_id == "subjects_n"], "n=24")
  expect_equal(as.character(loaded$status[loaded$item_id == "env_field"]),
               "not_applicable")
  expect_equal(as.character(loaded$status[loaded$item_id == "nutrition_diet"]),
               "not_reported")
})

test_that("templates round-trip through instar_report", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))
  items <- read_items(tmp)
  # All blank: should produce an all-"not reported" report
  rep <- instar_report(
    items,
    paper = list(title = "Demo", authors = "A")
  )
  expect_equal(rep$coverage$reported, 0L)
  expect_equal(rep$coverage$not_reported + rep$coverage$not_applicable, 18L)
})

test_that("a legacy value-only CSV still reads correctly", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  utils::write.csv(
    data.frame(item_id = c("subjects_taxon", "env_field"),
               value   = c("Apis mellifera", "NA"),
               stringsAsFactors = FALSE),
    tmp, row.names = FALSE
  )
  items <- read_items(tmp)
  expect_equal(as.character(items$status),
               c("reported", "not_applicable"))
})

# These two assert the non-interactive guard, which means actually
# *calling* the function. Under `R CMD check` interactive() is FALSE, the
# guard fires, and the expectation holds. In a live session (devtools::test())
# interactive() is TRUE, the guard does not fire, and the function would
# start its readline() prompt loop and hang the test run -- so skip there.
test_that("instar_fill errors in non-interactive sessions", {
  skip_if(interactive(), "would start the interactive prompt loop")
  expect_error(instar_fill(), "interactive")
})

test_that("instar_edit errors in non-interactive sessions", {
  skip_if(interactive(), "would start the interactive prompt loop")
  expect_error(instar_edit(instar_template(), "subjects_taxon"),
               "interactive")
})

test_that("print.instar_items prints without error", {
  tmpl <- instar_template()
  tmpl$value[1]  <- "filled"
  tmpl$status[1] <- "reported"
  tmpl <- instar_na(tmpl, tmpl$item_id[2])
  expect_output(print(tmpl))
})

test_that("write_template writes the fillable INSTAR CSV", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))
  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")

  # usage note + version + paper-detail rows + the framework items
  expect_equal(nrow(df), .n_csv_rows())
  expect_equal(names(df),
               c("domain", "item", "item_id", "description",
                 "lab", "field", "report"))
  # no status column: status is derived from `report`, so they cannot disagree
  expect_false("status" %in% names(df))
  # Everything the author is asked to fill in starts blank. The version
  # row is the one reserved row carrying content, because it is written
  # by the package rather than by the author.
  expect_true(all(df$report[!df$item_id %in% .VERSION_FIELD] == ""))
  expect_equal(df$report[df$item_id == .VERSION_FIELD], .INSTAR_VERSION)
  # reserved rows come first, in a fixed order
  expect_equal(df$item_id[seq_along(.reserved_ids())], .reserved_ids())
  # ...and everything after them is a framework item, in canonical order
  expect_equal(df$item_id[-seq_along(.reserved_ids())], instar_items$item_id)
})

test_that("write_template pre-marks not-applicable items in `report`", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp, study_type = "lab"))
  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  field_only <- instar_items$item_id[instar_items$lab == "-"]
  expect_true(all(df$report[df$item_id %in% field_only] == "NA"))
})

test_that("a filled template round-trips, carrying its paper details", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))

  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  df$report[df$item_id == "title"]          <- "A study of crickets"
  df$report[df$item_id == "authors"]        <- "Smith et al. (2026)"
  df$report[df$item_id == "subjects_taxon"] <- "Acheta domesticus"
  df$report[df$item_id == "env_field"]      <- "NA"
  utils::write.csv(df, tmp, row.names = FALSE)

  items <- read_items(tmp)
  expect_equal(nrow(items), 18L)                    # metadata rows peeled off
  expect_false(any(items$item_id %in% c("title", "authors")))
  expect_equal(attr(items, "paper")$title, "A study of crickets")
  expect_equal(attr(items, "paper")$authors, "Smith et al. (2026)")
  # journal and doi were left blank, so they are dropped rather than empty
  expect_null(attr(items, "paper")$journal)
  expect_equal(as.character(items$status[items$item_id == "subjects_taxon"]),
               "reported")
  expect_equal(as.character(items$status[items$item_id == "env_field"]),
               "not_applicable")
})

test_that("instar_report() picks up paper details from the file", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))
  df <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  df$report[df$item_id == "title"]   <- "A study of crickets"
  df$report[df$item_id == "authors"] <- "Smith et al. (2026)"
  utils::write.csv(df, tmp, row.names = FALSE)

  rep <- instar_report(read_items(tmp))
  expect_s3_class(rep, "instar_report")
  expect_equal(rep$paper$title, "A study of crickets")
  expect_equal(nrow(rep$items), 18L)
})

test_that("instar_report() errors helpfully with no paper details anywhere", {
  expect_error(instar_report(instar_template()), "No paper metadata")
})

test_that("a `report` column is accepted as an alias for `value`", {
  df <- data.frame(item_id = "subjects_taxon", report = "Apis mellifera",
                   stringsAsFactors = FALSE)
  items <- new_instar_items(df)
  expect_equal(items$value, "Apis mellifera")
  expect_equal(as.character(items$status), "reported")
})


test_that("write_report writes paper details into the reserved rows", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)

  items <- instar_template()
  items$value[items$item_id == "subjects_taxon"]  <- "Acheta domesticus"
  items$status[items$item_id == "subjects_taxon"] <- "reported"
  rep <- instar_report(
    items,
    paper = list(title = "Cricket study", authors = "Smith et al. (2026)",
                 journal = "J Examples", doi = "10.1234/x")
  )
  write_report(rep, tmp)

  raw <- read.csv(tmp, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  expect_equal(raw$report[raw$item_id == "title"], "Cricket study")
  expect_equal(raw$report[raw$item_id == "doi"],   "10.1234/x")
  expect_equal(raw$report[raw$item_id == "subjects_taxon"],
               "Acheta domesticus")

  # ...and the whole thing comes back
  back <- instar_report(read_items(tmp))
  expect_equal(back$paper$title, "Cricket study")
  expect_equal(back$coverage$reported, 1L)
})

test_that("write_report rejects non-report input", {
  expect_error(write_report(instar_template(), tempfile()), "instar_report")
})

test_that("a report survives a full write/read/write cycle unchanged", {
  t1 <- tempfile(fileext = ".csv"); t2 <- tempfile(fileext = ".csv")
  on.exit(unlink(c(t1, t2)), add = TRUE)

  items <- instar_template()
  items$value[items$item_id == "env_housing"]  <- "23 +/- 1 C; 12:12 L:D"
  items$status[items$item_id == "env_housing"] <- "reported"
  items <- instar_na(items, "env_field")
  rep1 <- instar_report(items, paper = list(title = "T", authors = "A"))

  write_report(rep1, t1)
  rep2 <- instar_report(read_items(t1))
  write_report(rep2, t2)

  expect_equal(readLines(t1), readLines(t2))
  expect_equal(rep2$coverage, rep1$coverage)
})
