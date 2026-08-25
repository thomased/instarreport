# Draw the standardised INSTAR figure

Renders a report to the current graphics device. This is the usual way
to look at a report. To capture the figure as an object you can modify
or compose with, use
[autoplot()](https://instar-statement.org/reference/autoplot.instar_report.md)
instead; to write it straight to a file, use
[`save_figure()`](https://instar-statement.org/reference/save_figure.md).

## Usage

``` r
# S3 method for class 'instar_report'
plot(x, ...)
```

## Arguments

- x:

  An object of class `instar_report`.

- ...:

  Passed to
  [autoplot()](https://instar-statement.org/reference/autoplot.instar_report.md).

## Value

`x`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
plot(rep)
} # }
```
