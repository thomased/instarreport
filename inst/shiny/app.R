# --------------------------------------------------------------------
# instarreport — Shiny web tool
#
# Lets users fill out the 18-item welfare reporting framework
# interactively (or by uploading a filled INSTAR.csv), preview the
# figure, and download both the figure and the completed INSTAR.csv.
# --------------------------------------------------------------------

library(shiny)

local({
  # Source the bundled R files into globalenv. The same R/ directory
  # ships inside inst/shiny/ both when the app is run locally via
  # instarreport::instar_app() (working directory points at the
  # installed package's inst/shiny) and when it's run under shinylive
  # (where the directory is bundled into the static export). Sourcing
  # always avoids any library() call for the package — which is
  # important because shinylive's static scanner attempts to install
  # any package named in a library() call from the webR binary repo,
  # fails for non-CRAN packages, and on Safari cascades into a stack
  # overflow.
  for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
    sys.source(f, envir = globalenv())
  }
})

use_bslib <- requireNamespace("bslib", quietly = TRUE)

domains_ordered <- unique(instar_items$domain)

# Internal helper
`%||%` <- function(a, b) if (is.null(a) || is.na(a) || identical(a, "")) b else a
nzchar_or <- function(x, default) if (is.null(x) || !nzchar(x)) default else x

# ---------- UI ----------
sidebar_content <- function() {
  tagList(
    fileInput("upload", "Load a filled INSTAR.csv",
              accept = c(".csv", "text/csv")),
    downloadButton("download_blank", "Download blank INSTAR.csv",
                   class = "btn-sm"),
    tags$hr(),
    textInput("paper_title",   "Title",          value = ""),
    textInput("paper_authors", "Authors",        value = ""),
    textInput("paper_journal", "Journal / venue", value = ""),
    textInput("paper_doi",     "DOI",            value = ""),
    selectInput("study_type", "Study type",
                choices = c("Both" = "both", "Laboratory" = "lab",
                            "Field" = "field"),
                selected = "both"),
    actionButton("apply_template", "Reset items to template",
                 class = "btn-sm"),
    tags$hr(),
    # Build the item inputs ONCE on app start.
    lapply(domains_ordered, function(dom) {
      dom_items <- instar_items[instar_items$domain == dom, , drop = FALSE]
      controls <- lapply(seq_len(nrow(dom_items)), function(i) {
        id    <- dom_items$item_id[i]
        label <- dom_items$item[i]
        desc  <- dom_items$description[i]
        tagList(
          tags$label(label, style = "font-weight:600; font-size: 0.9em;"),
          tags$small(desc,
                     style = "display:block; color:#666; margin-bottom:4px;"),
          textAreaInput(
            inputId = paste0("val_", id),
            label = NULL,
            value = "",
            rows = 2, width = "100%",
            placeholder = "Leave blank if not reported; type 'NA' if not applicable"
          )
        )
      })
      tagList(
        tags$h4(dom, style = "margin-top: 14px; color: #2E5F8E;"),
        controls
      )
    }),
    tags$hr(),
    downloadButton("download_csv", "Download INSTAR.csv",
                   class = "btn-primary"),
    downloadButton("download_pdf", "Download figure (PDF)"),
    downloadButton("download_png", "Download figure (PNG)")
  )
}

ui <- if (use_bslib) {
  bslib::page_sidebar(
    title = "Invertebrate welfare reporting",
    sidebar = bslib::sidebar(width = 440, sidebar_content()),
    bslib::card(
      bslib::card_header("Preview"),
      plotOutput("preview", height = "1000px")
    )
  )
} else {
  fluidPage(
    titlePanel("Invertebrate welfare reporting"),
    sidebarLayout(
      sidebarPanel(width = 5, sidebar_content()),
      mainPanel(width = 7,
                h3("Preview"),
                plotOutput("preview", height = "1000px"))
    )
  )
}

# ---------- Server ----------
server <- function(input, output, session) {

  # Read all item inputs into a data frame. This reactive depends on every
  # val_<id> input, so it invalidates whenever any text area changes.
  current_items <- reactive({
    vals <- vapply(instar_items$item_id, function(id) {
      v <- input[[paste0("val_", id)]]
      if (is.null(v)) "" else v
    }, character(1))
    data.frame(item_id = instar_items$item_id, value = vals,
               stringsAsFactors = FALSE)
  })

  # The text areas are free text, so a template row has to be flattened
  # back to the string convention the boxes use: "NA" for not-applicable,
  # empty for not-reported. new_instar_items() reverses this on the way in.
  tmpl_string <- function(tmpl, i) {
    if (identical(as.character(tmpl$status[i]), "not_applicable")) return("NA")
    if (is.na(tmpl$value[i])) return("")
    tmpl$value[i]
  }

  # Push study-type defaults into the existing inputs when the dropdown
  # changes (or on initial load).
  observeEvent(input$study_type, ignoreInit = FALSE, {
    tmpl <- instar_template(input$study_type)
    for (i in seq_len(nrow(tmpl))) {
      id <- tmpl$item_id[i]
      # Only overwrite items that are currently empty, so the user doesn't
      # lose typed content on a study-type change.
      current_val <- isolate(input[[paste0("val_", id)]]) %||% ""
      if (current_val == "" || current_val == "NA") {
        updateTextAreaInput(session, paste0("val_", id),
                            value = tmpl_string(tmpl, i))
      }
    }
  })

  # Reset all inputs to template defaults
  observeEvent(input$apply_template, {
    tmpl <- instar_template(input$study_type)
    for (i in seq_len(nrow(tmpl))) {
      updateTextAreaInput(session, paste0("val_", tmpl$item_id[i]),
                          value = tmpl_string(tmpl, i))
    }
  })

  # Build the report. Wrapped in tryCatch so render errors surface as
  # notifications rather than blanking the preview silently.
  current_report <- reactive({
    paper <- list(
      title   = nzchar_or(input$paper_title,   "Untitled study"),
      authors = nzchar_or(input$paper_authors, "Author(s) not given"),
      journal = nzchar_or(input$paper_journal, NULL),
      doi     = nzchar_or(input$paper_doi,     NULL)
    )
    tryCatch(
      instar_report(current_items(), paper = paper, strict = FALSE),
      error = function(e) {
        showNotification(paste("Error building figure:",
                               conditionMessage(e)),
                         type = "error", duration = 8)
        NULL
      }
    )
  })

  # Render the figure. instar_report() returns data, so go through
  # autoplot() to get the patchwork composition and print that.
  #
  # NOTE the ggplot2:: prefix. This app sources R/ into globalenv rather
  # than loading the package namespace, so the `autoplot` generic is not
  # on the search path -- only the autoplot.instar_report *method* is.
  # A bare autoplot() call is an undefined function here.
  #
  # Safari is sensitive to two things here: (1) the default `res` value
  # was too high and pushed the rendered bitmap past Safari's canvas
  # limits, leaving the preview area blank; (2) the initial-load
  # reactive sometimes does not flush in Safari if every input is NULL,
  # so we tap input$study_type to force at least one non-NULL dependency.
  output$preview <- renderPlot({
    input$study_type  # force a non-NULL reactive dep for Safari
    rep <- current_report()
    if (is.null(rep)) return(NULL)
    print(ggplot2::autoplot(rep))
  }, bg = "white")

  # ---- Upload: populate every input from a filled INSTAR.csv ----------
  observeEvent(input$upload, {
    tryCatch({
      items <- read_items(input$upload$datapath)

      # Item text areas. Flatten back to the free-text convention the
      # boxes use: "NA" for not-applicable, empty for not-reported.
      for (i in seq_len(nrow(items))) {
        st <- as.character(items$status[i])
        txt <- if (identical(st, "not_applicable")) "NA"
               else if (identical(st, "reported") && !is.na(items$value[i]))
                 items$value[i]
               else ""
        updateTextAreaInput(session, paste0("val_", items$item_id[i]),
                            value = txt)
      }

      # Paper details, if the reserved rows were filled in.
      paper <- attr(items, "paper")
      if (!is.null(paper)) {
        for (f in c("title", "authors", "journal", "doi")) {
          if (!is.null(paper[[f]])) {
            updateTextInput(session, paste0("paper_", f), value = paper[[f]])
          }
        }
      }

      showNotification("Loaded INSTAR.csv.", type = "message", duration = 4)
    }, error = function(e) {
      showNotification(paste("Could not read that file:",
                             conditionMessage(e)),
                       type = "error", duration = 10)
    })
  })

  # ---- Downloads ------------------------------------------------------
  output$download_blank <- downloadHandler(
    filename = function() "INSTAR.csv",
    content  = function(file) {
      suppressMessages(write_template(file, study_type = input$study_type))
    }
  )

  output$download_csv <- downloadHandler(
    filename = function() "INSTAR.csv",
    content  = function(file) {
      rep <- current_report()
      if (!is.null(rep)) write_report(rep, file)
    }
  )

  output$download_pdf <- downloadHandler(
    filename = function() "welfare_reporting.pdf",
    content = function(file) {
      rep <- current_report()
      if (!is.null(rep)) save_figure(rep, file)
    }
  )

  output$download_png <- downloadHandler(
    filename = function() "welfare_reporting.png",
    content = function(file) {
      rep <- current_report()
      if (!is.null(rep)) save_figure(rep, file)
    }
  )
}

shinyApp(ui, server)
