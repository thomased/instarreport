# Reserved item ids carrying paper metadata

The fillable CSV template carries the paper's own details as four
reserved rows at the top of the item table, so that a single deposited
file identifies the study it belongs to.
[`read_items()`](https://instar-statement.org/reference/read_items.md)
splits these out into a `paper` attribute; they are never treated as
framework items.

## Usage

``` r
.PAPER_FIELDS
```
