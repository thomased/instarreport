# Validate user inputs to instar_report()

Checks that the items table is well-formed, that every `item_id` it
references exists in
[instar_items](https://instar-statement.org/reference/instar_items.md),
and that any `status` column uses the canonical levels. Returns the
table in canonical form, with `status` derived from `value` if it was
absent.

## Usage

``` r
validate_items(items, items_ref = instar_items, strict = TRUE)
```

## Arguments

- items:

  A data frame with at least `item_id` and `value` columns.

- items_ref:

  The framework to validate against. Defaults to
  [instar_items](https://instar-statement.org/reference/instar_items.md).

- strict:

  Logical. If `TRUE` (the default), unknown `item_id`s raise an error.
  If `FALSE`, they are warned about and dropped.

## Value

The validated items table, with the `instar_items` class and a canonical
`status` column. Errors if validation fails.

## Examples

``` r
tmpl <- instar_template()
validate_items(tmpl)
#> 
#>   Subjects
#>     o  Taxonomic ID, life stage, & sex
#>     o  Source & culture history
#>     o  Sample size & attrition
#> 
#>   Procedures
#>     o  Capture, transport, & handling
#>     o  Anaesthesia, analgesia, & invasive procedures
#>     o  Containment & biosecurity
#> 
#>   Ethics & Compliance
#>     o  Ethics review, permits, & conservation status
#>     o  Humane endpoints & non-target impacts
#>     o  Welfare & 3Rs statement
#> 
#>   Nutrition
#>     o  Diet, feeding, & water
#> 
#>   Environment
#>     o  Housing & abiotic conditions
#>     o  Acclimation
#>     o  Field site & collection
#> 
#>   Health
#>     o  Health monitoring
#>     o  Injury & mortality
#>     o  End of study
#> 
#>   Behaviour
#>     o  Behavioural opportunities, enrichment, & disturbance
#> 
#>   Affective state
#>     o  Indicators & precautionary measures
#> 
```
