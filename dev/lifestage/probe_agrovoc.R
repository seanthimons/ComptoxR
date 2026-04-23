#!/usr/bin/env Rscript
# Phase 36.1: FAO/AGROVOC REST Search Probe
# Tests AGROVOC Skosmos REST API for agricultural and aquaculture lifestage terms.
# Run from project root: Rscript dev/lifestage/probe_agrovoc.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36.1: FAO/AGROVOC REST Search Probe")
cli::cli_text("Querying AGROVOC Skosmos REST API for agricultural/aquaculture terms")
cli::cli_text("")

# -- Test terms per D-14 -------------------------------------------------------

test_agricultural <- c(
  "Fry",
  "Fingerling",
  "Heading",
  "Jointing",
  "Tiller stage",
  "Sapling",
  "Rootstock",
  "Rooted cuttings"
)

# Alternate spellings for terms that may fail preferred label search
test_alternates <- c("tillering", "cuttings")

all_terms <- c(test_agricultural, test_alternates)

# -- AGROVOC search function ---------------------------------------------------

probe_agrovoc_term <- function(term) {
  # Step 1: search for term
  search_result <- tryCatch(
    {
      httr2::request("https://agrovoc.fao.org/browse/rest/v1/search/") |>
        httr2::req_url_query(query = term, lang = "en") |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      cli::cli_warn(c(
        "AGROVOC search endpoint unreachable for {.val {term}}.",
        "i" = "Check network connectivity.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(search_result)) {
    return(list(
      term = term,
      found = FALSE,
      concept_uri = NA_character_,
      preferred_label = NA_character_,
      broader_labels = character(0)
    ))
  }

  results_list <- search_result$results
  if (is.null(results_list) || length(results_list) == 0) {
    return(list(
      term = term,
      found = FALSE,
      concept_uri = NA_character_,
      preferred_label = NA_character_,
      broader_labels = character(0)
    ))
  }

  # Take first result
  first_result <- results_list[[1]]
  concept_uri <- first_result$uri
  preferred_label <- if (!is.null(first_result$prefLabel)) {
    first_result$prefLabel
  } else {
    NA_character_
  }

  # Step 2: fetch concept detail for broader/narrower terms
  broader_labels <- character(0)

  detail <- tryCatch(
    {
      httr2::request("https://agrovoc.fao.org/browse/rest/v1/data/") |>
        httr2::req_url_query(uri = concept_uri) |>
        httr2::req_perform() |>
        httr2::resp_body_json()
    },
    error = function(e) {
      cli::cli_warn(c(
        "AGROVOC detail endpoint unreachable for {.val {term}}.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (!is.null(detail)) {
    # Extract broader term labels if present
    broader_raw <- detail$broader
    if (!is.null(broader_raw) && length(broader_raw) > 0) {
      broader_labels <- vapply(
        broader_raw,
        function(b) if (!is.null(b$prefLabel)) b$prefLabel else NA_character_,
        character(1)
      )
      broader_labels <- broader_labels[!is.na(broader_labels)]
    }
  }

  list(
    term = term,
    found = TRUE,
    concept_uri = concept_uri,
    preferred_label = preferred_label,
    broader_labels = broader_labels
  )
}

# -- Run probes ----------------------------------------------------------------

results <- vector("list", length(all_terms))
names(results) <- all_terms

cli::cli_h2("Agricultural and Aquaculture Terms")

for (term in test_agricultural) {
  cli::cli_h2(term)
  res <- probe_agrovoc_term(term)
  results[[term]] <- res

  if (!res$found) {
    cli::cli_alert_danger("NOT FOUND in AGROVOC")
  } else {
    cli::cli_alert_success("FOUND | URI: {res$concept_uri}")
    cli::cli_text("  Preferred label: {res$preferred_label}")
    if (length(res$broader_labels) > 0) {
      cli::cli_text("  Broader: {paste(res$broader_labels, collapse = ', ')}")
    }
  }
  Sys.sleep(0.5)
}

cli::cli_h2("Alternate Spellings")

for (term in test_alternates) {
  cli::cli_h2(term)
  res <- probe_agrovoc_term(term)
  results[[term]] <- res

  if (!res$found) {
    cli::cli_alert_danger("NOT FOUND in AGROVOC")
  } else {
    cli::cli_alert_success("FOUND | URI: {res$concept_uri}")
    cli::cli_text("  Preferred label: {res$preferred_label}")
    if (length(res$broader_labels) > 0) {
      cli::cli_text("  Broader: {paste(res$broader_labels, collapse = ', ')}")
    }
  }
  Sys.sleep(0.5)
}

# -- Summary table -------------------------------------------------------------

cli::cli_h1("Summary")
cli::cli_text(
  "{.strong term} | {.strong found} | {.strong concept_uri} | {.strong preferred_label}"
)
cli::cli_text(paste(rep("-", 70), collapse = ""))

for (term in all_terms) {
  res <- results[[term]]
  found_str <- if (res$found) "YES" else "NO"
  uri_str <- if (is.na(res$concept_uri)) "NA" else res$concept_uri
  label_str <- if (is.na(res$preferred_label)) "NA" else res$preferred_label
  cli::cli_text("{term} | {found_str} | {uri_str} | {label_str}")
}

cli::cli_text("")
cli::cli_text(
  "Note: AGROVOC may return empty for 'jointing', 'sapling', 'tiller' --"
)
cli::cli_text(
  "  these are valid agricultural terms but may use different preferred labels."
)

cli::cli_h1("Probe Complete")
