# Save a report's figure to disk

Renders a report's figure and writes it via
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).
For the report as a depositable CSV instead, use
[`write_report()`](https://instar-statement.org/reference/write_report.md).

## Usage

``` r
save_figure(
  report,
  path,
  width = 8.5,
  height = NULL,
  dpi = 300,
  value_wrap = NULL,
  ...
)
```

## Arguments

- report:

  An object of class `instar_report`.

- path:

  Output file path. The extension chooses the format; `.pdf` or `.png`
  are recommended.

- width:

  Page width in inches. Defaults to 8.5".

- height:

  Page height in inches. If `NULL` (the default), a compact height is
  chosen from the content, clamped to `[6, 11]`.

- dpi:

  Resolution for raster formats. Defaults to 300.

- value_wrap:

  Approximate characters per line for the item text. Defaults to the
  value stored on the report.

- ...:

  Additional arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The path, invisibly.

## Details

The default page height is computed from the figure's natural content
size, so the saved file is as compact as the content allows with no
large blank regions. Pass an explicit `height` to override.

## Examples

``` r
if (FALSE) { # \dontrun{
rep <- instar_report(instar_template(), list(title = "T", authors = "A"))
save_figure(rep, "welfare_reporting.pdf")
} # }
```
