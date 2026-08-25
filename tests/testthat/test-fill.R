test_that("write_items round-trips values and statuses", {
  tmpl <- instar_template()
  tmpl$value[tmpl$item_id == "subjects_taxon"]  <- "Apis mellifera"
  tmpl$status[tmpl$item_id == "subjects_taxon"] <- "reported"
  tmpl$value[tmpl$item_id == "subjects_n"]      <- "n=24"
  tmpl$status[tmpl$item_id == "subjects_n"]     <- "reported"
  tmpl <- instar_na(tmpl, "env_field")

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write_items(tmpl, tmp)
  loaded <- read_items(tmp)

  expect_equal(loaded$value[loaded$item_id == "subjects_taxon"],
               "Apis mellifera")
  expect_equal(loaded$value[loaded$item_id == "subjects_n"], "n=24")
  expect_equal(as.character(loaded$status[loaded$item_id == "env_field"]),
               "not_applicable")
  expect_equal(as.character(loaded$status[loaded$item_id == "nutrition_diet"]),
               "not_reported")
})

test_that("write_template writes 18 rows with the expected columns", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))
  df <- read.csv(tmp, stringsAsFactors = FALSE)
  expect_equal(nrow(df), 18L)
  expect_true(all(c("item_id", "item", "domain", "description",
                    "value", "status") %in% names(df)))
  expect_true(all(df$value == "" | is.na(df$value)))
  expect_true(all(df$status == "not_reported"))
})

test_that("write_template lab/field pre-marks the right rows", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp, study_type = "lab"))
  df <- read.csv(tmp, stringsAsFactors = FALSE)
  field_only <- instar_items$item_id[instar_items$lab == "-"]
  expect_true(all(df$status[df$item_id %in% field_only] == "not_applicable"))
})

test_that("templates round-trip through instar_report", {
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  suppressMessages(write_template(tmp))
  items <- read_items(tmp)
  # All blank: should produce an all-"not reported" report
  rep <- instar_report(
    paper = list(title = "Demo", authors = "A"),
    items = items
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
