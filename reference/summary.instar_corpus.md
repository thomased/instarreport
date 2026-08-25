# Per-sheet summary of a corpus

One row per sheet, with its coverage. For coverage broken down by
framework item across the whole corpus, use
[`instar_audit()`](https://instar-statement.org/reference/instar_audit.md).

## Usage

``` r
# S3 method for class 'instar_corpus'
summary(object, ...)
```

## Arguments

- object:

  An `instar_corpus`.

- ...:

  Unused.

## Value

A data frame with columns `study`, `title`, `journal`, `doi`, `version`,
`folder` (the directory the sheet was read from, relative to what was
asked for), `reported`, `not_reported`, `not_applicable`, `applicable`,
and `percent_reported`.

## Examples

``` r
if (FALSE) { # \dontrun{
corpus <- read_instar("supplements/")
head(summary(corpus))
} # }
```
