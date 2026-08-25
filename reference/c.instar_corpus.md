# Combine corpora

Concatenates corpora read from different places, re-checking for
duplicate DOIs and mixed framework versions across the combined set.

## Usage

``` r
# S3 method for class 'instar_corpus'
c(...)
```

## Arguments

- ...:

  `instar_corpus` objects, or anything
  [`as_instar_corpus()`](https://instar-statement.org/reference/as_instar_corpus.md)
  accepts.

## Value

An `instar_corpus`.

## Examples

``` r
if (FALSE) { # \dontrun{
corpus <- c(read_instar("2025/"), read_instar("2026/"))
} # }
```
