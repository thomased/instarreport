# Run R CMD check the way CRAN will run it.
#
#   Rscript dev/check_cran.R
#
# A normal devtools::check() skips the "incoming" checks that CRAN runs
# only on submission. Those are the ones that catch:
#
#   * URLs in DESCRIPTION, README and Rd files that 404, redirect, or
#     are http where https exists
#   * DOIs that do not resolve
#   * spelling and grammar in Title and Description
#   * a package name already taken on CRAN
#   * an invalid or non-standard licence declaration
#   * files left in the tarball that should not be there
#
# Setting _R_CHECK_CRAN_INCOMING_REMOTE_ turns them on, which is what
# `remote = TRUE` does below. It needs a network connection and takes
# noticeably longer, so it is not what you want on every run -- but it is
# what you want before submitting, and it is worth running occasionally
# regardless, since a URL that worked last year may not work now.

if (!requireNamespace("devtools", quietly = TRUE)) {
  stop("install.packages(\"devtools\") first.", call. = FALSE)
}

devtools::check(
  remote = TRUE,     # sets _R_CHECK_CRAN_INCOMING_REMOTE_=TRUE
  manual = TRUE,     # also build the PDF manual, as CRAN does
  incoming = TRUE
)
