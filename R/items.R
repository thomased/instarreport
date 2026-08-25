#' The invertebrate welfare reporting framework
#'
#' A data frame describing the 18 reporting items grouped into eight
#' domains: five welfare domains adapted from the Mellor five-domains
#' model (Nutrition, Environment, Health, Behaviour, Affective state),
#' and three cross-cutting foundations (Subjects, Procedures, Ethics &
#' compliance). End-of-study disposition (`fate_end`) lives within the
#' Health welfare domain.
#'
#' @format A data frame with 18 rows and the following columns:
#' \describe{
#'   \item{order}{integer; canonical display order}
#'   \item{group}{`"welfare"` or `"foundation"`}
#'   \item{domain}{one of eight domain names}
#'   \item{item_id}{short snake_case identifier; the join key for user input}
#'   \item{item}{display name of the item}
#'   \item{description}{prompt text describing what to report}
#'   \item{lab}{applicability in laboratory studies: `"Y"`, `"C"`, or `"-"`}
#'   \item{field}{applicability in field studies: `"Y"`, `"C"`, or `"-"`}
#' }
#'
#' @source White et al. (in prep), \emph{Reporting items for invertebrate welfare}.
#' @export
instar_items <- (function() {
  # Order: foundations block first (Subjects, Procedures, Ethics &
  # compliance), then welfare block (Nutrition, Environment, Health,
  # Behaviour, Affective state). This matches the left-to-right reading
  # order of the figure produced by instar_report().
  cols <- list(
    order = 1:18,
    group = c(
      "foundation", "foundation", "foundation",
      "foundation", "foundation", "foundation",
      "foundation", "foundation", "foundation",
      "welfare",
      "welfare", "welfare", "welfare",
      "welfare", "welfare", "welfare",
      "welfare",
      "welfare"
    ),
    domain = c(
      "Subjects", "Subjects", "Subjects",
      "Procedures", "Procedures", "Procedures",
      "Ethics & Compliance", "Ethics & Compliance", "Ethics & Compliance",
      "Nutrition",
      "Environment", "Environment", "Environment",
      "Health", "Health", "Health",
      "Behaviour",
      "Affective state"
    ),
    item_id = c(
      "subjects_taxon", "subjects_source", "subjects_n",
      "proc_handling", "proc_anaesthesia", "proc_biosecurity",
      "ethics_review", "ethics_endpoints", "ethics_statement",
      "nutrition_diet",
      "env_housing", "env_acclimation", "env_field",
      "health_monitoring", "health_injury", "fate_end",
      "behaviour_general",
      "affect_indicators"
    ),
    item = c(
      "Taxonomic ID, life stage, & sex",
      "Source & culture history",
      "Sample size & attrition",
      "Capture, transport, & handling",
      "Anaesthesia, analgesia, & invasive procedures",
      "Containment & biosecurity",
      "Ethics review, permits, & conservation status",
      "Humane endpoints & non-target impacts",
      "Welfare & 3Rs statement",
      "Diet, feeding, & water",
      "Housing & abiotic conditions",
      "Acclimation",
      "Field site & collection",
      "Health monitoring",
      "Injury & mortality",
      "End of study",
      "Behavioural opportunities, enrichment, & disturbance",
      "Indicators & precautionary measures"
    ),
    description = c(
      "Species identification to the lowest practicable taxonomic level (with method); life stage(s) and sex where determinable or relevant; voucher specimens or reference imagery deposited where appropriate.",
      "Origin: wild-collected (with locality and date), laboratory colony (founding stock, source, date of establishment), or commercial supplier (named). For captive stock: generations in captivity, rearing conditions, and selection or inbreeding history.",
      "Total individuals collected or used and number contributing to analysis, with attrition accounted for. Justification of sample size (a priori power, pilot data, or stated convention). For bulk-sampling or mass-rearing work, report order-of-magnitude counts or ranges, and the unit of replication (colony, cycle, trap-day, batch), rather than individual totals.",
      "Capture method; transport duration, conditions, and mortality. Routine handling and restraint. Marking or tagging method, tag mass where relevant, retention checks. Where individual handling is not practicable (pitfall, Malaise, light, or sticky trapping and similar), report sampling effort (trap-days, trap-nights, deployment volume), trap design and check routine, and measures taken to reduce by-catch, retention time, and trapped-animal suffering.",
      "Anaesthetic or immobilisation agent or method; induction and recovery times; justification. Whether post-procedure analgesia was used, agent and dose, or explicit justification for omission. For surgical/invasive procedures: procedure, instruments, sterility, duration, recovery.",
      "Measures to prevent escape (particularly for non-native taxa) and procedures for disposal of waste and contaminated material.",
      "Institutional or regulatory ethics review and permit numbers, or an explicit statement that none was required. Collection or import permits. IUCN, national, or regional conservation status of focal taxa. Country, state, and any translocation between jurisdictions, including distance from point of collection where relevant.",
      "Predefined criteria for terminating procedures or experiments early in response to welfare concerns, and any instances triggered. For field work: anticipated and observed non-target impacts, with mitigation.",
      "Brief statement summarising welfare considerations and how the three Rs (Replacement, Reduction, Refinement) informed study design.",
      "Composition and source of diet or bait; preparation; feeding frequency and access; provision of water or moisture; any pre- or post-experimental fasting with justification.",
      "Enclosure materials, dimensions, substrate, and structural complexity. Stocking density and grouping. Temperature, humidity, ventilation, photoperiod and lighting, and water parameters for aquatic species. Enclosure cleaning frequency and protocol.",
      "Duration and conditions of any acclimation period before experimental procedures.",
      "Habitat type, location, abiotic conditions, and seasonality. Trap design, placement, deployment duration, checking frequency, and measures to limit injury, predation, exposure, or desiccation.",
      "Methods and criteria for assessing physical condition (responsiveness, posture, integument, autotomy). Any screening for disease or parasites and quarantine procedures. Frequency of welfare checks.",
      "Number and timing of injuries and unexpected deaths, suspected causes, and any interventions or protocol adjustments. For colony or industrial-scale work where individual death counts are not meaningful (because of scale, cannibalism, or routine attrition), report the disease-screening and prevention regime, density and condition monitoring, and any conditions under which cohort losses triggered intervention or protocol change.",
      "Method of killing (euthanasia, sacrifice, or slaughter as contextually appropriate) and justification; release protocols for field-collected animals; continued holding, rehoming, or transfer arrangements; voucher specimen deposition. For mass-rearing work, use the welfare-community terminology for the context (slaughter method for farmed insects). For studies considering release, note the reasoning behind the choice between release, continued holding, rehoming, and slaughter, including disease-spread risk to wild conspecifics and any maladaptation incurred during captivity.",
      "Aspects of the setup that supported or constrained species-typical behaviour. Provision of refugia or enrichment. Measures to reduce ambient disturbance. For social or gregarious species, access to conspecifics and the structure of social grouping. Opportunities for agency and choice (e.g., control over aspects of the physical or social environment).",
      "Taxon-appropriate behavioural and physiological indicators of stress, pain, or distress monitored, and how interpreted. Where capacity for affective experience is uncertain, the precautionary measures adopted."
    ),
    lab = c(
      "Y", "Y", "Y",
      "Y", "C", "Y",
      "Y", "Y", "Y",
      "Y",
      "Y", "Y", "-",
      "Y", "Y", "Y",
      "Y",
      "Y"
    ),
    field = c(
      "Y", "Y", "Y",
      "Y", "C", "C",
      "Y", "Y", "Y",
      "C",
      "C", "C", "Y",
      "C", "Y", "Y",
      "Y",
      "Y"
    )
  )
  data.frame(cols, stringsAsFactors = FALSE)
})()


#' Construct an items table
#'
#' Adds the `instar_items` class to a data frame of reporting items and
#' guarantees the canonical shape: a character `value` column carrying
#' only substantive content (`NA` otherwise), and a `status` factor with
#' levels `"reported"`, `"not_reported"`, `"not_applicable"`.
#'
#' If `x` has no `status` column, one is derived from `value` via
#' [.derive_status()], which honours `"NA"` / `"N/A"` strings as an input
#' shorthand for not-applicable. Once inside an `instar_items` table,
#' `status` is the single source of truth.
#'
#' @param x A data frame with at least `item_id` and `value` columns.
#' @return `x` with a canonical `status` column and the `instar_items`
#'   class prepended.
#' @keywords internal
new_instar_items <- function(x) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  # The fillable CSV names the free-text column `report`, which reads
  # better on a spreadsheet than `value`. Normalise it on the way in.
  if (is.null(x$value) && !is.null(x$report)) {
    x$value <- x$report
    x$report <- NULL
  }
  if (is.null(x$status)) {
    x$status <- .derive_status(x$value)
  } else {
    x$status <- .as_status(x$status)
  }
  # `value` holds substantive content only; blank it wherever the item is
  # not reported or not applicable, so the two never disagree.
  x$value <- as.character(x$value)
  x$value[x$status != "reported"] <- NA_character_
  class(x) <- unique(c("instar_items", class(x)))
  x
}


#' Mark items as not applicable
#'
#' Sets `status` to `"not_applicable"` for the named items, clearing any
#' value they carried. The explicit alternative to the older convention
#' of writing the string `"NA"` into `value`.
#'
#' @param items An items table.
#' @param item_id Character vector of `item_id`s to mark.
#'
#' @return The updated items table.
#'
#' @examples
#' tmpl <- instar_template()
#' tmpl <- instar_na(tmpl, c("env_field", "proc_anaesthesia"))
#'
#' @export
instar_na <- function(items, item_id) {
  items <- validate_items(items)
  unknown <- setdiff(item_id, instar_items$item_id)
  if (length(unknown) > 0) {
    stop("Unknown item_id(s): ", paste(unknown, collapse = ", "),
         call. = FALSE)
  }
  hit <- items$item_id %in% item_id
  items$status[hit] <- "not_applicable"
  items$value[hit]  <- NA_character_
  items
}


#' Return an empty items template for a study
#'
#' Convenience helper that returns a table with one row per framework
#' item, an empty `value` column for the user to fill in, and a `status`
#' column recording each item's state.
#'
#' Write substantive content into `value` to report an item. Leave it
#' blank for items the study does not report. Use [instar_na()] to mark
#' items that do not apply.
#'
#' @param study_type Optional. One of `"lab"`, `"field"`, or `"both"`.
#'   If supplied, items flagged as not applicable in that context are
#'   pre-marked with `status = "not_applicable"`.
#'
#' @return An `instar_items` table with columns `item_id`, `item`,
#'   `domain`, `description`, `value`, `status`.
#'
#' @examples
#' tmpl <- instar_template("lab")
#' head(tmpl)
#'
#' @export
instar_template <- function(study_type = c("both", "lab", "field")) {
  study_type <- match.arg(study_type)
  out <- instar_items[, c("order", "domain", "item_id", "item", "description",
                       "lab", "field")]
  out$value  <- NA_character_
  out$status <- "not_reported"
  if (study_type == "lab") {
    out$status[out$lab == "-"] <- "not_applicable"
  } else if (study_type == "field") {
    out$status[out$field == "-"] <- "not_applicable"
  }
  new_instar_items(
    out[, c("item_id", "item", "domain", "description", "value", "status")]
  )
}


#' Read items from a CSV file
#'
#' Reads a CSV file with at minimum an `item_id` and `value` column. If
#' the file also carries a `status` column it is used directly; otherwise
#' status is derived from `value`, with `"NA"` or `"N/A"` read as
#' not-applicable for compatibility with hand-edited templates. Blank
#' cells are read as empty strings rather than `NA`, so that the literal
#' text `"NA"` keeps its not-applicable meaning.
#'
#' Reserved rows are peeled off rather than returned as items: the usage
#' note is dropped, the paper's details become a `paper` attribute, and
#' the declared framework version becomes a `version` attribute (`NA` if
#' the sheet predates versioning).
#'
#' To read many sheets at once, use [read_instar()].
#'
#' @param path Path to a CSV file.
#' @param ... Additional arguments passed to [utils::read.csv()].
#'
#' @return An `instar_items` table with `item_id`, `value`, and `status`,
#'   carrying `paper` and `version` attributes.
#'
#' @examples
#' \dontrun{
#' items <- read_items("my_items.csv")
#' }
#'
#' @export
read_items <- function(path, ...) {
  # Two read.csv defaults have to be overridden here:
  #
  #   na.strings = character(0)  -- otherwise the literal string "NA" is
  #     turned into a real NA, silently downgrading a not-applicable item
  #     to not-reported.
  #   colClasses = "character"   -- otherwise type.convert() types a
  #     wholly blank `report` column (a freshly written template) as
  #     logical, making every cell NA rather than "".
  args <- utils::modifyList(
    list(file = path, stringsAsFactors = FALSE,
         na.strings = character(0), colClasses = "character"),
    list(...)
  )
  df <- do.call(utils::read.csv, args)

  if (is.null(df$value) && !is.null(df$report)) {
    df$value <- df$report
    df$report <- NULL
  }
  if (!is.null(df$value)) {
    df$value <- as.character(df$value)
    df$value[is.na(df$value)] <- ""
  }
  required <- c("item_id", "value")
  missing <- setdiff(required, names(df))
  if (length(missing) > 0) {
    stop("File `", path, "` is missing required column(s): ",
         paste(missing, collapse = ", "),
         ". Expected an `item_id` column and a `report` (or `value`) column.",
         call. = FALSE)
  }

  # Usage notes are for the human filling the sheet in; drop them.
  df <- df[!df$item_id %in% .HELP_FIELDS, , drop = FALSE]

  # If the item_id column was deleted or emptied, fall back to matching on
  # the display name so the file still reads.
  blank_id <- !nzchar(trimws(df$item_id))
  if (any(blank_id) && !is.null(df$item)) {
    key <- tolower(gsub("\\s+", " ", trimws(df$item)))
    ref <- stats::setNames(
      c(instar_items$item_id, .VERSION_FIELD, .PAPER_FIELDS),
      tolower(gsub("\\s+", " ",
                   c(instar_items$item, .VERSION_ROW[1],
                     unname(.PAPER_LABELS[.PAPER_FIELDS]))))
    )
    df$item_id[blank_id] <- unname(ref[key[blank_id]])
    df <- df[!is.na(df$item_id), , drop = FALSE]
  }

  # The framework version the sheet was completed against. Absent in
  # sheets written before versioning, which read as NA rather than being
  # assumed current: a corpus audit needs to know the difference between
  # "declared v1.0" and "did not say".
  version <- NA_character_
  is_ver <- df$item_id %in% .VERSION_FIELD
  if (any(is_ver)) {
    v <- trimws(as.character(df$value[is_ver]))[1]
    if (!is.na(v) && nzchar(v)) version <- v
    df <- df[!is_ver, , drop = FALSE]
  }

  # Reserved rows carry the paper's own details rather than framework
  # items. Peel them off into an attribute so a single file identifies
  # the study it belongs to.
  is_meta <- df$item_id %in% .PAPER_FIELDS
  paper <- NULL
  if (any(is_meta)) {
    vals <- stats::setNames(
      trimws(as.character(df$value[is_meta])),
      df$item_id[is_meta]
    )
    vals <- vals[nzchar(vals)]
    if (length(vals) > 0) paper <- as.list(vals)
    df <- df[!is_meta, , drop = FALSE]
  }

  out <- new_instar_items(df)
  attr(out, "paper") <- paper
  attr(out, "version") <- version
  out
}


#' Print an items table, grouped by domain
#'
#' Reported items show as `*`, items marked not applicable as `-`, and
#' empty items as `o`.
#'
#' @param x An `instar_items` table.
#' @param ... Unused.
#'
#' @return `x`, invisibly.
#'
#' @examples
#' print(instar_template("lab"))
#'
#' @export
print.instar_items <- function(x, ...) {
  .print_state(merge_for_state(x))
  invisible(x)
}
