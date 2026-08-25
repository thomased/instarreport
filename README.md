# instarreport

A small R toolkit implementing **INSTAR** (**IN**vertebrate **S**tandards
for **T**reatment **A**nd **R**eporting), an 18-item reporting framework
for invertebrate welfare in research (White et al., in prep). The
empirical baseline and primary intended audience are ecological and
evolutionary research, but the framework applies wherever invertebrates
are used.

The package produces a standardised, publication-ready summary figure in
which each cell carries the substantive content for the corresponding
item (species and provenance, housing conditions, ethics permits, 3Rs
reasoning, and so on), in the same spirit as the PRISMA and ROSES flow
diagrams for evidence synthesis.

## Installation

```r
# install.packages("remotes")
remotes::install_github("thomased/instarreport")
```

## Three ways to fill out the framework

Pick whichever fits your workflow. All three produce the same kind of
`items` object that `instar_report()` consumes.

### 1. Interactive prompt (recommended for first-time users)

```r
library(instarreport)
items <- instar_fill(save_to = "my_study_items.csv")
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
items <- instar_fill(read_items("my_study_items.csv"),
                    save_to = "my_study_items.csv")
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

### 2. Fill out a CSV template

For collaborators who'd rather work in Excel, or when items are spread
across several people, write a blank template and fill the `value` column:

```r
write_template("my_study_items.csv", study_type = "field")
# ...edit the file in Excel / Numbers / a text editor...
items <- read_items("my_study_items.csv")
```

The template CSV has one row per item with `item_id`, `item`, `domain`,
`description`, and an empty `value` column. The `item`, `domain`, and
`description` columns are there as on-page reminders of what each item
asks for; they're ignored when the CSV is loaded back, so only `item_id`
and `value` are strictly required.

A bundled blank template is also available without writing anything:

```r
template_path <- system.file("extdata", "template_items.csv",
                             package = "instarreport")
file.copy(template_path, "my_study_items.csv")
```

A filled example (a notional bumblebee study) is at:

```r
system.file("extdata", "example_items.csv", package = "instarreport")
```

### 3. Programmatic fill (for scripts)

```r
items <- instar_template(study_type = "field")

report_item <- function(items, id, text) {
  items$value[items$item_id == id]  <- text
  items$status[items$item_id == id] <- "reported"
  items
}

items <- report_item(items, "subjects_taxon",  "Bombus terrestris (worker female); COI")
items <- report_item(items, "subjects_source", "Wild-collected, Royal NP, May 2025")
items <- report_item(items, "subjects_n",      "n=80; n=72 analysed (10% attrition)")
items <- instar_na(items, "proc_anaesthesia")   # mark items that don't apply
# ...and so on
```

## Building the figure

Once `items` is filled, the rest is the same regardless of how you got
there:

```r
report <- instar_report(
  paper = list(
    title   = "My study title",
    authors = "Smith et al. (2026)",
    journal = "Some Journal"
  ),
  items = items
)

report
#> <instar_report>
#>   My study title
#>   14 of 17 applicable items reported (82%); 1 not applicable.
#>   Use plot() to draw it, or instar_save() to write it to disk.

# `report` is data, not a plot. Compute on it:
summary(report)                 # one row per item, with status
subset(summary(report), status == "not_reported")

# ...or render it:
plot(report)                                  # draw it
instar_save(report, "fig_S1_welfare_reporting.pdf")   # or write to file
```

If you want the figure as an object to modify before rendering, use
`autoplot()`, which returns the underlying patchwork composition:

```r
autoplot(report) + patchwork::plot_annotation(caption = "Figure S1")
```

## Web tool

A hosted version of the app is available at
**https://thomas-white.shinyapps.io/instar/** — no installation
required, just open it in any browser.

For a local copy with live preview (and no shinyapps.io free-tier
sleep), launch the bundled Shiny app:

```r
instar_app()
```

## The framework

The 18 items are split into five welfare domains adapted from Mellor *et al.*
(2020) (Nutrition, Environment, Health, Behaviour, Affective state) and
three cross-cutting foundations (Subjects, Procedures, Ethics & compliance).
End-of-study disposition lives within the Health welfare domain. See
`?framework` for the full table, or:

```r
table(instar_items$domain, instar_items$group)
```

## Conventions

Every item carries a `status`, which is the single source of truth:

| `status`           | Meaning                          | Renders as                |
|--------------------|----------------------------------|---------------------------|
| `"reported"`       | The study reports this item      | The text in `value`       |
| `"not_reported"`   | The study is silent on it        | *Not reported*, muted     |
| `"not_applicable"` | It does not apply to this study  | *Not applicable*, grey    |

- `value` carries substantive content only, and is `NA` whenever `status`
  is not `"reported"`. The two can never disagree.
- Use `instar_na(items, "item_id")` to mark items that do not apply.
- Reading a CSV with no `status` column derives it from `value`: blanks
  become `"not_reported"`, and the strings `"NA"` or `"N/A"` are honoured
  as shorthand for `"not_applicable"`.
- Otherwise, write a concise sentence or two of substantive content per
  cell, exactly as you would in the methods paragraph.

## Citation

If you use `instarreport`, please cite:

> White, T. E. ... & Drinkwater, E. (in prep). INSTAR: reporting items for
> invertebrate welfare in research.

And the package directly:

> White, T. E. ... & Drinkwater, E. (2026). `instarreport`: An R
> implementation of the INSTAR framework. R package version 0.1.0.
> https://github.com/thomased/instarreport.

## Licence

MIT. See `LICENSE`.
