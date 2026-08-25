# Compute a coverage summary from a status vector

Compute a coverage summary from a status vector

## Usage

``` r
.coverage(status)
```

## Arguments

- status:

  A factor or character vector of item statuses.

## Value

A list with counts and the percentage of applicable items reported.
Not-applicable items are excluded from the denominator.
