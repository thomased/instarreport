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
