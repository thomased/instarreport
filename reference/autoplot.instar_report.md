# Return a report's figure as a plot object

The
[`ggplot2::autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
method for `instar_report` objects. Unlike
[plot()](https://instar-statement.org/reference/plot.instar_report.md),
which draws to the device, this returns the patchwork composition so you
can modify it before rendering:

## Usage

``` r
# S3 method for class 'instar_report'
autoplot(object, value_wrap = NULL, ...)
```

## Arguments

- object:

  An object of class `instar_report`.

- value_wrap:

  Approximate characters per line for the item text. Defaults to the
  value stored on the report by
  [`instar_report()`](https://instar-statement.org/reference/instar_report.md).

- ...:

  Unused.

## Value

A patchwork object.

## Details

    autoplot(rep) + patchwork::plot_annotation(caption = "Figure S1")

## Examples

``` r
if (FALSE) { # \dontrun{
rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
p <- autoplot(rep)
} # }
```
