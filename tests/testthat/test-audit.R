# Corpus-level coverage.
#
# The arithmetic that matters: not-applicable items must stay out of the
# denominator, both per study and per item. Getting that wrong would
# understate coverage for exactly the items the framework marks as
# conditional, which is the claim the paper's survey rests on.

# A small corpus with known, hand-checkable coverage.
demo_corpus <- function() {
  mk <- function(title, reported, na = character(0), journal = "J Alpha",
                 doi = NULL) {
    items <- instar_template()
    items$value[items$item_id %in% reported]  <- "Reported"
    items$status[items$item_id %in% reported] <- "reported"
    if (length(na) > 0) items <- instar_na(items, na)
    instar_report(items, paper = list(title = title, authors = "A",
                                      journal = journal, doi = doi))
  }
  as_instar_corpus(list(
    a = mk("A", c("subjects_taxon", "subjects_n")),
    b = mk("B", "subjects_taxon", na = "env_field", journal = "J Beta"),
    c = mk("C", "subjects_taxon", journal = "J Beta")
  ))
}


test_that("a named list keeps its names through as_instar_corpus", {
  # lapply(seq_along(x), ...) drops names. Losing them relabels every
  # study as study_1, study_2, ... which is wrong everywhere downstream:
  # audit$long$study, summary()$study, and any grouping keyed on them.
  corpus <- demo_corpus()
  expect_equal(names(corpus), c("a", "b", "c"))
  expect_setequal(unique(instar_audit(corpus)$long$study), c("a", "b", "c"))
  expect_setequal(summary(corpus)$study, c("a", "b", "c"))
})

test_that("instar_audit summarises item-level coverage", {
  audit <- instar_audit(demo_corpus())

  expect_s3_class(audit, "instar_audit")
  expect_equal(audit$n, 3L)
  expect_equal(nrow(audit$items), nrow(instar_items))

  s <- summary(audit)
  # All three studies reported taxon.
  taxon <- s[s$item_id == "subjects_taxon", ]
  expect_equal(taxon$reported, 3L)
  expect_equal(taxon$percent_reported, 100)

  # One study of three reported sample size.
  n <- s[s$item_id == "subjects_n", ]
  expect_equal(n$reported, 1L)
  expect_equal(n$applicable, 3L)

  # env_field: nobody reported it, and one study marked it not
  # applicable, so it leaves the denominator for that study only.
  ef <- s[s$item_id == "env_field", ]
  expect_equal(ef$reported, 0L)
  expect_equal(ef$not_applicable, 1L)
  expect_equal(ef$applicable, 2L)
  expect_equal(ef$percent_reported, 0)
})

test_that("items come back in canonical framework order", {
  audit <- instar_audit(demo_corpus())
  expect_equal(summary(audit)$item_id, instar_items$item_id)
})

test_that("per-study coverage excludes not-applicable items", {
  audit <- instar_audit(demo_corpus())
  st <- audit$studies

  b <- st[st$title == "B", ]
  # 18 items, 1 marked not applicable, 1 reported.
  expect_equal(b$not_applicable, 1L)
  expect_equal(b$applicable, nrow(instar_items) - 1L)
  expect_equal(b$reported, 1L)
})

test_that("summary(by =) groups by study metadata", {
  audit <- instar_audit(demo_corpus())
  s <- summary(audit, by = "journal")

  expect_true("journal" %in% names(s))
  expect_setequal(unique(s$journal), c("J Alpha", "J Beta"))
  expect_equal(nrow(s), 2L * nrow(instar_items))

  # Sample size: reported by the one J Alpha study, neither J Beta one.
  n_alpha <- s[s$journal == "J Alpha" & s$item_id == "subjects_n", ]
  n_beta  <- s[s$journal == "J Beta"  & s$item_id == "subjects_n", ]
  expect_equal(n_alpha$percent_reported, 100)
  expect_equal(n_beta$percent_reported, 0)
})

test_that("summary(by =) errors helpfully on an unknown column", {
  audit <- instar_audit(demo_corpus())
  expect_error(summary(audit, by = "nonesuch"), "No study-level column")
})

test_that("instar_audit accepts a path and reads it", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  corpus <- demo_corpus()
  for (i in seq_along(corpus)) {
    write_report(corpus[[i]], file.path(d, sprintf("s%d.csv", i)))
  }

  audit <- instar_audit(d, quiet = TRUE)
  expect_s3_class(audit, "instar_audit")
  expect_equal(audit$n, 3L)
})

test_that("auditing an empty corpus errors", {
  expect_error(instar_audit(as_instar_corpus(list())), "empty")
})

test_that("print and plot run", {
  audit <- instar_audit(demo_corpus())
  expect_output(print(audit), "instar_audit")
  expect_output(print(audit), "3 studies")
  expect_s3_class(ggplot2::autoplot(audit), "ggplot")
  expect_s3_class(ggplot2::autoplot(audit, by = "journal"), "ggplot")
})


# --- Retrospective scoring matrices ----------------------------------

test_that("audit_from_matrix reads a wide scoring table", {
  scores <- data.frame(
    doi     = c("10.1/a", "10.1/b", "10.1/c"),
    journal = c("J Alpha", "J Beta", "J Beta"),
    subjects_taxon = c("Y", "Y", "Y"),
    subjects_n     = c("Y", "N", "N"),
    env_field      = c("NA", "Y", "-"),
    stringsAsFactors = FALSE
  )
  audit <- suppressMessages(audit_from_matrix(scores, id = "doi"))

  expect_s3_class(audit, "instar_audit")
  expect_equal(audit$n, 3L)
  # Only the three scored items appear; unscored ones are left out
  # rather than counted as failures to report.
  expect_equal(nrow(audit$items), 3L)

  s <- summary(audit)
  expect_equal(s$percent_reported[s$item_id == "subjects_taxon"], 100)
  expect_equal(s$percent_reported[s$item_id == "subjects_n"],
               100 / 3, tolerance = 1e-6)
  # env_field: one Y, two not-applicable, so 1 of 1 applicable.
  ef <- s[s$item_id == "env_field", ]
  expect_equal(ef$not_applicable, 2L)
  expect_equal(ef$applicable, 1L)
  expect_equal(ef$percent_reported, 100)
})

test_that("non-item columns become groupable metadata", {
  scores <- data.frame(
    doi = c("10.1/a", "10.1/b"),
    journal = c("J Alpha", "J Beta"),
    year = c(2024, 2025),
    subjects_taxon = c("Y", "N"),
    stringsAsFactors = FALSE
  )
  audit <- suppressMessages(audit_from_matrix(scores, id = "doi"))

  expect_true(all(c("journal", "year") %in% names(audit$studies)))
  s <- summary(audit, by = "journal")
  expect_equal(s$percent_reported[s$journal == "J Alpha"], 100)
  expect_equal(s$percent_reported[s$journal == "J Beta"], 0)
})

test_that("score values are read leniently", {
  expect_equal(as.character(.score_status(c("Y", "yes", "TRUE", "1", "C"))),
               rep("reported", 5))
  expect_equal(as.character(.score_status(c("N", "no", "FALSE", "0"))),
               rep("not_reported", 4))
  expect_equal(as.character(.score_status(c(NA, "", "NA", "N/A", "-"))),
               rep("not_applicable", 5))
})

test_that("an unrecognised score warns rather than failing silently", {
  expect_warning(.score_status(c("Y", "maybe")), "Unrecognised score")
})

test_that("a duplicated study id warns before being made unique", {
  scores <- data.frame(
    doi = c("10.1/a", "10.1/a"), subjects_taxon = c("Y", "N"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    audit <- suppressMessages(audit_from_matrix(scores, id = "doi")),
    "Duplicate study identifier"
  )
  # Still two studies: disambiguated, not merged or dropped.
  expect_equal(audit$n, 2L)
})

test_that("blank study ids get their own advice", {
  # The real case: DOI extraction failed for some rows, so they share an
  # empty id despite being different papers.
  scores <- data.frame(
    doi = c("10.1/a", "", ""), subjects_taxon = c("Y", "N", "Y"),
    stringsAsFactors = FALSE
  )
  expect_warning(
    audit <- suppressMessages(audit_from_matrix(scores, id = "doi")),
    "column is incomplete"
  )
  expect_equal(audit$n, 3L)
})

test_that("a matrix with no recognisable items errors", {
  expect_error(
    audit_from_matrix(data.frame(a = 1, b = 2)),
    "None of the columns"
  )
})

test_that("instar_audit dispatches a data frame to audit_from_matrix", {
  scores <- data.frame(doi = "10.1/a", subjects_taxon = "Y",
                       stringsAsFactors = FALSE)
  audit <- suppressMessages(instar_audit(scores, id = "doi"))
  expect_s3_class(audit, "instar_audit")
  expect_equal(audit$n, 1L)
})
