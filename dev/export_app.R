# Rebuild the shinylive (in-browser) copy of the web tool.
#
#   Rscript dev/export_app.R        # from the package root
#
# The export lands in pkgdown/assets/app/, not docs/, because pkgdown
# cleans its destination on every build and would delete it. Everything
# under pkgdown/assets/ is copied into the built site verbatim, so the
# app is served at <site>/app/ and survives rebuilds.
#
# shinylive::export() regenerates index.html from its own template each
# time, so the page title and the loading notice have to be reapplied
# afterwards. That is what .patch_index() below is for: run this script
# rather than calling shinylive::export() directly, or the notice will
# silently disappear on the next export.

APP_SRC  <- "inst/shiny"
APP_DEST <- "pkgdown/assets/app"

stopifnot(dir.exists(APP_SRC))
if (!requireNamespace("shinylive", quietly = TRUE)) {
  stop("install.packages(\"shinylive\") first.", call. = FALSE)
}

# The bundle sources inst/shiny/R/ into globalenv with no namespace
# attached, so it must not have drifted from R/. Check before exporting:
# shipping a stale bundle is how this app has broken before.
src <- list.files("R", pattern = "\\.R$")
bun <- list.files(file.path(APP_SRC, "R"), pattern = "\\.R$")
shared <- setdiff(intersect(src, bun), c("app.R", "instarreport-package.R"))
stale <- shared[!vapply(shared, function(f) {
  identical(readLines(file.path("R", f), warn = FALSE),
            readLines(file.path(APP_SRC, "R", f), warn = FALSE))
}, logical(1))]
if (length(stale) > 0) {
  stop("inst/shiny/R/ has drifted from R/. Re-copy first: ",
       paste(stale, collapse = ", "), call. = FALSE)
}

message("Exporting ", APP_SRC, " -> ", APP_DEST, " ...")
shinylive::export(APP_SRC, APP_DEST)


#' Reapply the page title and the cold-start notice
#'
#' The notice sits inside the #root container that shinylive mounts the
#' app into, so it is replaced automatically when the app renders. No
#' timer, no observer, nothing to get out of step.
.patch_index <- function(path = file.path(APP_DEST, "index.html")) {
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")

  html <- sub("<title>[^<]*</title>",
              "<title>INSTAR reporting tool</title>", html)

  splash <- paste0(
    '<div id="instar-splash" style="display:flex;height:100%;width:100%;',
    'align-items:center;justify-content:center;font-family:system-ui,',
    '-apple-system,Segoe UI,Roboto,sans-serif;color:#3a3a3a;">',
    '<div style="max-width:30rem;padding:2rem;text-align:center;">',
    '<div style="font-size:1.05rem;font-weight:600;color:#2E5F8E;',
    'margin-bottom:0.6rem;">Starting R in your browser</div>',
    '<p style="margin:0 0 0.8rem 0;line-height:1.5;">',
    'The first visit downloads about 35&nbsp;MB and takes roughly ',
    '30&nbsp;seconds. After that it loads from cache almost instantly.',
    '</p>',
    '<p style="margin:0;font-size:0.9em;color:#6a6a6a;line-height:1.5;">',
    'The whole tool runs inside this tab, so nothing you type is sent ',
    'to a server.</p>',
    '</div></div>'
  )

  html <- sub('(<div style="height: 100vh; width: 100vw" id="root">)',
              paste0("\\1", splash), html)

  if (!grepl("instar-splash", html, fixed = TRUE)) {
    stop("Could not insert the loading notice: shinylive's index.html ",
         "template has changed. Update .patch_index() in dev/export_app.R.",
         call. = FALSE)
  }
  writeLines(html, path)
  message("Patched ", path, ": title + cold-start notice.")
}

.patch_index()

message("\nDone. Commit pkgdown/assets/app/ and push; the pkgdown build ",
        "copies it to <site>/app/.")
