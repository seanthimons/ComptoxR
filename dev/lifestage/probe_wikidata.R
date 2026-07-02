#!/usr/bin/env Rscript
# Phase 36.1: Wikidata SPARQL Search Probe
# Tests Wikidata SPARQL endpoint for UBERON cross-references on unresolved lifestage terms.
# Run from project root: Rscript dev/lifestage/probe_wikidata.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

cli::cli_h1("Phase 36.1: Wikidata SPARQL Search Probe")
cli::cli_text("Querying Wikidata for concepts with UBERON cross-references (wdt:P1554)")
cli::cli_text("Also probing wdt:P3841 (Animal Diversity Web ID) for broader coverage")
cli::cli_text("")

# -- Test terms per D-05 and D-14 -----------------------------------------------

test_simple <- c("fry", "fingerling", "alevin", "yearling", "weanling")

test_complex <- c("copepodid", "glochidia", "naiad", "trophozoite")

all_terms <- c(test_simple, test_complex)

# -- SPARQL query builders -----------------------------------------------------

make_uberon_query <- function(term) {
  glue::glue(
    'SELECT ?item ?itemLabel ?uberonId WHERE {{
      ?item wdt:P1554 ?uberonId .
      ?item rdfs:label ?itemLabel .
      FILTER(LANG(?itemLabel) = "en")
      FILTER(CONTAINS(LCASE(?itemLabel), "{tolower(term)}"))
    }}
    LIMIT 10'
  )
}

make_adw_query <- function(term) {
  glue::glue(
    'SELECT ?item ?itemLabel ?adwId WHERE {{
      ?item wdt:P3841 ?adwId .
      ?item rdfs:label ?itemLabel .
      FILTER(LANG(?itemLabel) = "en")
      FILTER(CONTAINS(LCASE(?itemLabel), "{tolower(term)}"))
    }}
    LIMIT 10'
  )
}

# -- Wikidata SPARQL request function ------------------------------------------

query_wikidata_sparql <- function(sparql_query, term) {
  tryCatch(
    {
      httr2::request("https://query.wikidata.org/sparql") |>
        httr2::req_url_query(query = sparql_query) |>
        httr2::req_headers(
          Accept = "application/sparql-results+json",
          `User-Agent` = "ComptoxR/dev probe script (verfassergeist@gmail.com)"
        ) |>
        httr2::req_perform() |>
        httr2::resp_body_string() |>
        jsonlite::fromJSON(simplifyDataFrame = TRUE)
    },
    error = function(e) {
      cli::cli_warn(c(
        "Wikidata SPARQL endpoint unreachable for {.val {term}}.",
        "i" = "Wikidata candidates will be skipped.",
        "x" = conditionMessage(e)
      ))
      NULL
    }
  )
}

# -- Probe a single term via both SPARQL patterns ------------------------------

probe_wikidata_term <- function(term) {
  # Query 1: UBERON cross-reference (wdt:P1554)
  uberon_payload <- query_wikidata_sparql(make_uberon_query(term), term)

  uberon_hits <- 0L
  uberon_ids <- character(0)

  if (!is.null(uberon_payload)) {
    bindings <- uberon_payload$results$bindings
    if (is.data.frame(bindings) && nrow(bindings) > 0) {
      uberon_hits <- nrow(bindings)
      if ("uberonId" %in% names(bindings)) {
        uberon_ids <- unique(bindings$uberonId$value)
      }
    }
  }

  Sys.sleep(1)

  # Query 2: Animal Diversity Web ID (wdt:P3841) for broader coverage
  adw_payload <- query_wikidata_sparql(make_adw_query(term), term)

  adw_hits <- 0L

  if (!is.null(adw_payload)) {
    bindings <- adw_payload$results$bindings
    if (is.data.frame(bindings) && nrow(bindings) > 0) {
      adw_hits <- nrow(bindings)
    }
  }

  list(
    term = term,
    wikidata_uberon_hits = uberon_hits,
    wikidata_adw_hits = adw_hits,
    uberon_ids = uberon_ids,
    found = uberon_hits > 0 || adw_hits > 0
  )
}

# -- Run probes ----------------------------------------------------------------

results <- vector("list", length(all_terms))
names(results) <- all_terms

cli::cli_h2("Simple Terms")

for (term in test_simple) {
  cli::cli_h2(term)
  res <- probe_wikidata_term(term)
  results[[term]] <- res

  if (!res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | UBERON hits: {res$wikidata_uberon_hits} | ADW hits: {res$wikidata_adw_hits}"
    )
  } else {
    cli::cli_alert_success(
      "FOUND | UBERON hits: {res$wikidata_uberon_hits} | ADW hits: {res$wikidata_adw_hits}"
    )
    if (length(res$uberon_ids) > 0) {
      cli::cli_text("  UBERON IDs: {paste(res$uberon_ids, collapse = ', ')}")
    }
  }
  Sys.sleep(1)
}

cli::cli_h2("Complex Terms")

for (term in test_complex) {
  cli::cli_h2(term)
  res <- probe_wikidata_term(term)
  results[[term]] <- res

  if (!res$found) {
    cli::cli_alert_danger(
      "NOT FOUND | UBERON hits: {res$wikidata_uberon_hits} | ADW hits: {res$wikidata_adw_hits}"
    )
  } else {
    cli::cli_alert_success(
      "FOUND | UBERON hits: {res$wikidata_uberon_hits} | ADW hits: {res$wikidata_adw_hits}"
    )
    if (length(res$uberon_ids) > 0) {
      cli::cli_text("  UBERON IDs: {paste(res$uberon_ids, collapse = ', ')}")
    }
  }
  Sys.sleep(1)
}

# -- Summary table -------------------------------------------------------------

cli::cli_h1("Summary")
cli::cli_text(
  "{.strong term} | {.strong found} | {.strong uberon_hits} | {.strong adw_hits} | {.strong uberon_ids}"
)
cli::cli_text(paste(rep("-", 70), collapse = ""))

for (term in all_terms) {
  res <- results[[term]]
  found_str <- if (res$found) "YES" else "NO"
  uberon_str <- as.character(res$wikidata_uberon_hits)
  adw_str <- as.character(res$wikidata_adw_hits)
  id_str <- if (length(res$uberon_ids) > 0) {
    paste(res$uberon_ids, collapse = " | ")
  } else {
    "NA"
  }
  cli::cli_text("{term} | {found_str} | {uberon_str} | {adw_str} | {id_str}")
}

cli::cli_text("")
cli::cli_text(
  "Note: Wikidata P1554 = UBERON ID cross-reference; P3841 = Animal Diversity Web ID"
)
cli::cli_text(
  "  If P1554 returns 0 hits, check if the property ID is current via Wikidata property search."
)

cli::cli_h1("Probe Complete")
