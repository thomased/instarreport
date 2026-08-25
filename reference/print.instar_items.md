# Print an items table, grouped by domain

Reported items show as `*`, items marked not applicable as `-`, and
empty items as `o`.

## Usage

``` r
# S3 method for class 'instar_items'
print(x, ...)
```

## Arguments

- x:

  An `instar_items` table.

- ...:

  Unused.

## Value

`x`, invisibly.

## Examples

``` r
print(instar_template("lab"))
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
#>     -  Field site & collection
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
