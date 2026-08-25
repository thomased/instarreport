# The invertebrate welfare reporting framework

A data frame describing the 18 reporting items grouped into eight
domains: five welfare domains adapted from the Mellor five-domains model
(Nutrition, Environment, Health, Behaviour, Affective state), and three
cross-cutting foundations (Subjects, Procedures, Ethics & compliance).
End-of-study disposition (`fate_end`) lives within the Health welfare
domain.

## Usage

``` r
instar_items
```

## Format

A data frame with 18 rows and the following columns:

- order:

  integer; canonical display order

- group:

  `"welfare"` or `"foundation"`

- domain:

  one of eight domain names

- item_id:

  short snake_case identifier; the join key for user input

- item:

  display name of the item

- description:

  prompt text describing what to report

- lab:

  applicability in laboratory studies: `"Y"`, `"C"`, or `"-"`

- field:

  applicability in field studies: `"Y"`, `"C"`, or `"-"`

## Source

White et al. (in prep), *Reporting items for invertebrate welfare*.
