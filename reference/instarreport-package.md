# instarreport: an R implementation of the INSTAR framework

`instarreport` is the R implementation of **INSTAR** (INvertebrate
Standards for Treatment And Reporting; White et al., in prep), an
18-item reporting standard for invertebrate welfare in research. The
package produces a standardised, publication-ready summary figure in
which each cell carries the substantive content for the corresponding
item (species and provenance, housing conditions, ethics review and
permits, and so on), in the same spirit as the PRISMA and ROSES flow
diagrams for evidence synthesis.

## Three ways to fill out the framework

**Interactive prompt** (see
[`instar_fill()`](https://instar-statement.org/reference/instar_fill.md)):

    items <- instar_fill(save_to = "my_study.csv")

**CSV template** (see
[`write_template()`](https://instar-statement.org/reference/write_template.md),
[`read_items()`](https://instar-statement.org/reference/read_items.md)):

    write_template("my_study.csv")
    # ...edit the value column in Excel...
    items <- read_items("my_study.csv")

**Programmatic**:

    items <- instar_template()
    items$value[items$item_id == "subjects_taxon"] <-
      "Bombus terrestris (worker female); morphology + COI"

## Building the figure

    report <- instar_report(
      paper = list(title = "My study", authors = "Smith et al. (2026)"),
      items = items
    )
    save_figure(report, "fig_S1_welfare_reporting.pdf")

## Auditing many studies

    corpus <- read_instar("supplements/")
    audit  <- instar_audit(corpus)
    summary(audit, by = "journal")

## Web tool

[`instar_app()`](https://instar-statement.org/reference/instar_app.md)
launches a local web interface for filling out the framework with a live
preview.

## See also

Useful links:

- <https://instar-statement.org/>

- <https://github.com/thomased/instarreport>

- Report bugs at <https://github.com/thomased/instarreport/issues>

## Author

**Maintainer**: Thomas E. White <thomas.white026@gmail.com>
([ORCID](https://orcid.org/0000-0002-3976-1734))

Authors:

- Thomas E. White <thomas.white026@gmail.com>
  ([ORCID](https://orcid.org/0000-0002-3976-1734))

- Eleanor Drinkwater
