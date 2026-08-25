# Intentionally empty in the bundled Shiny app copy.
#
# The package-level documentation lives in the installed package at
# R/instarreport-package.R. It is roxygen only, so it does nothing here,
# and shipping a copy makes rsconnect's renv scanner (and shinylive's
# static scanner) conclude that the app depends on the package itself.
# It does not: app.R sources this R/ directory into globalenv instead.
