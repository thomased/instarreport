# Subset a corpus

Keeps the `instar_corpus` class, so that `corpus[1:10]` and
`corpus[sapply(corpus, f)]` still print and audit as corpora.

## Usage

``` r
# S3 method for class 'instar_corpus'
x[i]
```

## Arguments

- x:

  An `instar_corpus`.

- i:

  Index.

## Value

An `instar_corpus`.
