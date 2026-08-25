# Read an INSTAR sheet from a spreadsheet file

The xlsx and csv forms of the sheet carry identical rows, so this
rewrites the sheet to a temporary CSV and hands it to
[`read_items()`](https://instar-statement.org/reference/read_items.md)
rather than duplicating the reserved-row logic.

## Usage

``` r
.read_items_xlsx(path)
```
