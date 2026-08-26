# Coerce a report to a plain data frame

One row per framework item, carrying the paper's identifying details
alongside them. Unlike
[summary()](https://instar-statement.org/reference/summary.instar_report.md),
which returns only the item and its status, this keeps `value`, so it is
the method to use when you want what a study actually reported rather
than whether it reported it.

## Usage

``` r
# S3 method for class 'instar_report'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An object of class `instar_report`.

- row.names:

  Unused, for consistency with the generic.

- optional:

  Unused, for consistency with the generic.

- ...:

  Unused.

## Value

A data frame with columns `title`, `doi`, `item_id`, `item`, `domain`,
`group`, `status`, and `value`.

## Examples

``` r
rep <- instar_report(
  instar_set(instar_template(), subjects_taxon = "Apis mellifera"),
  paper = list(title = "Demo", authors = "A")
)
head(as.data.frame(rep), 3)
#>   title  doi         item_id                            item   domain
#> 1  Demo <NA>  subjects_taxon Taxonomic ID, life stage, & sex Subjects
#> 2  Demo <NA> subjects_source        Source & culture history Subjects
#> 3  Demo <NA>      subjects_n         Sample size & attrition Subjects
#>        group       status          value
#> 1 foundation     reported Apis mellifera
#> 2 foundation not_reported           <NA>
#> 3 foundation not_reported           <NA>
```
