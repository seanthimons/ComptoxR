#!/usr/bin/env Rscript
# Phase 36.1: Broader OLS4 Search Probe
# Tests OLS4 with queryFields across all ontologies (no ontology restriction)
# to determine coverage of unresolved lifestage terms.
# Run from project root: Rscript dev/lifestage/probe_ols4.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36.1: Broader OLS4 Search Probe")
cli::cli_text("Removing ontology restriction; adding queryFields=label,synonym,description")
cli::cli_text("Post-filtering to relevant life-stage ontology prefixes")
cli::cli_text("")

# -- Test terms per D-05 -------------------------------------------------------

test_simple <- c("Fry", "Fingerling", "Alevin", "Yearling", "Pullet", "Weanling")

test_complex <- c(
  "Copepodid",
  "Glochidia",
  "Trophozoite",
  "Naiad",
  "Sporeling",
  "Zygospore"
)

test_agricultural <- c("Heading", "Jointing", "Tiller stage", "Sapling")

all_terms <- c(test_simple, test_complex, test_agricultural)

# -- Relevant ontology prefixes for post-filtering ----------------------------

RELEVANT_PREFIXES <- c(
  "UBERON:",
  "PO:",
  "ECOCORE:",
  "BTO:",
  "EFO:",
  "ZFA:",
  "FBdv:",
  "MeSH:"
)

# -- OLS4 search function ------------------------------------------------------

probe_ols4_term <- function(term) {
  response <- tryCatch(
    {
      httr2::request("https://www.ebi.ac.uk/ols4/api/search") |>
        httr2::req_url_query(
          q = term,
          queryFields = "label,synonym,description",
          rows = 25
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON(simplifyDataFrame = TRUE)
    },
    error = function(e) {
      cli::cli_warn(c(
        "OLS4 endpoint unreachable for {.val {term}}.",
        "i" = "Check network connectivity.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )

  if (is.null(response)) {
    return(NULL)
  }

  docs <- response$response$docs
  if (is.null(docs) || !is.data.frame(docs) || nrow(docs) == 0) {
    return(list(
      term = term,
      raw_hits = 0L,
      filtered_hits = 0L,
      top_results = tibble::tibble(),
      found = FALSE,
      best_ontology = NA_character_,
      best_obo_id = NA_character_
    ))
  }

  raw_hits <- nrow(docs)

  # Post-filter by relevant ontology prefixes
  obo_ids <- if ("obo_id" %in% names(docs)) docs$obo_id else rep(NA_character_, nrow(docs))
  keep <- purrr::map_lgl(
    obo_ids,
    function(id) {
      if (is.na(id) || !nzchar(id)) {
        return(FALSE)
      }
      any(startsWith(id, RELEVANT_PREFIXES))
    }
  )
  filtered_docs <- docs[keep, , drop = FALSE]
  filtered_hits <- nrow(filtered_docs)

  # Extract top 3 filtered results
  top_n <- min(3L, filtered_hits)
  top_results <- if (top_n > 0) {
    tibble::tibble(
      obo_id = if ("obo_id" %in% names(filtered_docs)) {
        filtered_docs$obo_id[seq_len(top_n)]
      } else {
        rep(NA_character_, top_n)
      },
      label = if ("label" %in% names(filtered_docs)) {
        filtered_docs$label[seq_len(top_n)]
      } else {
        rep(NA_character_, top_n)
      },
      ontology_name = if ("ontology_name" %in% names(filtered_docs)) {
        filtered_docs$ontology_name[seq_len(top_n)]
      } else {
        rep(NA_character_, top_n)
      }
    )
  } else {
    tibble::tibble()
  }

  best_obo_id <- if (filtered_hits > 0 && "obo_id" %in% names(filtered_docs)) {
    filtered_docs$obo_id[[1]]
  } else {
    NA_character_
  }
  best_ontology <- if (filtered_hits > 0 && "ontology_name" %in% names(filtered_docs)) {
    filtered_docs$ontology_name[[1]]
  } else {
    NA_character_
  }

  list(
    term = term,
    raw_hits = raw_hits,
    filtered_hits = filtered_hits,
    top_results = top_results,
    found = filtered_hits > 0,
    best_ontology = best_ontology,
    best_obo_id = best_obo_id
  )
}

# -- Run probes ----------------------------------------------------------------

results <- vector("list", length(all_terms))
names(results) <- all_terms

cli::cli_h2("Simple Terms")

for (term in test_simple) {
  cli::cli_h2(term)
  res <- probe_ols4_term(term)
  results[[term]] <- res

  if (is.null(res)) {
    cli::cli_alert_danger("Request failed for {.val {term}}")
  } else if (!res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | raw hits: {res$raw_hits} | filtered hits: 0"
    )
  } else {
    cli::cli_alert_success(
      "FOUND | raw hits: {res$raw_hits} | filtered hits: {res$filtered_hits}"
    )
    if (nrow(res$top_results) > 0) {
      for (i in seq_len(nrow(res$top_results))) {
        r <- res$top_results[i, ]
        cli::cli_text(
          "  [{i}] {r$obo_id} | {r$label} | {r$ontology_name}"
        )
      }
    }
  }
  Sys.sleep(0.3)
}

cli::cli_h2("Complex Terms")

for (term in test_complex) {
  cli::cli_h2(term)
  res <- probe_ols4_term(term)
  results[[term]] <- res

  if (is.null(res)) {
    cli::cli_alert_danger("Request failed for {.val {term}}")
  } else if (!res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | raw hits: {res$raw_hits} | filtered hits: 0"
    )
  } else {
    cli::cli_alert_success(
      "FOUND | raw hits: {res$raw_hits} | filtered hits: {res$filtered_hits}"
    )
    if (nrow(res$top_results) > 0) {
      for (i in seq_len(nrow(res$top_results))) {
        r <- res$top_results[i, ]
        cli::cli_text(
          "  [{i}] {r$obo_id} | {r$label} | {r$ontology_name}"
        )
      }
    }
  }
  Sys.sleep(0.3)
}

cli::cli_h2("Agricultural Terms")

for (term in test_agricultural) {
  cli::cli_h2(term)
  res <- probe_ols4_term(term)
  results[[term]] <- res

  if (is.null(res)) {
    cli::cli_alert_danger("Request failed for {.val {term}}")
  } else if (!res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | raw hits: {res$raw_hits} | filtered hits: 0"
    )
  } else {
    cli::cli_alert_success(
      "FOUND | raw hits: {res$raw_hits} | filtered hits: {res$filtered_hits}"
    )
    if (nrow(res$top_results) > 0) {
      for (i in seq_len(nrow(res$top_results))) {
        r <- res$top_results[i, ]
        cli::cli_text(
          "  [{i}] {r$obo_id} | {r$label} | {r$ontology_name}"
        )
      }
    }
  }
  Sys.sleep(0.3)
}

# -- Summary table -------------------------------------------------------------

cli::cli_h1("Summary")
cli::cli_text(
  "{.strong term} | {.strong found} | {.strong best_ontology} | {.strong best_obo_id}"
)
cli::cli_text(paste(rep("-", 60), collapse = ""))

for (term in all_terms) {
  res <- results[[term]]
  if (is.null(res)) {
    cli::cli_text("{term} | ERROR | NA | NA")
  } else {
    found_str <- if (res$found) "YES" else "NO"
    best_ont <- if (is.na(res$best_ontology)) "NA" else res$best_ontology
    best_id <- if (is.na(res$best_obo_id)) "NA" else res$best_obo_id
    cli::cli_text("{term} | {found_str} | {best_ont} | {best_id}")
  }
}

cli::cli_h1("Probe Complete")
