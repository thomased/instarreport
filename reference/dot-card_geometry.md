# Compute per-card content geometry

Returns a data frame with one row per item plus attributes describing
the card's total line budget. Used both for laying out items inside a
card and for sizing cards in the patchwork stack.

## Usage

``` r
.card_geometry(domain_name, data, value_wrap = 75)
```
