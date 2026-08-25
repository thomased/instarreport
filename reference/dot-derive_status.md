# Derive item status from a value column

Used when reading items from sources that carry no explicit `status`
column (CSV templates, hand-built data frames). Empty or `NA` values
become `"not_reported"`. The strings `"NA"` and `"N/A"` are honoured as
an input shorthand for `"not_applicable"`, but are never used as the
internal representation.

## Usage

``` r
.derive_status(value)
```

## Arguments

- value:

  A character vector.

## Value

A factor with levels
[.STATUS_LEVELS](https://instar-statement.org/reference/dot-STATUS_LEVELS.md).
