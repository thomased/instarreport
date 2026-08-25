# Add rendering columns to a report's item table

Derives the display string, colour, and font face for each item from its
`value` and `status`. Kept separate from
[`instar_report()`](https://instar-statement.org/reference/instar_report.md)
so that the report object stays free of presentation detail.

## Usage

``` r
.render_data(report)
```

## Arguments

- report:

  An object of class `instar_report`.

## Value

A data frame ready for
[`.build_figure()`](https://instar-statement.org/reference/dot-build_figure.md).
