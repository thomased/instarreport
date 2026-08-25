# Read INSTAR sheets from disk

Reads one or many completed INSTAR sheets and returns them as a single
`instar_corpus`. Point it at a file, a directory, or any mix of both:
the format is worked out from the file extension, and the result has the
same class whether it found one sheet or two hundred.

## Usage

``` r
read_instar(
  where,
  pattern = NULL,
  recursive = FALSE,
  subdir_names = FALSE,
  ext = c("csv", "xlsx"),
  quiet = FALSE,
  strict = FALSE
)
```

## Arguments

- where:

  A file path, a directory, or a character vector of either. Directories
  are searched for readable sheets.

- pattern:

  Optional regular expression to filter file names within directories.
  Applied after the extension filter.

- recursive:

  Logical; search directories recursively. Defaults to `FALSE`.

- subdir_names:

  Logical; when recursing, prefix each sheet's name with its directory
  path relative to `where`. Useful when a corpus is organised into
  folders that mean something (by journal, by year), as the prefix then
  survives into
  [`instar_audit()`](https://instar-statement.org/reference/instar_audit.md)
  as a grouping variable. Defaults to `FALSE`.

- ext:

  File extensions to accept. Defaults to `c("csv", "xlsx")`. Reading
  `.xlsx` requires the readxl package.

- quiet:

  Logical; suppress the progress messages. Defaults to `FALSE`.

- strict:

  Passed to
  [`instar_report()`](https://instar-statement.org/reference/instar_report.md).
  Defaults to `FALSE`, so that a sheet carrying an unrecognised
  `item_id` (a hand-edited row, a later framework version) warns rather
  than failing the whole corpus.

## Value

An object of class `instar_corpus`: a named list of `instar_report`
objects, with attributes `failed` (a data frame of unreadable files and
their error messages) and `path` (what was asked for).

## Details

A file that cannot be read does not stop the run. It is reported in a
warning, left out of the corpus, and recorded with its error message in
the `failed` attribute, so a single corrupt supplement in a large corpus
is a thing to go and look at rather than a dead end.

    corpus <- read_instar("supplements/")
    attr(corpus, "failed")     # what could not be read, and why

## Naming

Sheets are named by their DOI where the reserved rows carry one, and by
file name otherwise. Duplicate DOIs are warned about but kept: the same
study reaching a corpus twice through different routes will otherwise
inflate coverage estimates silently.

## Framework versions

Each sheet declares the framework version it was completed against. A
corpus mixing versions is warned about, because coverage is not
comparable across them: an item absent from half the sheets because it
did not exist yet is not the same as an item those studies failed to
report. Sheets written before versioning declare nothing and read as
`NA`.

## See also

[`read_items()`](https://instar-statement.org/reference/read_items.md)
for a single sheet as an items table,
[`instar_audit()`](https://instar-statement.org/reference/instar_audit.md)
for coverage across a corpus.

## Examples

``` r
if (FALSE) { # \dontrun{
# A directory of deposited supplements
corpus <- read_instar("supplements/")

# Organised by journal, with the folder kept as a grouping variable
corpus <- read_instar("corpus/", recursive = TRUE, subdir_names = TRUE)

# A single sheet, still a corpus of one
corpus <- read_instar("INSTAR.csv")
} # }
```
