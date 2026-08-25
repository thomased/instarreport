# Build an audit from a wide matrix of scores

For auditing studies that never completed an INSTAR sheet, which is
every study published before the framework existed. The usual shape is
one row per paper, one column per framework item, scored by a reader.

## Usage

``` r
audit_from_matrix(scores, id = NULL)
```

## Arguments

- scores:

  A data frame in wide form.

- id:

  Optional name of the column identifying each study. If omitted, the
  first non-item column is used, and failing that the row number.

## Value

An object of class `instar_audit`.

## Details

Columns whose names match an `item_id` in
[instar_items](https://instar-statement.org/reference/instar_items.md)
are treated as items. Every other column is carried through as study
metadata, so a `journal` or `year` column in the input becomes a
grouping variable in `summary(audit, by = )` without any further work.

Cell values are read leniently, because scoring sheets are made by
people: `Y`, `yes`, `TRUE`, and `1` all mean reported; `N`, `no`,
`FALSE`, and `0` mean not reported; `NA`, `N/A`, `-`, and empty cells
mean not applicable. `C` (conditional) counts as reported, matching the
framework's applicability codes.

## Examples

``` r
scores <- data.frame(
  doi = c("10.1/a", "10.1/b"),
  journal = c("J Exp Biol", "Behav Ecol"),
  subjects_taxon = c("Y", "Y"),
  subjects_n = c("Y", "N"),
  env_field = c("NA", "Y")
)
audit <- audit_from_matrix(scores, id = "doi")
#> 15 framework items not present in `scores` and left out of the audit: subjects_source, proc_handling, proc_anaesthesia, proc_biosecurity, ethics_review, ethics_endpoints, ethics_statement, nutrition_diet, env_housing, env_acclimation, health_monitoring, health_injury, fate_end, behaviour_general, affect_indicators
summary(audit)
#>          item_id                            item      domain      group
#> 1 subjects_taxon Taxonomic ID, life stage, & sex    Subjects foundation
#> 2     subjects_n         Sample size & attrition    Subjects foundation
#> 3      env_field         Field site & collection Environment    welfare
#>   n_studies reported not_reported not_applicable applicable percent_reported
#> 1         2        2            0              0          2              100
#> 2         2        1            1              0          2               50
#> 3         2        1            0              1          1              100
```
