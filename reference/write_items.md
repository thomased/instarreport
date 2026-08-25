# Write a filled-in items table to an INSTAR CSV

Writes the same file shape as
[`write_template()`](https://instar-statement.org/reference/write_template.md),
with your content in the `report` column. Use this to save and resume a
partly-finished table; use
[`write_report()`](https://instar-statement.org/reference/write_report.md)
when you have a full report object and want the paper's details written
in too.

## Usage

``` r
write_items(items, path)
```

## Arguments

- items:

  A data frame of items.

- path:

  Output file path.

## Value

The path, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
write_items(items, "INSTAR.csv")
} # }
```
