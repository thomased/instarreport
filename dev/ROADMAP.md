# Roadmap

Notes on what the package should and should not grow into. Kept so that
decisions already made do not get re-litigated, and so the two changes
that are genuinely waiting on something have their trigger written down.

## The API is complete for what the package does

Fill a sheet, render it, deposit it, read many back, audit them. Every
export is a promise to keep working, and seventeen exported functions
plus methods is already generous for an 18-item framework. New functions
need to clear a real bar, not just be plausible.

## Considered and rejected

These were proposed early and are not worth building. Each is a one-liner
in base R, or duplicates something that already exists.

| Proposed | Why not |
|---|---|
| `instar_coverage(by = )` | `table(summary(rep)$domain, summary(rep)$status)` does it; `rep$coverage` has the totals. |
| `instar_find()` | Eighteen items. `print(instar_items)` shows them all, and `instar_set()` suggests near-matches on a typo, which was the actual pain. |
| `instar_applicable()` | `instar_template("lab")` already pre-marks non-applicable items, which is the useful form. |
| `instar_checklist()` | `print(instar_template())` is that, and the CSV *is* the checklist. |
| `instar_diff()` | Sheets are CSVs. `waldo::compare()` or `diff` handles it. Revisit only as part of version migration below. |
| `instar_fetch_doi()` | Would pull title, authors and journal from Crossref. Saves typing four fields once per paper, at the cost of a network dependency, offline handling and `\dontrun{}` examples. Defensible, not necessary. Build it only if people ask. |

## Waiting on a trigger

### Deprecate `instar_na()`

`instar_na(items, "env_field")` and `instar_set(items, env_field = NA)`
do the same thing. Two ways to do one thing is two things to document
and explain, and `instar_set()` is the more general.

**Trigger:** after the paper is published. The supplement currently uses
`instar_na()`, so deprecating it now would date the supplement on
arrival. Deprecate with `lifecycle::deprecate_soft()` in the release
after that, and update the supplement, README and vignettes in the same
pass.

### Version migration

`read_instar()` warns when a corpus mixes framework versions, but there
is no way to reconcile them. Once v1.1 exists, every deposited v1.0 sheet
needs a defined upgrade path.

Likely shape is `instar_migrate(items, to = "1.1")`, driven by a stored
table of what changed between versions so the mapping is data rather than
code. `instar_audit()` could then reconcile a mixed corpus rather than
only warning about it.

Three of the six change types are mechanical. A **rename** carries the
value across, a **merge** concatenates two answers, a **removal** drops
one with a note. The other three are the reason not to build this blind:

**Additions force a fourth status.** A v1.0 study that says nothing about
a v1.1 item did not fail to report it, it was never asked. Filing that as
`not_reported` would quietly make every older study look worse, which is
exactly the error the version warning exists to prevent. So a migrated
addition needs something like `not_asked`, excluded from the coverage
denominator the way `not_applicable` is. That ripples into `.coverage()`,
the figure rendering, and the `report` column convention in the sheet.

**Splits cannot be automated.** One paragraph answering the old item
partly answers both new ones, and apportioning it is a judgement. The
function should carry the text to both, mark them for review, and say so
loudly rather than emit a plausible-looking sheet.

**Rescopes are invisible.** Same `item_id`, wider description. The old
answer still sits there looking fine while no longer satisfying the item.
Only the change table can catch this.

**Trigger:** the first framework revision. If v1.1 is three renames this
is thirty lines. If it adds items or splits one, it is a new status level
and a ripple through coverage, rendering and the sheet format. Design it
against a real changelog, not an imagined one.
