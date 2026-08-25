# Write a blank CSV for authors to fill in

Writes the fillable INSTAR report: one row per framework item, with a
`description` of what to report and an empty `report` column at the far
right to type into. Reserved rows at the top carry a usage note and the
paper's own details, so a completed file explains itself and identifies
the study it belongs to.

## Usage

``` r
write_template(path, study_type = c("both", "lab", "field"))
```

## Arguments

- path:

  Output file path. `INSTAR.csv` is the suggested name.

- study_type:

  Optional. One of `"both"`, `"lab"`, or `"field"`. If supplied, items
  that do not apply in that context are pre-filled with `NA` in the
  `report` column.

## Value

The path, invisibly.

## Details

The file is a plain CSV and is meant to be opened in a spreadsheet,
filled in, and deposited alongside the paper as supplementary material.
Read it back with
[`read_items()`](https://instar-statement.org/reference/read_items.md).

Conventions for the `report` column:

- write a sentence or two of substantive content for items the study
  reports;

- leave it blank for items the study does not report;

- write `NA` for items that do not apply to the study.

There is deliberately no `status` column: status is derived from what
you write, so the two can never disagree.
[`write_items()`](https://instar-statement.org/reference/write_items.md)
does include it, for saving and resuming your own work.

## Examples

``` r
if (FALSE) { # \dontrun{
write_template("INSTAR.csv", study_type = "field")
# ...fill in the report column in Excel, Numbers, or any editor...
items <- read_items("INSTAR.csv")
} # }
```
