# Intentionally empty in the bundled Shiny app copy.
#
# The real instar_app() helper lives in the installed package at
# R/app.R. It is not needed inside the Shiny app itself
# (the app is already running by the time anything would call it),
# and shipping a copy here causes shinylive's static dependency
# scanner to spot the `package = ...` argument in system.file() and
# attempt to install the package from the webR binary repository,
# which fails and on Safari cascades into a stack overflow.
