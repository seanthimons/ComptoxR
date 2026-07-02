#!/usr/bin/env Rscript
# Phase 36.1: BioPortal Annotator Search Probe
# Tests BioPortal Annotator across specialist ontologies for unresolved lifestage terms.
# Requires free API key from bioportal.bioontology.org set as BIOPORTAL_API_KEY env var.
# Run from project root: Rscript dev/lifestage/probe_bioportal.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36.1: BioPortal Annotator Search Probe")

# -- API key guard -------------------------------------------------------------

bioportal_key <- Sys.getenv("BIOPORTAL_API_KEY")
if (!nzchar(bioportal_key)) {
  cli::cli_alert_warning(c(
    "BIOPORTAL_API_KEY environment variable is not set.",
    "i" = "Obtain a free API key at {.url https://bioportal.bioontology.org}",
    "i" = "Set with: {.code Sys.setenv(BIOPORTAL_API_KEY = 'your_key')}",
    "i" = "Or in shell: {.code export BIOPORTAL_API_KEY=your_key}"
  ))
  quit(save = "no", status = 0)
}

cli::cli_text("Querying BioPortal Annotator across UBERON, ZFA, FBdv, ECOCORE, BTO, EFO, MeSH")
cli::cli_text("")

# -- Test terms per D-05 and D-14 -----------------------------------------------

test_simple <- c("Fry", "Fingerling", "Alevin", "Yearling")

test_complex <- c(
  "Copepodid",
  "Glochidia",
  "Trophozoite",
  "Naiad",
  "Imago"
)

test_out_of_scope <- c("F0 generation", "Exponential growth phase")

all_terms <- c(test_simple, test_complex, test_out_of_scope)

# -- Ontologies to target -------------------------------------------------------

TARGET_ONTOLOGIES <- "UBERON,ZFA,FBdv,ECOCORE,BTO,EFO,MeSH"

# -- BioPortal Annotator function ----------------------------------------------

probe_bioportal_term <- function(term, apikey) {
  response <- tryCatch(
    {
      httr2::request("https://data.bioontology.org/annotator") |>
        httr2::req_url_query(
          text = term,
          ontologies = TARGET_ONTOLOGIES,
          apikey = apikey
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      cli::cli_warn(c(
        "BioPortal endpoint unreachable for {.val {term}}.",
        "i" = "Check network connectivity or API key validity.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(response)) {
    return(list(
      term = term,
      found = FALSE,
      annotations_count = 0L,
      top_annotation = NULL
    ))
  }

  annotations <- response
  if (!is.list(annotations) || length(annotations) == 0) {
    return(list(
      term = term,
      found = FALSE,
      annotations_count = 0L,
      top_annotation = NULL
    ))
  }

  # Extract annotated class info from first annotation
  top_annotation <- tryCatch(
    {
      first <- annotations[[1]]
      annotated_class <- first$annotatedClass
      class_id <- if (!is.null(annotated_class$`@id`)) {
        annotated_class$`@id`
      } else {
        NA_character_
      }
      label <- if (!is.null(annotated_class$prefLabel)) {
        annotated_class$prefLabel
      } else {
        NA_character_
      }
      ontology_acronym <- if (!is.null(annotated_class$links$ontology)) {
        # Extract acronym from ontology link URL
        sub(".*ontologies/([^/]+).*", "\\1", annotated_class$links$ontology)
      } else {
        NA_character_
      }
      match_type <- if (!is.null(first$annotations) && length(first$annotations) > 0) {
        first$annotations[[1]]$matchType
      } else {
        NA_character_
      }
      list(
        class_id = class_id,
        label = label,
        ontology = ontology_acronym,
        match_type = match_type
      )
    },
    error = function(e) NULL
  )

  list(
    term = term,
    found = length(annotations) > 0,
    annotations_count = length(annotations),
    top_annotation = top_annotation
  )
}

# -- Run probes ----------------------------------------------------------------

results <- vector("list", length(all_terms))
names(results) <- all_terms

cli::cli_h2("Simple Terms")

for (term in test_simple) {
  cli::cli_h2(term)
  res <- probe_bioportal_term(term, bioportal_key)
  results[[term]] <- res

  if (is.null(res) || !res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | annotations: {if (is.null(res)) 'ERROR' else res$annotations_count}"
    )
  } else {
    cli::cli_alert_success("FOUND | annotations: {res$annotations_count}")
    if (!is.null(res$top_annotation)) {
      top <- res$top_annotation
      cli::cli_text(
        "  Top: {top$class_id} | {top$label} | {top$ontology} | match: {top$match_type}"
      )
    }
  }
  Sys.sleep(0.5)
}

cli::cli_h2("Complex Terms")

for (term in test_complex) {
  cli::cli_h2(term)
  res <- probe_bioportal_term(term, bioportal_key)
  results[[term]] <- res

  if (is.null(res) || !res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | annotations: {if (is.null(res)) 'ERROR' else res$annotations_count}"
    )
  } else {
    cli::cli_alert_success("FOUND | annotations: {res$annotations_count}")
    if (!is.null(res$top_annotation)) {
      top <- res$top_annotation
      cli::cli_text(
        "  Top: {top$class_id} | {top$label} | {top$ontology} | match: {top$match_type}"
      )
    }
  }
  Sys.sleep(0.5)
}

cli::cli_h2("Out-of-Scope Check Terms")

for (term in test_out_of_scope) {
  cli::cli_h2(term)
  res <- probe_bioportal_term(term, bioportal_key)
  results[[term]] <- res

  if (is.null(res) || !res$found) {
    cli::cli_alert_success(
      "NOT FOUND (expected for out-of-scope) | annotations: {if (is.null(res)) 'ERROR' else res$annotations_count}"
    )
  } else {
    cli::cli_alert_danger(
      "FOUND (unexpected for out-of-scope) | annotations: {res$annotations_count}"
    )
    if (!is.null(res$top_annotation)) {
      top <- res$top_annotation
      cli::cli_text(
        "  Top: {top$class_id} | {top$label} | {top$ontology} | match: {top$match_type}"
      )
    }
  }
  Sys.sleep(0.5)
}

# -- Summary table -------------------------------------------------------------

cli::cli_h1("Summary")
cli::cli_text(
  "{.strong term} | {.strong found} | {.strong annotations} | {.strong top_class} | {.strong ontology}"
)
cli::cli_text(paste(rep("-", 70), collapse = ""))

for (term in all_terms) {
  res <- results[[term]]
  if (is.null(res)) {
    cli::cli_text("{term} | ERROR | NA | NA | NA")
  } else {
    found_str <- if (res$found) "YES" else "NO"
    ann_str <- as.character(res$annotations_count)
    top_class <- if (!is.null(res$top_annotation) && !is.na(res$top_annotation$class_id)) {
      res$top_annotation$class_id
    } else {
      "NA"
    }
    ont_str <- if (!is.null(res$top_annotation) && !is.na(res$top_annotation$ontology)) {
      res$top_annotation$ontology
    } else {
      "NA"
    }
    cli::cli_text("{term} | {found_str} | {ann_str} | {top_class} | {ont_str}")
  }
}

cli::cli_h1("Probe Complete")
