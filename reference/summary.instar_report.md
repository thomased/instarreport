# Coverage summary for a report, as a data frame

Returns one row per framework item with its domain, group, and status.
Use this rather than reaching into the object to compute on coverage.

## Usage

``` r
# S3 method for class 'instar_report'
summary(object, ...)
```

## Arguments

- object:

  An object of class `instar_report`.

- ...:

  Unused.

## Value

A data frame with columns `item_id`, `item`, `domain`, `group`, and
`status`.

## Examples

``` r
rep <- instar_report(
  paper = list(title = "Demo", authors = "A"),
  items = instar_template()
)
summary(rep)
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
#>                 domain      group       status
#> 1             Subjects foundation not_reported
#> 2             Subjects foundation not_reported
#> 3             Subjects foundation not_reported
#> 4           Procedures foundation not_reported
#> 5           Procedures foundation not_reported
#> 6           Procedures foundation not_reported
#> 7  Ethics & Compliance foundation not_reported
#> 8  Ethics & Compliance foundation not_reported
#> 9  Ethics & Compliance foundation not_reported
#> 10           Nutrition    welfare not_reported
#> 11         Environment    welfare not_reported
#> 12         Environment    welfare not_reported
#> 13         Environment    welfare not_reported
#> 14              Health    welfare not_reported
#> 15              Health    welfare not_reported
#> 16              Health    welfare not_reported
#> 17           Behaviour    welfare not_reported
#> 18     Affective state    welfare not_reported
```
