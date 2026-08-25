test_that("validate_items accepts a fresh template", {
  expect_silent(validate_items(instar_template()))
})

test_that("validate_items errors on missing columns", {
  expect_error(validate_items(data.frame(item_id = "x")),
               "missing required column")
  expect_error(validate_items(data.frame(value = "x")),
               "missing required column")
})

test_that("validate_items errors on unknown item_id by default", {
  bad <- data.frame(item_id = "not_a_real_item", value = "x",
                    stringsAsFactors = FALSE)
  expect_error(validate_items(bad), "Unknown item_id")
})

test_that("unknown = 'drop' warns and discards instead of failing", {
  bad <- data.frame(item_id = c("subjects_taxon", "not_a_real_item"),
                    value = c("Apis mellifera", "x"),
                    stringsAsFactors = FALSE)
  expect_warning(out <- validate_items(bad, unknown = "drop"),
                 "Dropping unknown item_id")
  expect_equal(nrow(out), 1L)
  expect_equal(out$item_id, "subjects_taxon")
})

test_that("unknown = is matched, not silently accepted", {
  # rlang::arg_match() rejects anything outside the allowed set, and
  # suggests the nearest match rather than just refusing.
  expect_error(validate_items(instar_template(), unknown = "ignore"),
               "unknown")
})

test_that("validate_items rejects duplicated item_ids", {
  dupe <- data.frame(item_id = c("subjects_taxon", "subjects_taxon"),
                     value = c("a", "b"), stringsAsFactors = FALSE)
  expect_error(validate_items(dupe), "Duplicate item_id")
})
