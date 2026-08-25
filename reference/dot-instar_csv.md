# Build the INSTAR CSV as a data frame

The single on-disk shape, used by
[`write_template()`](https://instar-statement.org/reference/write_template.md),
[`write_items()`](https://instar-statement.org/reference/write_items.md)
and
[`write_report()`](https://instar-statement.org/reference/write_report.md):
the reserved rows (usage note, framework version, paper details), then
one row per framework item, with the free-text `report` column last.

## Usage

``` r
.instar_csv(
  items = NULL,
  paper = NULL,
  version = NULL,
  study_type = c("both", "lab", "field")
)
```

## Arguments

- items:

  An items table, or `NULL` for a blank sheet.

- paper:

  Optional named list of paper details.

- version:

  Framework version to stamp. If `NULL`, a version declared by `items`
  is preserved, and failing that the current
  [.INSTAR_VERSION](https://instar-statement.org/reference/dot-INSTAR_VERSION.md)
  is written. Round-tripping an older sheet keeps its declared version
  rather than silently upgrading it: the content was written against
  that framework, not this one.

- study_type:

  Used only when `items` is `NULL`.

## Value

A data frame ready to write with
[`utils::write.csv()`](https://rdrr.io/r/utils/write.table.html).
