# Build an invertebrate welfare report

Joins a study's filled-in items against the canonical
[instar_items](https://instar-statement.org/reference/instar_items.md)
framework and returns a report object. The result is *data*, not a plot:
it carries the paper metadata, the resolved item table, and a coverage
summary. Call
[plot()](https://instar-statement.org/reference/plot.instar_report.md)
to draw the standardised figure,
[`save_figure()`](https://instar-statement.org/reference/save_figure.md)
to write that figure to disk, or
[`write_report()`](https://instar-statement.org/reference/write_report.md)
to write the deposit-ready CSV. If you want the figure as an object to
modify further, use
[autoplot()](https://instar-statement.org/reference/autoplot.instar_report.md).

## Usage

``` r
instar_report(
  items,
  paper = NULL,
  value_wrap = 75,
  unknown = c("error", "drop")
)
```

## Arguments

- items:

  A data frame with at least `item_id` and a `report` (or `value`)
  column, optionally a `status` column. Use
  [`instar_template()`](https://instar-statement.org/reference/instar_template.md)
  for an in-session template,
  [`write_template()`](https://instar-statement.org/reference/write_template.md)
  for a fillable CSV, and
  [`instar_na()`](https://instar-statement.org/reference/instar_na.md)
  to mark items that do not apply.

- paper:

  A named list of paper metadata. Required: `title`, `authors`.
  Optional: `journal`, `version`, `doi`. May be omitted if `items` came
  from
  [`read_items()`](https://instar-statement.org/reference/read_items.md)
  on a file carrying the reserved metadata rows, in which case those
  details are used.

- value_wrap:

  Integer; approximate characters per line for the value text when the
  report is plotted. Defaults to `75`.

- unknown:

  What to do with `item_id`s in `items` that are not in the framework.
  `"error"` (the default) stops; `"drop"` warns and ignores them. Passed
  to
  [`validate_items()`](https://instar-statement.org/reference/validate_items.md).

## Value

An object of class `instar_report`: a list with elements `paper`,
`items` (one row per framework item, with `value` and `status`),
`coverage`, `version` (the framework version the items declared, or
`NA`), and `value_wrap`.

## Examples

``` r
tmpl <- instar_template()
tmpl$value[tmpl$item_id == "subjects_taxon"] <-
  "Bombus terrestris (worker female); morphology + COI"
tmpl$status[tmpl$item_id == "subjects_taxon"] <- "reported"
tmpl <- instar_na(tmpl, "proc_anaesthesia")

rep <- instar_report(
  tmpl,
  paper = list(title = "Demo", authors = "Smith et al. (2026)")
)
rep
#> <instar_report>
#>   Demo
#>   1 of 17 applicable items reported (6%); 1 not applicable.
#>   plot() to draw it; save_figure() for a PDF/PNG; write_report() for a depositable CSV.
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
#>                 domain      group         status
#> 1             Subjects foundation       reported
#> 2             Subjects foundation   not_reported
#> 3             Subjects foundation   not_reported
#> 4           Procedures foundation   not_reported
#> 5           Procedures foundation not_applicable
#> 6           Procedures foundation   not_reported
#> 7  Ethics & Compliance foundation   not_reported
#> 8  Ethics & Compliance foundation   not_reported
#> 9  Ethics & Compliance foundation   not_reported
#> 10           Nutrition    welfare   not_reported
#> 11         Environment    welfare   not_reported
#> 12         Environment    welfare   not_reported
#> 13         Environment    welfare   not_reported
#> 14              Health    welfare   not_reported
#> 15              Health    welfare   not_reported
#> 16              Health    welfare   not_reported
#> 17           Behaviour    welfare   not_reported
#> 18     Affective state    welfare   not_reported
```
