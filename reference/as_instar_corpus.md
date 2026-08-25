# Coerce to an instar_corpus

Accepts anything
[`instar_audit()`](https://instar-statement.org/reference/instar_audit.md)
will take as a corpus: an existing corpus, a list of reports or items
tables, or a path to read.

## Usage

``` r
as_instar_corpus(x, ...)
```

## Arguments

- x:

  An object to coerce.

- ...:

  Passed to
  [`read_instar()`](https://instar-statement.org/reference/read_instar.md)
  when `x` is a path.

## Value

An `instar_corpus`.
