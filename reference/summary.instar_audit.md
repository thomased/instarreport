# Summarise an audit

With no `by`, returns one row per framework item. With `by`, returns one
row per item per group, where `by` names a column of study metadata:
`"journal"` for a corpus read from sheets, or any column that came along
in the scoring matrix.

## Usage

``` r
# S3 method for class 'instar_audit'
summary(object, by = NULL, ...)
```

## Arguments

- object:

  An `instar_audit`.

- by:

  Optional name of a study-level column to group by.

- ...:

  Unused.

## Value

A data frame.

## Examples

``` r
if (FALSE) { # \dontrun{
summary(audit)
summary(audit, by = "journal")
} # }
```
