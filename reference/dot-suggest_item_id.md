# Suggest a near-matching item_id for a typo

Returns a named cli bullet, or a zero-length vector when nothing is
close. Zero-length rather than `""`, so that
[`c()`](https://rdrr.io/r/base/c.html) drops it and cli does not render
an empty bullet.

## Usage

``` r
.suggest_item_id(bad)
```
