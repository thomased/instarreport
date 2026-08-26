# Package index

## The framework

The 18 reporting items, and how to get a blank set of them to fill in.

- [`instar_items`](https://instar-statement.org/reference/instar_items.md)
  : The invertebrate welfare reporting framework
- [`instar_template()`](https://instar-statement.org/reference/instar_template.md)
  : Return an empty items template for a study
- [`instar_set()`](https://instar-statement.org/reference/instar_set.md)
  : Record what a study reports for one or more items

## Completing a report

Three routes to the same items table: the INSTAR.csv sheet, an
interactive prompt, or direct assignment in a script.

- [`read_items()`](https://instar-statement.org/reference/read_items.md)
  : Read items from a CSV file
- [`write_template()`](https://instar-statement.org/reference/write_template.md)
  : Write a blank CSV for authors to fill in
- [`write_items()`](https://instar-statement.org/reference/write_items.md)
  : Write a filled-in items table to an INSTAR CSV
- [`instar_fill()`](https://instar-statement.org/reference/instar_fill.md)
  : Interactively fill in the reporting items at the R console
- [`instar_edit()`](https://instar-statement.org/reference/instar_edit.md)
  : Edit a single item
- [`print(`*`<instar_items>`*`)`](https://instar-statement.org/reference/print.instar_items.md)
  : Print an items table, grouped by domain

## Reports and figures

Turning completed items into a report object, and from there into the
standardised one-page figure or a depositable sheet.

- [`instar_report()`](https://instar-statement.org/reference/instar_report.md)
  : Build an invertebrate welfare report
- [`print(`*`<instar_report>`*`)`](https://instar-statement.org/reference/print.instar_report.md)
  : Print method for instar_report
- [`summary(`*`<instar_report>`*`)`](https://instar-statement.org/reference/summary.instar_report.md)
  : Coverage summary for a report, as a data frame
- [`as.data.frame(`*`<instar_report>`*`)`](https://instar-statement.org/reference/as.data.frame.instar_report.md)
  : Coerce a report to a plain data frame
- [`plot(`*`<instar_report>`*`)`](https://instar-statement.org/reference/plot.instar_report.md)
  : Draw the standardised INSTAR figure
- [`autoplot(`*`<instar_report>`*`)`](https://instar-statement.org/reference/autoplot.instar_report.md)
  : Return a report's figure as a plot object
- [`save_figure()`](https://instar-statement.org/reference/save_figure.md)
  : Save a report's figure to disk
- [`write_report()`](https://instar-statement.org/reference/write_report.md)
  : Write a completed INSTAR report to CSV

## Auditing many studies

Reading a corpus of deposited sheets, and summarising reporting coverage
across a literature rather than a single study.

- [`read_instar()`](https://instar-statement.org/reference/read_instar.md)
  : Read INSTAR sheets from disk
- [`print(`*`<instar_corpus>`*`)`](https://instar-statement.org/reference/print.instar_corpus.md)
  : Print an INSTAR corpus
- [`summary(`*`<instar_corpus>`*`)`](https://instar-statement.org/reference/summary.instar_corpus.md)
  : Per-sheet summary of a corpus
- [`as.data.frame(`*`<instar_corpus>`*`)`](https://instar-statement.org/reference/as.data.frame.instar_corpus.md)
  : Coerce a corpus to a plain data frame
- [`` `[`( ``*`<instar_corpus>`*`)`](https://instar-statement.org/reference/sub-.instar_corpus.md)
  : Subset a corpus
- [`c(`*`<instar_corpus>`*`)`](https://instar-statement.org/reference/c.instar_corpus.md)
  : Combine corpora
- [`instar_audit()`](https://instar-statement.org/reference/instar_audit.md)
  : Audit reporting coverage across many studies
- [`audit_from_matrix()`](https://instar-statement.org/reference/audit_from_matrix.md)
  : Build an audit from a wide matrix of scores
- [`print(`*`<instar_audit>`*`)`](https://instar-statement.org/reference/print.instar_audit.md)
  : Print an audit
- [`summary(`*`<instar_audit>`*`)`](https://instar-statement.org/reference/summary.instar_audit.md)
  : Summarise an audit
- [`plot(`*`<instar_audit>`*`)`](https://instar-statement.org/reference/plot.instar_audit.md)
  : Plot reporting coverage across a corpus
- [`autoplot(`*`<instar_audit>`*`)`](https://instar-statement.org/reference/autoplot.instar_audit.md)
  : Return an audit's figure as a plot object

## Validation and the web tool

- [`validate_items()`](https://instar-statement.org/reference/validate_items.md)
  : Validate user inputs to instar_report()
- [`instar_app()`](https://instar-statement.org/reference/instar_app.md)
  : Launch the instarreport web tool

## Package

- [`instarreport`](https://instar-statement.org/reference/instarreport-package.md)
  [`instarreport-package`](https://instar-statement.org/reference/instarreport-package.md)
  : instarreport: an R implementation of the INSTAR framework
