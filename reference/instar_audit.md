# Audit reporting coverage across many studies

Summarises how consistently a set of studies reported each framework
item. This is the corpus-level view:
[`instar_report()`](https://instar-statement.org/reference/instar_report.md)
describes one study, `instar_audit()` describes a literature.

## Usage

``` r
instar_audit(x, ...)
```

## Arguments

- x:

  What to audit. Any of:

  - a path to a directory of sheets, or a vector of file paths, which
    are read with
    [`read_instar()`](https://instar-statement.org/reference/read_instar.md);

  - an `instar_corpus`;

  - a list of `instar_report` objects, or of items tables;

  - a data frame of scores in wide form, passed to
    [`audit_from_matrix()`](https://instar-statement.org/reference/audit_from_matrix.md).

- ...:

  Passed to
  [`read_instar()`](https://instar-statement.org/reference/read_instar.md)
  when `x` is a path, or to
  [`audit_from_matrix()`](https://instar-statement.org/reference/audit_from_matrix.md)
  when `x` is a data frame.

## Value

An object of class `instar_audit`: a list with

- `items`, one row per framework item with counts and the percentage of
  applicable studies that reported it;

- `studies`, one row per study with its own coverage (as
  [`summary.instar_corpus()`](https://instar-statement.org/reference/summary.instar_corpus.md)
  returns);

- `long`, one row per study-item pair, the tidy form to compute on;

- `n`, the number of studies.

## See also

[`read_instar()`](https://instar-statement.org/reference/read_instar.md)
to build a corpus,
[`audit_from_matrix()`](https://instar-statement.org/reference/audit_from_matrix.md)
for retrospective scoring.

## Examples

``` r
if (FALSE) { # \dontrun{
# Prospective: a folder of deposited sheets
audit <- instar_audit("supplements/")
audit
summary(audit)
plot(audit)

# Which items does the literature handle worst?
head(summary(audit)[order(summary(audit)$percent_reported), ])
} # }
```
