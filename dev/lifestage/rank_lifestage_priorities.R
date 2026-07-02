#!/usr/bin/env Rscript
# Rank ECOTOX lifestage terms for curation priority.
# Produces count-based ranking by compound, species, and citation coverage.
# Run from project root: Rscript dev/lifestage/rank_lifestage_priorities.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

csv_path <- function(filename) {
  file.path("dev", "lifestage", "source", filename)
}

percent_rank_desc <- function(x) {
  dplyr::percent_rank(dplyr::coalesce(x, 0))
}

cli::cli_h1("Lifestage Priority Ranking")

db_path <- eco_path()
if (!file.exists(db_path)) {
  cli::cli_abort("ECOTOX DuckDB not found at {.path {db_path}}.")
}

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

baseline <- readr::read_csv(csv_path("lifestage_baseline.csv"), show_col_types = FALSE)

sql <- paste(
  "SELECT",
  "  lc.description AS org_lifestage,",
  "  COUNT(DISTINCT COALESCE(c.dtxsid, t.test_cas)) AS compound_count,",
  "  COUNT(DISTINCT t.species_number) AS species_count,",
  "  COUNT(DISTINCT t.reference_number) AS citation_count,",
  "  COUNT(DISTINCT t.test_id) AS test_count,",
  "  COUNT(DISTINCT r.result_id) AS result_count",
  "FROM lifestage_codes lc",
  "LEFT JOIN tests t",
  "  ON lc.code = t.organism_lifestage",
  "LEFT JOIN results r",
  "  ON t.test_id = r.test_id",
  "LEFT JOIN chemicals c",
  "  ON t.test_cas = c.cas_number",
  "GROUP BY 1",
  "ORDER BY compound_count DESC, species_count DESC, citation_count DESC",
  sep = "\n"
)

priority <- DBI::dbGetQuery(con, sql) |>
  tibble::as_tibble() |>
  dplyr::left_join(
    baseline |>
      dplyr::select(
        "org_lifestage",
        "source_match_status",
        "source_ontology",
        "source_term_id",
        "source_term_label",
        "candidate_score"
      ),
    by = "org_lifestage"
  ) |>
  dplyr::mutate(
    compound_rank = dplyr::min_rank(dplyr::desc(.data$compound_count)),
    species_rank = dplyr::min_rank(dplyr::desc(.data$species_count)),
    citation_rank = dplyr::min_rank(dplyr::desc(.data$citation_count)),
    compound_percentile = percent_rank_desc(.data$compound_count),
    species_percentile = percent_rank_desc(.data$species_count),
    citation_percentile = percent_rank_desc(.data$citation_count),
    priority_score = round(
      (0.5 * .data$compound_percentile) +
        (0.3 * .data$species_percentile) +
        (0.2 * .data$citation_percentile),
      4
    )
  ) |>
  dplyr::arrange(
    dplyr::desc(.data$priority_score),
    dplyr::desc(.data$compound_count),
    dplyr::desc(.data$species_count),
    dplyr::desc(.data$citation_count),
    .data$org_lifestage
  )

all_path <- file.path("dev", "lifestage", "lifestage_priority_rankings.csv")
focus_path <- file.path("dev", "lifestage", "lifestage_priority_rankings_nonresolved.csv")

utils::write.csv(priority, all_path, row.names = FALSE, na = "")
utils::write.csv(
  dplyr::filter(priority, .data$source_match_status != "resolved"),
  focus_path,
  row.names = FALSE,
  na = ""
)

cli::cli_alert_success(
  "Wrote all-term priority ranking to {.path {all_path}}."
)
cli::cli_alert_success(
  "Wrote non-resolved priority ranking to {.path {focus_path}}."
)

cli::cli_h2("Top 15 Non-Resolved Terms")
top_nonresolved <- priority |>
  dplyr::filter(.data$source_match_status != "resolved") |>
  dplyr::select(
    "org_lifestage",
    "source_match_status",
    "compound_count",
    "species_count",
    "citation_count",
    "priority_score"
  ) |>
  utils::head(15)
print(top_nonresolved, n = 15)

cli::cli_h2("Common Terms of Interest")
focus_terms <- priority |>
  dplyr::filter(
    .data$org_lifestage %in%
      c(
        "Fry",
        "Froglet",
        "Fingerling",
        "Alevin",
        "Yearling",
        "Weanling",
        "Copepodid",
        "Young of year",
        "Sexually mature"
      )
  ) |>
  dplyr::select(
    "org_lifestage",
    "source_match_status",
    "compound_count",
    "species_count",
    "citation_count",
    "priority_score"
  )
print(focus_terms, n = nrow(focus_terms))
