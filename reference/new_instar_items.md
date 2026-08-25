# Construct an items table

Adds the `instar_items` class to a data frame of reporting items and
guarantees the canonical shape: a character `value` column carrying only
substantive content (`NA` otherwise), and a `status` factor with levels
`"reported"`, `"not_reported"`, `"not_applicable"`.

## Usage

``` r
new_instar_items(x)
```

## Arguments

- x:

  A data frame with at least `item_id` and `value` columns.

## Value

`x` with a canonical `status` column and the `instar_items` class
prepended.

## Details

If `x` has no `status` column, one is derived from `value` via
[`.derive_status()`](https://instar-statement.org/reference/dot-derive_status.md),
which honours `"NA"` / `"N/A"` strings as an input shorthand for
not-applicable. Once inside an `instar_items` table, `status` is the
single source of truth.
