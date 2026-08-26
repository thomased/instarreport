# Coerce a corpus to a plain data frame

One row per study per framework item, in long form, carrying what each
study reported. This is the shape to compute on when the question is
about content rather than coverage, such as pulling every housing
description out of a corpus.

## Usage

``` r
# S3 method for class 'instar_corpus'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An `instar_corpus`.

- row.names:

  Unused, for consistency with the generic.

- optional:

  Unused, for consistency with the generic.

- ...:

  Unused.

## Value

A data frame with columns `study`, `title`, `doi`, `journal`, `item_id`,
`item`, `domain`, `group`, `status`, and `value`.

## Details

[summary()](https://instar-statement.org/reference/summary.instar_corpus.md)
gives one row per study, and
[`instar_audit()`](https://instar-statement.org/reference/instar_audit.md)
gives one row per item. This gives both at once.

## Examples

``` r
if (FALSE) { # \dontrun{
d <- as.data.frame(read_instar("supplements/"))

# every housing description in the corpus
subset(d, item_id == "env_housing" & status == "reported",
       select = c(study, value))
} # }
```
