# Mark items as not applicable

Sets `status` to `"not_applicable"` for the named items, clearing any
value they carried. The explicit alternative to the older convention of
writing the string `"NA"` into `value`.

## Usage

``` r
instar_na(items, item_id)
```

## Arguments

- items:

  An items table.

- item_id:

  Character vector of `item_id`s to mark.

## Value

The updated items table.

## Examples

``` r
tmpl <- instar_template()
tmpl <- instar_na(tmpl, c("env_field", "proc_anaesthesia"))
```
