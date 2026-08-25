# The bulk loader.
#
# The behaviour worth guarding is the tolerant part: pointed at a real
# directory it will meet malformed files, and it has to survive them.
# A loader that aborts on the first bad sheet is useless on a corpus.

# Write `n` filled sheets into a fresh directory, and return the path.
# `prefix` keeps DOIs distinct between corpora, so that tests which are
# not about duplicate detection do not trip it by accident.
make_corpus <- function(n = 3, dir = tempfile(), prefix = "a") {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  for (i in seq_len(n)) {
    items <- instar_template()
    # Vary coverage so summaries have something to say.
    ids <- instar_items$item_id[seq_len(i)]
    items$value[items$item_id %in% ids]  <- "Reported here"
    items$status[items$item_id %in% ids] <- "reported"
    rep <- instar_report(
      items,
      paper = list(title = paste("Study", i),
                   authors = paste0("Author", i, " (2026)"),
                   journal = if (i %% 2 == 0) "J Alpha" else "J Beta",
                   doi = paste0("10.1234/", prefix, i))
    )
    write_report(rep, file.path(dir, sprintf("study%02d.csv", i)))
  }
  dir
}


test_that("read_instar reads a directory into a corpus", {
  d <- make_corpus(3)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  corpus <- read_instar(d, quiet = TRUE)
  expect_s3_class(corpus, "instar_corpus")
  expect_length(corpus, 3L)
  expect_true(all(vapply(corpus, inherits, logical(1), "instar_report")))
  expect_equal(nrow(attr(corpus, "failed")), 0L)
})

test_that("one file is still a corpus", {
  # Type stability: downstream code should not care how many were found.
  d <- make_corpus(1)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  f <- list.files(d, full.names = TRUE)[1]

  corpus <- read_instar(f, quiet = TRUE)
  expect_s3_class(corpus, "instar_corpus")
  expect_length(corpus, 1L)
})

test_that("a vector of mixed files and directories works", {
  d1 <- make_corpus(2, prefix = "a")
  d2 <- make_corpus(2, prefix = "b")
  on.exit(unlink(c(d1, d2), recursive = TRUE), add = TRUE)
  extra <- list.files(d2, full.names = TRUE)[1]

  corpus <- read_instar(c(d1, extra), quiet = TRUE)
  expect_length(corpus, 3L)
})

test_that("sheets are named by DOI, falling back to file name", {
  d <- make_corpus(2)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  # A third sheet with no DOI.
  items <- instar_template()
  rep <- instar_report(items, paper = list(title = "No DOI", authors = "A"))
  write_report(rep, file.path(d, "nodoi.csv"))

  corpus <- read_instar(d, quiet = TRUE)
  expect_true("10.1234/a1" %in% names(corpus))
  expect_true("nodoi" %in% names(corpus))
})

test_that("a malformed file warns and is skipped, not fatal", {
  d <- make_corpus(2)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  writeLines(c("this,is,not", "an,instar,sheet"), file.path(d, "junk.csv"))

  expect_warning(corpus <- read_instar(d, quiet = TRUE), "could not be read")
  expect_length(corpus, 2L)

  failed <- attr(corpus, "failed")
  expect_equal(nrow(failed), 1L)
  expect_match(basename(failed$file), "junk.csv")
  expect_match(failed$error, "item_id", fixed = TRUE)
})

test_that("an empty directory errors helpfully", {
  d <- tempfile()
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  expect_error(read_instar(d, quiet = TRUE), "No INSTAR sheets found")
})

test_that("recursive and subdir_names pick up the folder structure", {
  root <- tempfile()
  make_corpus(2, file.path(root, "j_alpha"), prefix = "alpha")
  make_corpus(1, file.path(root, "j_beta"),  prefix = "beta")
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  expect_error(read_instar(root, quiet = TRUE), "No INSTAR sheets found")

  flat <- read_instar(root, recursive = TRUE, quiet = TRUE)
  expect_length(flat, 3L)

  # The folder each sheet came from is kept regardless of naming, so a
  # corpus filed by journal is groupable without a lookup table.
  expect_setequal(summary(flat)$folder, c("j_alpha", "j_alpha", "j_beta"))
  audit <- instar_audit(flat)
  expect_setequal(unique(summary(audit, by = "folder")$folder),
                  c("j_alpha", "j_beta"))
})

test_that("subdir_names puts the folder into the sheet names", {
  root <- tempfile()
  # No DOIs, so names fall through to the file path rather than the DOI.
  for (sub in c("j_alpha", "j_beta")) {
    dir.create(file.path(root, sub), recursive = TRUE)
    rep <- instar_report(instar_template(),
                         paper = list(title = sub, authors = "A"))
    write_report(rep, file.path(root, sub, "study.csv"))
  }
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  flat <- read_instar(root, recursive = TRUE, quiet = TRUE)
  # Both files are called study.csv, so bare names collide and are
  # disambiguated by make.unique().
  expect_setequal(names(flat), c("study", "study_1"))

  nested <- read_instar(root, recursive = TRUE, subdir_names = TRUE,
                        quiet = TRUE)
  expect_setequal(names(nested),
                  c("j_alpha/study", "j_beta/study"))
})

test_that("pattern filters on the file name", {
  d <- make_corpus(3)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  corpus <- read_instar(d, pattern = "study01", quiet = TRUE)
  expect_length(corpus, 1L)
})

test_that("a mixed-version corpus warns", {
  d <- make_corpus(2)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)

  f <- file.path(d, "study01.csv")
  df <- read.csv(f, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  df$report[df$item_id == .VERSION_FIELD] <- "0.9"
  utils::write.csv(df, f, row.names = FALSE)

  expect_warning(read_instar(d, quiet = TRUE), "mixes INSTAR framework versions")
})

test_that("duplicate DOIs warn", {
  d <- make_corpus(1)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  file.copy(file.path(d, "study01.csv"), file.path(d, "study01_copy.csv"))
  expect_warning(read_instar(d, quiet = TRUE), "Duplicate DOI")
})

test_that("subsetting and combining keep the class", {
  d1 <- make_corpus(3, prefix = "a")
  d2 <- make_corpus(2, dir = tempfile(), prefix = "b")
  on.exit(unlink(c(d1, d2), recursive = TRUE), add = TRUE)

  a <- read_instar(d1, quiet = TRUE)
  expect_s3_class(a[1:2], "instar_corpus")
  expect_length(a[1:2], 2L)

  b <- read_instar(d2, quiet = TRUE)
  both <- c(a, b)
  expect_s3_class(both, "instar_corpus")
  expect_length(both, 5L)
})

test_that("combining corpora re-checks for duplicate DOIs", {
  # The realistic failure: the same study pulled in from two sources.
  d1 <- make_corpus(2, prefix = "a")
  d2 <- make_corpus(2, dir = tempfile(), prefix = "a")
  on.exit(unlink(c(d1, d2), recursive = TRUE), add = TRUE)

  a <- read_instar(d1, quiet = TRUE)
  b <- read_instar(d2, quiet = TRUE)
  expect_warning(c(a, b), "Duplicate DOI")
})

test_that("summary of a corpus is one row per sheet", {
  d <- make_corpus(3)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  corpus <- read_instar(d, quiet = TRUE)

  s <- summary(corpus)
  expect_equal(nrow(s), 3L)
  expect_true(all(c("study", "title", "journal", "doi", "version",
                    "percent_reported") %in% names(s)))
  expect_true(all(s$version == .INSTAR_VERSION))
  # Coverage rises with the study number, by construction.
  expect_true(all(diff(s$reported[order(s$title)]) > 0))
})

test_that("print methods run", {
  d <- make_corpus(2)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  corpus <- read_instar(d, quiet = TRUE)
  expect_output(print(corpus), "instar_corpus")
  expect_output(print(corpus), "2 sheets")
})

test_that("xlsx sheets read the same as their CSV twin", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")

  d <- make_corpus(1)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  csv <- list.files(d, pattern = "\\.csv$", full.names = TRUE)[1]

  df <- read.csv(csv, stringsAsFactors = FALSE, na.strings = character(0),
                 colClasses = "character")
  xlsx <- file.path(d, "study01.xlsx")
  writexl::write_xlsx(df, xlsx)
  file.remove(csv)

  corpus <- read_instar(d, quiet = TRUE)
  expect_length(corpus, 1L)
  expect_equal(corpus[[1]]$paper$title, "Study 1")
  expect_equal(corpus[[1]]$version, .INSTAR_VERSION)
})
