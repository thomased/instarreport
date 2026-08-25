# Edit a single item

Pops up a one-item prompt for the named `item_id`. If `item_id` is
`NULL`, prints a numbered menu of all 18 items and asks you to pick one.
Useful for tweaking a single field after a full fill.

## Usage

``` r
instar_edit(items, item_id = NULL)
```

## Arguments

- items:

  A data frame of items.

- item_id:

  Optional. The canonical `item_id` to edit. If omitted, you'll be shown
  a numbered menu.

## Value

The updated items data frame, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
items <- instar_edit(items, "subjects_taxon")
items <- instar_edit(items)   # numbered menu
} # }
```
