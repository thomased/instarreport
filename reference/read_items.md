# Read items from a CSV file

Reads a CSV file with at minimum an `item_id` and `value` column. If the
file also carries a `status` column it is used directly; otherwise
status is derived from `value`, with `"NA"` or `"N/A"` read as
not-applicable for compatibility with hand-edited templates. Blank cells
are read as empty strings rather than `NA`, so that the literal text
`"NA"` keeps its not-applicable meaning.

## Usage

``` r
read_items(path, ...)
```

## Arguments

- path:

  Path to a CSV file.

- ...:

  Additional arguments passed to
  [`utils::read.csv()`](https://rdrr.io/r/utils/read.table.html).

## Value

An `instar_items` table with `item_id`, `value`, and `status`, carrying
`paper` and `version` attributes.

## Details

Reserved rows are peeled off rather than returned as items: the usage
note is dropped, the paper's details become a `paper` attribute, and the
declared framework version becomes a `version` attribute (`NA` if the
sheet predates versioning).

To read many sheets at once, use
[`read_instar()`](https://instar-statement.org/reference/read_instar.md).

## Examples

``` r
if (FALSE) { # \dontrun{
items <- read_items("my_items.csv")
} # }
```
