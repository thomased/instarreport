# instarreport

**https://instar-statement.org**

<!-- badges: start -->
[![R-CMD-check](https://github.com/thomased/instarreport/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/thomased/instarreport/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/thomased/instarreport/graph/badge.svg)](https://app.codecov.io/gh/thomased/instarreport)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
<!-- badges: end -->

A small R toolkit implementing **INSTAR** (**IN**vertebrate **S**tandards
for **T**reatment **A**nd **R**eporting), an 18-item reporting framework
for invertebrate welfare in research (White et al., in prep). The
empirical baseline and primary intended audience are ecological and
evolutionary research, but the framework applies wherever invertebrates
are used.

The unit of work is a single file, `INSTAR.csv`: one row per reporting
item, with a `report` column you fill in. Deposit it alongside your paper
as supplementary material. It is plain text, so it stays readable and
machine-readable indefinitely; a formatted `INSTAR.xlsx` with the same
rows is available if you would rather work in a spreadsheet.

From that file the package renders a standardised, publication-ready
summary figure in which each cell carries the substantive content for the
corresponding item (species and provenance, housing conditions, ethics
permits, 3Rs reasoning, and so on), in the same spirit as the PRISMA and
ROSES flow diagrams for evidence synthesis.

## Quick start: no installation

Open the web tool at **https://instar-statement.org/app/**. You
can either fill the items in the browser and download both the figure and
the completed `INSTAR.csv`, or download the blank `INSTAR.csv`, fill it in
a spreadsheet, and upload it to get the figure back.

(A second copy runs at https://thomas-white.shinyapps.io/instar/. Both
serve the same app; the shinyapps.io one is a full R session, the one
above runs entirely in your browser.)

Everything below is the R package, for scripted or reproducible use.

## Installation

```r
# install.packages("remotes")
remotes::install_github("thomased/instarreport")
```

## Filling out the framework

Three workflows, all producing the same `items` object that
`instar_report()` consumes.

### 1. The INSTAR.csv sheet (the usual route)

Write the blank sheet, fill in the `report` column, read it back:

```r
library(instarreport)

write_template("INSTAR.csv")
# ...fill the `report` column in Excel, Numbers, or any editor...
items <- read_items("INSTAR.csv")
```

The sheet has one row per reporting item, carrying the item's `domain`,
`item`, `description`, and applicability flags, plus an empty `report`
column at the far right to type into. Reserved rows at the top hold a
usage note, the framework version, and the paper's own details (title,
authors, journal, DOI), so a completed file explains itself and
identifies both the study it belongs to and the framework it was
completed against.

Because the sheet carries the paper's details, `instar_report()` can pick
them up without being told:

```r
report <- instar_report(read_items("INSTAR.csv"))
```

Copies are bundled with the package if you would rather not write one:

```r
system.file("extdata", "INSTAR.csv", package = "instarreport")
```

### 2. Interactive prompt

```r
library(instarreport)
items <- instar_fill(save_to = "INSTAR.csv")
```

This walks through the 18 items in order, showing each one's name,
description, and current value, and prompting you for input. At any
prompt you can type:

- the value, or just press **enter** to keep the current one
- `NA` to mark the item as not applicable to your study
- `skip` to leave it blank (it'll render as "Not reported")
- `back` to return to the previous item
- `save` (or `save other_path.csv`) to write progress to disk
- `quit` to stop and return what you have so far

To resume later, load the saved CSV back in:

```r
items <- instar_fill(read_items("INSTAR.csv"),
                    save_to = "INSTAR.csv")
```

To tweak a single item afterwards:

```r
items <- instar_edit(items, "subjects_n")   # by item_id
items <- instar_edit(items)                 # numbered menu of all 18 items
```

To check your progress at any point:

```r
print(items)
```

### 3. Programmatic fill (for scripts)

```r
items <- instar_set(
  instar_template(study_type = "field"),
  subjects_taxon   = "Bombus terrestris (worker female); COI",
  subjects_source  = "Wild-collected, Royal NP, May 2025",
  subjects_n       = "n=80; n=72 analysed (10% attrition)",
  proc_anaesthesia = NA           # does not apply to this study
  # ...and so on
)
```

`instar_set()` sets both `value` and `status` together. Assigning
`items$value` on its own does **not** work: `status` is the source of
truth, so an item whose status is still `"not_reported"` has its value
discarded when the report is built — silently, with no error.

## Building the figure

Once `items` is filled, the rest is the same regardless of how you got
there:

```r
report <- instar_report(
  items,
  paper = list(
    title   = "My study title",
    authors = "Smith et al. (2026)",
    journal = "Some Journal"
  )
)

report
#> <instar_report>
#>   My study title
#>   14 of 17 applicable items reported (82%); 1 not applicable.
#>   Use plot() to draw it, or save_figure() to write it to disk.

# `report` is data, not a plot. Compute on it:
summary(report)                 # one row per item, with status
subset(summary(report), status == "not_reported")

# ...or write the two deposit artifacts:
write_report(report, "INSTAR.csv")     # the completed sheet
save_figure(report, "INSTAR.pdf")      # the figure
```

`write_` produces text, `save_` produces figures. `write_report()` writes
the same file shape an author would have filled in by hand, with the
paper's details in the reserved rows, so it round-trips back through
`read_items()`.

If you want the figure as an object to modify before rendering, use
`autoplot()`, which returns the underlying patchwork composition:

```r
autoplot(report) + patchwork::plot_annotation(caption = "Figure S1")
```

## Web tool

**https://instar-statement.org/app/** — no installation required.
Fill the items in the browser with a live preview, or upload a filled
`INSTAR.csv` to render it. Downloads the figure (PDF or PNG) and the
completed `INSTAR.csv`.

For a local copy (and no shinyapps.io free-tier sleep):

```r
instar_app()
```

## Auditing many studies

Once sheets are being deposited, a corpus of them is just a folder.
`read_instar()` takes a file, a directory, or a vector of either, works
out the format from the extension, and always returns the same thing:

```r
corpus <- read_instar("supplements/")
#> Reading 47 files...
#> ================================================================== 47/47
#> Imported 45 sheets; 2 failed.

corpus
#> <instar_corpus>
#>   45 sheets, INSTAR v1.0
#>   median coverage 71% (range 22-100%)
#>   2 files failed to read; see attr(., "failed")
```

A file it cannot read does not stop the run: it warns, skips, and records
the error in `attr(corpus, "failed")` for you to go and look at. Sheets
are named by DOI where they carry one, and duplicate DOIs are flagged,
since the same study counted twice will skew any audit.

`instar_audit()` turns that into coverage per framework item:

```r
audit <- instar_audit(corpus)     # or instar_audit("supplements/")

summary(audit)                    # one row per item
summary(audit, by = "journal")    # ...per item per journal
plot(audit)                       # coverage barchart

# Which items does the literature handle worst?
head(summary(audit)[order(summary(audit)$percent_reported), ])
```

Not-applicable items stay out of the denominator throughout, so an item
that genuinely does not apply to a study is never counted against it.

For studies that predate the framework and have no sheets, score them
into a wide table instead and hand that over:

```r
# one row per paper, one column per item_id, plus any metadata columns
audit <- audit_from_matrix(scores, id = "doi")
```

Columns matching an `item_id` are treated as items; everything else
(`journal`, `year`) rides along as study metadata and becomes available
to `summary(by = )`. Scores are read leniently: `Y`/`yes`/`TRUE`/`1`/`C`
mean reported, `N`/`no`/`FALSE`/`0` mean not, and `NA`/`-`/blank mean not
applicable.

### Framework versions

Every sheet records the INSTAR version it was completed against, in a
reserved row. Reading a corpus that mixes versions warns, because
coverage is not comparable across them: an item absent from half the
sheets because it did not exist yet is not the same as an item those
studies failed to report.

## The framework

The 18 items are split into five welfare domains adapted from Mellor *et al.*
(2020) (Nutrition, Environment, Health, Behaviour, Affective state) and
three cross-cutting foundations (Subjects, Procedures, Ethics & compliance).
End-of-study disposition lives within the Health welfare domain. See
`?instar_items` for the full table, or:

```r
table(instar_items$domain, instar_items$group)
```

## Conventions

In the sheet, the `report` column is all you fill in: write a sentence or
two for items your study reports, leave it blank for items it does not,
and write `NA` for items that do not apply.

In R, that resolves to a `status` column, which is the single source of
truth:

| `status`           | Meaning                          | Renders as                |
|--------------------|----------------------------------|---------------------------|
| `"reported"`       | The study reports this item      | The text in `value`       |
| `"not_reported"`   | The study is silent on it        | *Not reported*, muted     |
| `"not_applicable"` | It does not apply to this study  | *Not applicable*, grey    |

- `value` carries substantive content only, and is `NA` whenever `status`
  is not `"reported"`. The two can never disagree.
- Use `instar_set(items, item_id = NA)` to mark items that do not apply.
- Reading a sheet derives `status` from the `report` column: blanks
  become `"not_reported"`, and `"NA"` or `"N/A"` are honoured as shorthand
  for `"not_applicable"`.
- There is deliberately no `status` column in the sheet, so the two can
  never disagree.

## Citation

If you use `instarreport`, please cite:

> White, T. E. ... & Drinkwater, E. (in prep). INSTAR: reporting items for
> invertebrate welfare in research.

And the package directly:

> White, T. E., & Drinkwater, E. (2026). `instarreport`: INSTAR reporting
> of invertebrate welfare in research. R package version 1.0.0.
> https://instar-statement.org/

`citation("instarreport")` prints both.

## Licence

MIT. See `LICENSE`.
