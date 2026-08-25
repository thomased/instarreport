# Launch the instarreport web tool

Starts a local Shiny app that lets users fill in the 18 framework items
interactively, preview the figure, and download the result as PDF or
PNG.

## Usage

``` r
instar_app(launch.browser = TRUE, ...)
```

## Arguments

- launch.browser:

  Logical. If `TRUE` (the default), opens a browser window. Passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Called for its side effect.

## Examples

``` r
if (FALSE) { # \dontrun{
instar_app()
} # }
```
