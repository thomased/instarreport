# The Shiny bundle runs with NO package namespace loaded: app.R sources
# inst/shiny/R/*.R into globalenv and attaches nothing but shiny. Every
# non-base function must therefore either be defined in those sourced
# files or carry an explicit pkg:: prefix.
#
# Four bugs have shipped from breaking that rule -- library(invertreport),
# instarreport::instar_items as a default argument, a bare autoplot(), and
# a bare ggplot2 generic in save_figure(). These tests are cheap and catch
# the whole class without needing to start a browser.

app_dir <- function() {
  d <- system.file("shiny", package = "instarreport")
  if (!nzchar(d)) d <- testthat::test_path("..", "..", "inst", "shiny")
  normalizePath(d, mustWork = FALSE)
}

bundle_files <- function() {
  d <- app_dir()
  if (!dir.exists(d)) return(character(0))
  c(list.files(file.path(d, "R"), pattern = "\\.R$", full.names = TRUE),
    list.files(d, pattern = "^app\\.R$", full.names = TRUE))
}

# Strip comments and string literals so we only inspect live code.
strip_code <- function(path) {
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  txt <- gsub('"(\\\\.|[^"\\\\])*"', '""', txt)
  txt <- gsub("'(\\\\.|[^'\\\\])*'", "''", txt)
  txt <- gsub("#[^\n]*", "", txt)
  txt
}


test_that("the Shiny bundle does not drift from the package sources", {
  # The bundle carries a copy of R/ so the app can source it without a
  # namespace. Those copies are kept in sync by hand, so check them: a
  # stale copy means the deployed app runs different code from the
  # package. Only possible when testing from the source tree.
  src <- testthat::test_path("..", "..", "R")
  bun <- testthat::test_path("..", "..", "inst", "shiny", "R")
  skip_if(!dir.exists(src) || !dir.exists(bun), "not testing from source tree")

  # Files deliberately blanked in the bundle (package-only machinery).
  blanked <- c("app.R", "instarreport-package.R")

  shared <- setdiff(intersect(list.files(src, pattern = "\\.R$"),
                              list.files(bun, pattern = "\\.R$")),
                    blanked)
  expect_gt(length(shared), 0)

  stale <- shared[!vapply(shared, function(f) {
    identical(readLines(file.path(src, f), warn = FALSE),
              readLines(file.path(bun, f), warn = FALSE))
  }, logical(1))]

  expect_equal(
    stale, character(0),
    info = paste0(
      "inst/shiny/R/ has drifted from R/. Re-copy: ",
      paste(stale, collapse = ", ")
    )
  )
})


test_that("the bundle never names the package in executable code", {
  files <- bundle_files()
  skip_if(length(files) == 0, "shiny bundle not found")

  offenders <- character(0)
  for (f in files) {
    code <- strip_code(f)
    if (grepl("library\\s*\\(\\s*instarreport", code) ||
        grepl("require\\s*\\(\\s*instarreport", code) ||
        grepl("instarreport::", code)) {
      offenders <- c(offenders, basename(f))
    }
  }
  expect_equal(
    offenders, character(0),
    info = paste0(
      "The Shiny bundle must not load or namespace-qualify the package: ",
      "it sources R/ into globalenv instead, and the package is not ",
      "installed under shinylive. Offending file(s): ",
      paste(offenders, collapse = ", ")
    )
  )
})


test_that("the bundle qualifies foreign generics it calls", {
  files <- bundle_files()
  skip_if(length(files) == 0, "shiny bundle not found")

  # Functions that live in a package the bundle never attaches. A bare
  # call to any of these is an undefined-function error at runtime.
  foreign <- c("autoplot", "ggsave", "ggplot", "aes", "theme_void",
               "wrap_plots", "plot_layout", "geom_richtext")

  offenders <- character(0)
  for (f in files) {
    code <- strip_code(f)
    for (fn in foreign) {
      # a call to fn( that is not preceded by "::" or a word character,
      # and is not the definition of an S3 method for it
      bare <- gregexpr(paste0("(?<![\\w.:])", fn, "\\s*\\("), code, perl = TRUE)[[1]]
      if (bare[1] == -1) next
      # allow `fn.class <- function` style method definitions
      is_method_def <- grepl(paste0(fn, "\\.[A-Za-z_.]+\\s*<-\\s*function"), code)
      if (!is_method_def) {
        offenders <- c(offenders, paste0(basename(f), ":", fn, "()"))
      }
    }
  }
  expect_equal(
    offenders, character(0),
    info = paste0(
      "Unqualified calls to functions from unattached packages: ",
      paste(offenders, collapse = ", "),
      ". Prefix with pkg:: -- the bundle attaches only shiny."
    )
  )
})


test_that("app.R parses and defines a shinyApp", {
  d <- app_dir()
  skip_if(!dir.exists(d), "shiny bundle not found")
  app_file <- file.path(d, "app.R")
  skip_if(!file.exists(app_file), "app.R not found")

  expect_no_error(parse(app_file))
  code <- paste(readLines(app_file, warn = FALSE), collapse = "\n")
  expect_match(code, "shinyApp\\s*\\(", info = "app.R must call shinyApp()")
})


test_that("every bundled R file parses", {
  files <- bundle_files()
  skip_if(length(files) == 0, "shiny bundle not found")
  for (f in files) expect_no_error(parse(f))
})


# --- End-to-end smoke test -------------------------------------------
# Drives the real app in a headless browser: load it, upload a filled
# INSTAR.csv, and confirm the preview renders rather than erroring. This
# is the test that would have caught the bare autoplot() bug.
#
# shinytest2 must stay declared in Suggests: R CMD check inspects test
# files for `::` calls and raises a WARNING for any package not declared,
# which would block a CRAN submission.
#
# The cost of declaring it is that CI installs chromote, which needs a
# `chromium` system package. Ubuntu 24.04 has none in its main archive,
# so pak adds the third-party xtradeb PPA -- which has failed at least
# once when Launchpad 500'd fetching its signing key. If that recurs
# often, the fix is to pin the CI dependency set in R-CMD-check.yaml
# rather than to undeclare the package here.
#
# To run this test locally:  install.packages("shinytest2")
# It skips cleanly when absent, which is the state on a fresh checkout.

test_that("the app loads, accepts an upload, and renders a preview", {
  skip_if_not_installed("shinytest2")
  skip_on_cran()
  skip_on_ci()

  d <- app_dir()
  skip_if(!dir.exists(d), "shiny bundle not found")

  # A filled sheet to upload.
  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  items <- instar_template()
  items$value[items$item_id == "subjects_taxon"]  <- "Acheta domesticus"
  items$status[items$item_id == "subjects_taxon"] <- "reported"
  rep <- instar_report(
    items,
    paper = list(title = "Smoke test study", authors = "Author (2026)")
  )
  write_report(rep, tmp)

  app <- shinytest2::AppDriver$new(d, name = "instar", load_timeout = 60000)
  on.exit(app$stop(), add = TRUE)

  # The preview must render on a cold load, with nothing filled in.
  app$wait_for_idle(timeout = 30000)
  expect_false(
    grepl("error has occurred", app$get_html("body"), ignore.case = TRUE),
    info = "the preview errored on initial load"
  )

  # Upload, then check the title propagated out of the reserved rows.
  app$upload_file(upload = tmp)
  app$wait_for_idle(timeout = 30000)
  expect_equal(app$get_value(input = "paper_title"), "Smoke test study")
  expect_equal(app$get_value(input = "val_subjects_taxon"), "Acheta domesticus")
  expect_false(
    grepl("error has occurred", app$get_html("body"), ignore.case = TRUE),
    info = "the preview errored after upload"
  )
})
