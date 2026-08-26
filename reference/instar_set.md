# Record what a study reports for one or more items

The main way to fill in items from a script. Pass
`item_id = "what the study reports"` pairs; each sets both the item's
`value` and its `status` in one step.

## Usage

``` r
instar_set(items, ...)
```

## Arguments

- items:

  An items table, typically from
  [`instar_template()`](https://instar-statement.org/reference/instar_template.md)
  or
  [`read_items()`](https://instar-statement.org/reference/read_items.md).

- ...:

  Named values, one per `item_id`. Names must be valid item ids; see
  `instar_items$item_id`. Values are length-one character (or coercible
  to it), `NA`, or `NULL`.

## Value

The updated items table.

## Details

Setting `value` directly does not work, and fails quietly: `status` is
the single source of truth, and
[`instar_report()`](https://instar-statement.org/reference/instar_report.md)
blanks `value` wherever status is not `"reported"`. A table built by
assigning `value` alone renders as wholly unreported, with no error.
This function exists so that is not a trap you can fall into.

The three states follow the same convention as the `report` column of
the CSV sheet:

|                |                    |
|----------------|--------------------|
| Value passed   | Resulting status   |
| a string       | `"reported"`       |
| `NA`           | `"not_applicable"` |
| `""` or `NULL` | `"not_reported"`   |

## See also

[`instar_fill()`](https://instar-statement.org/reference/instar_fill.md)
for the interactive equivalent.

## Examples

``` r
items <- instar_set(
  instar_template(),
  subjects_taxon  = "Bombus terrestris (worker female); morphology + COI",
  subjects_n      = "n = 80; 72 analysed (10% attrition)",
  env_field       = NA,          # laboratory study, does not apply
  proc_biosecurity = ""          # explicitly leave unreported
)
summary(instar_report(items, paper = list(title = "T", authors = "A")))
#>              item_id                                                 item
#> 1     subjects_taxon                      Taxonomic ID, life stage, & sex
#> 2    subjects_source                             Source & culture history
#> 3         subjects_n                              Sample size & attrition
#> 4      proc_handling                       Capture, transport, & handling
#> 5   proc_anaesthesia        Anaesthesia, analgesia, & invasive procedures
#> 6   proc_biosecurity                            Containment & biosecurity
#> 7      ethics_review        Ethics review, permits, & conservation status
#> 8   ethics_endpoints                Humane endpoints & non-target impacts
#> 9   ethics_statement                              Welfare & 3Rs statement
#> 10    nutrition_diet                               Diet, feeding, & water
#> 11       env_housing                         Housing & abiotic conditions
#> 12   env_acclimation                                          Acclimation
#> 13         env_field                              Field site & collection
#> 14 health_monitoring                                    Health monitoring
#> 15     health_injury                                   Injury & mortality
#> 16          fate_end                                         End of study
#> 17 behaviour_general Behavioural opportunities, enrichment, & disturbance
#> 18 affect_indicators                  Indicators & precautionary measures
#>                 domain      group         status
#> 1             Subjects foundation       reported
#> 2             Subjects foundation   not_reported
#> 3             Subjects foundation       reported
#> 4           Procedures foundation   not_reported
#> 5           Procedures foundation   not_reported
#> 6           Procedures foundation   not_reported
#> 7  Ethics & Compliance foundation   not_reported
#> 8  Ethics & Compliance foundation   not_reported
#> 9  Ethics & Compliance foundation   not_reported
#> 10           Nutrition    welfare   not_reported
#> 11         Environment    welfare   not_reported
#> 12         Environment    welfare   not_reported
#> 13         Environment    welfare not_applicable
#> 14              Health    welfare   not_reported
#> 15              Health    welfare   not_reported
#> 16              Health    welfare   not_reported
#> 17           Behaviour    welfare   not_reported
#> 18     Affective state    welfare   not_reported
```
