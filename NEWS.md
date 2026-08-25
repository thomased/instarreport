# instarreport 0.2.0

Pre-release. The package was renamed from `invertreport` and the API
consolidated before any wider use, so these changes are listed for
orientation rather than as a migration guide.

## Package rename

* `invertreport` is now `instarreport`, matching the INSTAR framework it
  implements and making the package discoverable by searching "instar".
  The repository moved to
  <https://github.com/thomased/instarreport>.

## Reports are data, not plots

* `instar_report()` (was `invert_report()`) now returns a list of class
  `instar_report` holding `paper`, `items`, `coverage`, and
  `value_wrap`. Previously it returned a patchwork object with metadata
  attached as attributes, which meant the result could not be reliably
  computed on.
* `plot()` draws the figure; `autoplot()` returns it as a patchwork
  object for further composition; `summary()` returns one row per
  framework item with its status.
* `instar_save()` (was `save_report()`) renders and writes in one call,
  keeping the content-aware default page height.

## Explicit item status

* Items now carry a `status` factor with levels `"reported"`,
  `"not_reported"`, and `"not_applicable"`. This replaces the previous
  convention where an empty `value` meant not-reported and the literal
  string `"NA"` meant not-applicable.
* `value` holds substantive content only and is `NA` whenever `status`
  is not `"reported"`, so the two cannot disagree.
* `instar_na()` marks items as not applicable.
* Reading a CSV without a `status` column derives it from `value`, and
  still honours `"NA"` / `"N/A"` as shorthand, so hand-edited
  spreadsheets continue to work.
* `read_items()` now sets `na.strings = character(0)`, so the literal
  string `"NA"` is no longer silently converted to a missing value on
  the way in.

## Naming

Function names were reorganised into a single `instar_*` family, with
readr-style `read_*` / `write_*` for file I/O:

| Old                    | New                     |
|------------------------|-------------------------|
| `invert_report()`      | `instar_report()`       |
| `save_report()`        | `instar_save()`         |
| `framework_template()` | `instar_template()`     |
| `fill_items()`         | `instar_fill()`         |
| `edit_item()`          | `instar_edit()`         |
| `run_shiny_app()`      | `instar_app()`          |
| `load_items()`         | `read_items()`          |
| `save_items()`         | `write_items()`         |
| `save_template()`      | `write_template()`      |
| `show_items()`         | `print()` method        |
| `framework`            | `instar_items`          |

## Framework

* The three cross-cutting groups are now called **foundations** rather
  than essentials, in the package, the spreadsheet, and the manuscript.
* `instar_items` gains an `instar_items` S3 class with a domain-grouped
  `print()` method, replacing `show_items()`.


# instarreport 0.1.0

* Initial release as `invertreport`: the 18-item INSTAR framework as
  data, interactive and CSV-based fill workflows, a standardised summary
  figure, and a Shiny web tool.
