# Current version of the INSTAR framework

The version of the item set defined in
[instar_items](https://instar-statement.org/reference/instar_items.md).
Stamped into every sheet written by
[`write_template()`](https://instar-statement.org/reference/write_template.md)
and
[`write_report()`](https://instar-statement.org/reference/write_report.md),
so a deposited file records which framework it was completed against.

## Usage

``` r
.INSTAR_VERSION
```

## Details

This matters most when auditing a corpus: if a later version adds,
removes, or redefines an item, coverage figures computed across a
mixed-version corpus are not comparable. An item absent from half the
sheets because it did not exist yet is not the same as an item those
studies failed to report.
[`read_instar()`](https://instar-statement.org/reference/read_instar.md)
warns when a corpus mixes versions.
