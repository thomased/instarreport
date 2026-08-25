test_that("framework has 18 items in 8 domains", {
  expect_equal(nrow(instar_items), 18L)
  expect_equal(length(unique(instar_items$domain)), 8L)
})

test_that("domains split 3 foundations / 5 welfare", {
  by_group <- tapply(instar_items$domain, instar_items$group,
                     function(x) length(unique(x)))
  expect_equal(unname(by_group[["foundation"]]), 3L)
  expect_equal(unname(by_group[["welfare"]]), 5L)
})

test_that("framework item_ids are unique snake_case", {
  expect_equal(length(instar_items$item_id), length(unique(instar_items$item_id)))
  expect_true(all(grepl("^[a-z][a-z0-9_]*$", instar_items$item_id)))
})

test_that("instar_template returns a fillable, classed template", {
  tmpl <- instar_template()
  expect_s3_class(tmpl, "instar_items")
  expect_s3_class(tmpl, "data.frame")
  expect_equal(nrow(tmpl), 18L)
  expect_true(all(c("item_id", "value", "status") %in% names(tmpl)))
  expect_true(all(is.na(tmpl$value)))
  expect_true(all(tmpl$status == "not_reported"))
})

test_that("status is a factor with the canonical levels", {
  tmpl <- instar_template()
  expect_s3_class(tmpl$status, "factor")
  expect_equal(levels(tmpl$status),
               c("reported", "not_reported", "not_applicable"))
})

test_that("instar_template marks not-applicable items for lab studies", {
  tmpl <- instar_template("lab")
  field_only <- instar_items$item_id[instar_items$lab == "-"]
  expect_true(all(tmpl$status[tmpl$item_id %in% field_only] ==
                    "not_applicable"))
  expect_true(all(is.na(tmpl$value[tmpl$item_id %in% field_only])))
})

test_that("instar_template marks not-applicable items for field studies", {
  tmpl <- instar_template("field")
  lab_only <- instar_items$item_id[instar_items$field == "-"]
  expect_true(all(tmpl$status[tmpl$item_id %in% lab_only] ==
                    "not_applicable"))
})

test_that("instar_set sets value and status together", {
  items <- instar_set(instar_template(),
                      subjects_taxon = "Apis mellifera",
                      subjects_n     = "n = 24")

  expect_s3_class(items, "instar_items")
  expect_equal(items$value[items$item_id == "subjects_taxon"], "Apis mellifera")
  expect_equal(as.character(items$status[items$item_id == "subjects_taxon"]),
               "reported")
  expect_equal(as.character(items$status[items$item_id == "subjects_n"]),
               "reported")
  # Untouched items are left alone.
  expect_equal(as.character(items$status[items$item_id == "env_housing"]),
               "not_reported")
})

test_that("instar_set survives the round trip that hand-assignment does not", {
  # The bug this function exists to prevent: setting `value` without
  # `status` means instar_report() blanks it and the study renders as
  # wholly unreported, with no error anywhere. This is what broke the
  # manuscript's Figure 1 script.
  by_hand <- instar_template()
  by_hand$value[by_hand$item_id == "subjects_taxon"] <- "Apis mellifera"
  rep_hand <- instar_report(by_hand, paper = list(title = "T", authors = "A"))
  expect_equal(rep_hand$coverage$reported, 0L)

  by_set <- instar_set(instar_template(), subjects_taxon = "Apis mellifera")
  rep_set <- instar_report(by_set, paper = list(title = "T", authors = "A"))
  expect_equal(rep_set$coverage$reported, 1L)
  expect_equal(rep_set$items$value[rep_set$items$item_id == "subjects_taxon"],
               "Apis mellifera")
})

test_that("instar_set maps NA, empty and NULL to the right statuses", {
  items <- instar_set(instar_template(),
                      env_field        = NA,
                      proc_anaesthesia = "",
                      subjects_n       = NULL,
                      subjects_taxon   = "Apis mellifera")
  st <- function(id) as.character(items$status[items$item_id == id])

  expect_equal(st("env_field"), "not_applicable")
  expect_equal(st("proc_anaesthesia"), "not_reported")
  expect_equal(st("subjects_n"), "not_reported")
  expect_equal(st("subjects_taxon"), "reported")
  # value carries substantive content only
  expect_true(is.na(items$value[items$item_id == "env_field"]))
  expect_true(is.na(items$value[items$item_id == "proc_anaesthesia"]))
})

test_that("instar_set overwrites a previously set item", {
  items <- instar_set(instar_template(), subjects_n = "n = 24")
  items <- instar_set(items, subjects_n = "n = 48")
  expect_equal(items$value[items$item_id == "subjects_n"], "n = 48")

  # ...including back to not applicable
  items <- instar_set(items, subjects_n = NA)
  expect_equal(as.character(items$status[items$item_id == "subjects_n"]),
               "not_applicable")
  expect_true(is.na(items$value[items$item_id == "subjects_n"]))
})

test_that("instar_set coerces a non-character scalar", {
  items <- instar_set(instar_template(), subjects_n = 80)
  expect_equal(items$value[items$item_id == "subjects_n"], "80")
})

test_that("instar_set rejects bad input helpfully", {
  tmpl <- instar_template()

  expect_error(instar_set(tmpl, "no name here"), "must be named")
  expect_error(instar_set(tmpl, nonesuch = "x"), "Unknown item_id")
  expect_error(instar_set(tmpl, subjects_n = c("a", "b")), "single value")

  # A near miss gets a suggestion rather than just a rejection.
  expect_error(instar_set(tmpl, subject_taxon = "x"), "Did you mean")
  expect_error(instar_set(tmpl, subject_taxon = "x"), "subjects_taxon")
})

test_that("instar_set with nothing to set is a no-op", {
  tmpl <- instar_template()
  expect_equal(nrow(instar_set(tmpl)), nrow(tmpl))
})

test_that("instar_set adds a row absent from a partial table", {
  # read_items() on a partial file returns only the rows it found.
  partial <- new_instar_items(
    data.frame(item_id = "subjects_taxon", value = "Apis mellifera",
               stringsAsFactors = FALSE)
  )
  out <- instar_set(partial, subjects_n = "n = 24")
  expect_equal(nrow(out), 2L)
  expect_equal(out$value[out$item_id == "subjects_n"], "n = 24")
})

test_that("instar_na marks items and clears their value", {
  tmpl <- instar_template()
  tmpl$value[tmpl$item_id == "env_field"]  <- "should be cleared"
  tmpl$status[tmpl$item_id == "env_field"] <- "reported"

  out <- instar_na(tmpl, "env_field")
  expect_equal(as.character(out$status[out$item_id == "env_field"]),
               "not_applicable")
  expect_true(is.na(out$value[out$item_id == "env_field"]))
})

test_that("instar_na rejects unknown ids", {
  expect_error(instar_na(instar_template(), "not_an_item"), "Unknown item_id")
})

test_that("status is derived from value when absent", {
  df <- data.frame(
    item_id = c("subjects_taxon", "subjects_source", "subjects_n"),
    value   = c("Apis mellifera", "", "NA"),
    stringsAsFactors = FALSE
  )
  out <- validate_items(df)
  expect_equal(as.character(out$status),
               c("reported", "not_reported", "not_applicable"))
  # the "NA" shorthand is consumed, not retained as content
  expect_true(is.na(out$value[out$item_id == "subjects_n"]))
})

test_that("an explicit status column wins over value", {
  df <- data.frame(
    item_id = "subjects_taxon",
    value   = "some text",
    status  = "not_applicable",
    stringsAsFactors = FALSE
  )
  out <- validate_items(df)
  expect_equal(as.character(out$status), "not_applicable")
  expect_true(is.na(out$value))
})

test_that("invalid status values are rejected", {
  df <- data.frame(item_id = "subjects_taxon", value = "x",
                   status = "maybe", stringsAsFactors = FALSE)
  expect_error(validate_items(df), "Invalid `status`")
})
