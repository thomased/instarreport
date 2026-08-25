# Write a completed INSTAR report to CSV

Writes the deposit-ready INSTAR report: the same CSV an author would
have filled in by hand, with their content in the `report` column and
the paper's own details in the four reserved rows at the top. This is
the file to lodge as supplementary material.

## Usage

``` r
write_report(report, path)
```

## Arguments

- report:

  An object of class `instar_report`.

- path:

  Output file path. `INSTAR.csv` is the suggested name.

## Value

The path, invisibly.

## Details

Use
[`save_figure()`](https://instar-statement.org/reference/save_figure.md)
for the graphical version of the same report.

## Examples

``` r
if (FALSE) { # \dontrun{
rep <- instar_report(read_items("INSTAR.csv"))
write_report(rep, "INSTAR_completed.csv")
} # }
```
