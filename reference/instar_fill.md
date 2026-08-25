# Interactively fill in the reporting items at the R console

Walks through the 18 framework items in canonical order, prompting for a
value for each. Designed for use at the R or RStudio console. You can
stop at any point with `quit`, save with `save path/to/file.csv`, and
resume later by passing the saved file back in (via
[`read_items()`](https://instar-statement.org/reference/read_items.md))
or the returned object directly.

## Usage

``` r
instar_fill(
  items = NULL,
  study_type = c("both", "lab", "field"),
  save_to = NULL
)
```

## Arguments

- items:

  A data frame of items to start from. If `NULL`, starts from a blank
  [`instar_template()`](https://instar-statement.org/reference/instar_template.md).
  Pass an existing fill in to resume.

- study_type:

  Passed to
  [`instar_template()`](https://instar-statement.org/reference/instar_template.md)
  if `items` is `NULL`.

- save_to:

  Optional path to save to on `save` (without an argument) and on normal
  exit.

## Value

The (possibly partially) filled items data frame, invisibly.

## Details

Each prompt shows the item's domain, name, and description so you do not
need to remember `item_id`s or indexing.

## Examples

``` r
if (FALSE) { # \dontrun{
# Start fresh
items <- instar_fill()

# Save partway and resume later
items <- instar_fill(save_to = "my_study.csv")
# ...later...
items <- instar_fill(read_items("my_study.csv"), save_to = "my_study.csv")
} # }
```
