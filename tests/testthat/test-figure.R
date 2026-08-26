# Visual regression tests for the standardised figure.
#
# These guard the layout details that have broken silently before: card
# heights matching their content, the two columns ending flush, and the
# domain header strips spanning the full column width. A text-only test
# cannot catch any of those.
#
# Snapshots are platform-sensitive (font metrics differ), so they run
# only on the maintainer's platform and are skipped on CI and elsewhere.
# On first run, vdiffr writes the .svg snapshots; inspect them with
# `testthat::snapshot_review()` before committing.

# A fixed, fully-specified report so the figure is deterministic.
demo_report <- function() {
  # Leave a spread of items unset so they render as not reported, and
  # mark two NA, so the snapshot exercises all three render states.
  items <- instar_set(
    instar_template(),
    subjects_taxon    = "Acheta domesticus; adults of both sexes",
    subjects_source   = "Commercially reared; generations in captivity not recorded",
    subjects_n        = "n = 80 adults (40 M, 40 F); all analysed",
    proc_handling     = "Gently immobilised on a sponge; identical handling across treatments",
    ethics_review     = "No institutional review applied; welfare reasoning given in Methods",
    nutrition_diet    = "Wheatgerm ad libitum; peaches in juice as food and water",
    env_housing       = "Shared containers 40 x 40 x 100 cm; 12:12 L:D; 23 +/- 1 C",
    health_injury     = "No injuries or unexpected deaths",
    fate_end          = "Returned to housing; lived out natural lifespans",
    affect_indicators = "Site-directed grooming as a pain-like indicator",
    env_field         = NA,
    proc_anaesthesia  = NA
  )

  instar_report(
    items,
    paper = list(
      title   = "Flexible self-protection in house crickets",
      authors = "Demo, Author, & Example (2026)",
      journal = "Journal of Examples 1: 1-10"
    )
  )
}


test_that("the standardised figure renders as expected", {
  skip_if_not_installed("vdiffr")
  skip_on_ci()
  skip_on_cran()
  vdiffr::expect_doppelganger("instar report figure", autoplot(demo_report()))
})

test_that("a wholly unreported report renders as expected", {
  skip_if_not_installed("vdiffr")
  skip_on_ci()
  skip_on_cran()
  rep <- instar_report(
    paper = list(title = "Empty demo", authors = "Author (2026)"),
    items = instar_template()
  )
  vdiffr::expect_doppelganger("instar report figure empty", autoplot(rep))
})

test_that("value_wrap changes the layout", {
  skip_if_not_installed("vdiffr")
  skip_on_ci()
  skip_on_cran()
  rep <- demo_report()
  rep$value_wrap <- 45
  vdiffr::expect_doppelganger("instar report figure narrow", autoplot(rep))
})

test_that("value_wrap can be overridden at draw time", {
  # It used to be accepted and silently discarded, so plot(rep, value_wrap =)
  # looked like it worked and did nothing.
  rep <- demo_report()
  wide   <- attr(autoplot(rep, value_wrap = 100), "natural_lines")
  narrow <- attr(autoplot(rep, value_wrap = 40),  "natural_lines")
  expect_gt(narrow, wide)

  # The report's own setting is still the default.
  expect_equal(attr(autoplot(rep), "natural_lines"),
               attr(autoplot(rep, value_wrap = rep$value_wrap),
                    "natural_lines"))
})


# --- Structural checks that are safe on every platform ----------------

test_that("the figure is a patchwork carrying its natural height", {
  p <- autoplot(demo_report())
  expect_s3_class(p, "patchwork")
  nat <- attr(p, "natural_lines")
  expect_true(is.numeric(nat))
  expect_gt(nat, 0)
})

test_that("card heights grow with content", {
  short <- instar_report(
    paper = list(title = "T", authors = "A"),
    items = instar_template()
  )
  long_items <- instar_template()
  long_items$value[long_items$item_id == "env_housing"] <-
    paste(rep("A fairly long sentence about housing conditions.", 8),
          collapse = " ")
  long_items$status[long_items$item_id == "env_housing"] <- "reported"
  long <- instar_report(
    long_items,
    paper = list(title = "T", authors = "A")
  )
  expect_gt(attr(autoplot(long), "natural_lines"),
            attr(autoplot(short), "natural_lines"))
})

test_that("every framework domain appears in the render data", {
  d <- .render_data(demo_report())
  expect_setequal(unique(d$domain), unique(instar_items$domain))
  expect_equal(nrow(d), nrow(instar_items))
})

test_that("render data carries all three display states", {
  d <- .render_data(demo_report())
  expect_true(any(d$display_value == "Not reported"))
  expect_true(any(d$display_value == "Not applicable"))
  expect_true(any(!d$display_value %in% c("Not reported", "Not applicable")))
})
