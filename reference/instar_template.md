# Return an empty items template for a study

Convenience helper that returns a table with one row per framework item,
an empty `value` column for the user to fill in, and a `status` column
recording each item's state.

## Usage

``` r
instar_template(study_type = c("both", "lab", "field"))
```

## Arguments

- study_type:

  Optional. One of `"lab"`, `"field"`, or `"both"`. If supplied, items
  flagged as not applicable in that context are pre-marked with
  `status = "not_applicable"`.

## Value

An `instar_items` table with columns `item_id`, `item`, `domain`,
`description`, `value`, `status`.

## Details

Write substantive content into `value` to report an item. Leave it blank
for items the study does not report. Use
[`instar_na()`](https://instar-statement.org/reference/instar_na.md) to
mark items that do not apply.

## Examples

``` r
tmpl <- instar_template("lab")
head(tmpl)
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
