test_that("instar_report returns data, not a plot", {
  tmpl <- instar_template()
  tmpl$value[tmpl$item_id == "subjects_taxon"]  <- "Apis mellifera"
  tmpl$status[tmpl$item_id == "subjects_taxon"] <- "reported"

  rep <- instar_report(
    tmpl,
    paper = list(title = "Demo", authors = "Author et al.")
  )
  expect_s3_class(rep, "instar_report")
  expect_type(rep, "list")
  expect_named(rep, c("paper", "items", "coverage", "version", "value_wrap"))
  expect_false(inherits(rep, "ggplot"))
  expect_false(inherits(rep, "patchwork"))
})

test_that("report items cover the framework exactly once, in order", {
  rep <- instar_report(
    paper = list(title = "Demo", authors = "A"),
    items = instar_template()
  )
  expect_equal(nrow(rep$items), nrow(instar_items))
  expect_equal(rep$items$item_id, instar_items$item_id)
})

test_that("instar_report errors on missing paper fields", {
  tmpl <- instar_template()
  expect_error(instar_report(tmpl, list(authors = "x")), "title")
  expect_error(instar_report(tmpl, list(title = "x")), "authors")
})

test_that("as.data.frame keeps the values, not just the statuses", {
  rep <- instar_report(
    instar_set(instar_template(),
               subjects_taxon = "Apis mellifera",
               env_field      = NA),
    paper = list(title = "Demo", authors = "A", doi = "10.1/x")
  )
  d <- as.data.frame(rep)

  expect_s3_class(d, "data.frame")
  expect_false(inherits(d, "instar_items"))
  expect_equal(nrow(d), nrow(instar_items))
  expect_named(d, c("title", "doi", "item_id", "item", "domain", "group",
                    "status", "value"))

  # The point of the method: summary() drops `value`, this keeps it.
  expect_equal(d$value[d$item_id == "subjects_taxon"], "Apis mellifera")
  expect_false("value" %in% names(summary(rep)))

  expect_equal(d$status[d$item_id == "env_field"], "not_applicable")
  expect_true(all(d$title == "Demo"))
})

test_that("as.data.frame on a corpus is long form across studies", {
  mk <- function(nm, taxon) instar_report(
    instar_set(instar_template(), subjects_taxon = taxon),
    paper = list(title = nm, authors = "A", journal = "J Alpha")
  )
  corpus <- as_instar_corpus(list(a = mk("A", "Apis mellifera"),
                                  b = mk("B", "Bombus terrestris")))
  d <- as.data.frame(corpus)

  expect_equal(nrow(d), 2L * nrow(instar_items))
  expect_setequal(unique(d$study), c("a", "b"))
  expect_true("journal" %in% names(d))

  # The extraction the auditing vignette is written around.
  taxa <- subset(d, item_id == "subjects_taxon" & status == "reported")
  expect_setequal(taxa$value, c("Apis mellifera", "Bombus terrestris"))
})

test_that("as.data.frame on an empty corpus keeps the columns", {
  d <- as.data.frame(as_instar_corpus(list()))
  expect_equal(nrow(d), 0L)
  expect_true(all(c("study", "item_id", "value") %in% names(d)))
})

test_that("coverage counts statuses correctly", {
  tmpl <- instar_template()
  # Fill 10 items; mark 2 as not applicable; leave 6 not reported
  tmpl$value[1:10]  <- "filled"
  tmpl$status[1:10] <- "reported"
  tmpl <- instar_set(tmpl, env_housing = NA, env_acclimation = NA)

  rep <- instar_report(
    tmpl,
    paper = list(title = "Demo", authors = "Author et al.")
  )
  cov <- rep$coverage
  expect_equal(cov$reported, 10L)
  expect_equal(cov$not_applicable, 2L)
  expect_equal(cov$not_reported, 6L)
  expect_equal(cov$applicable, 16L)
  # 10/16 = 62.5% exactly; assert the value, not a rounding of it
  expect_equal(cov$percent_reported, 62.5)
})

test_that("summary() returns one row per item with a status column", {
  rep <- instar_report(
    paper = list(title = "Demo", authors = "A"),
    items = instar_template()
  )
  s <- summary(rep)
  expect_s3_class(s, "data.frame")
  expect_equal(nrow(s), 18L)
  expect_true(all(c("item_id", "domain", "group", "status") %in% names(s)))
  expect_s3_class(s$status, "factor")
  expect_equal(levels(s$status),
               c("reported", "not_reported", "not_applicable"))
})

test_that("autoplot() produces a patchwork composition", {
  rep <- instar_report(
    paper = list(title = "Demo", authors = "A"),
    items = instar_template()
  )
  p <- ggplot2::autoplot(rep)
  expect_s3_class(p, "patchwork")
  expect_false(is.null(attr(p, "natural_lines")))
})

test_that("print() reports coverage without drawing", {
  rep <- instar_report(
    paper = list(title = "Demo", authors = "A"),
    items = instar_template()
  )
  expect_output(print(rep), "instar_report")
  expect_output(print(rep), "applicable items reported")
})

test_that("save_figure rejects non-report input", {
  expect_error(save_figure(instar_template(), tempfile()), "instar_report")
})
