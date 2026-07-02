#!/usr/bin/env Rscript
# Build lifestage taxon inference artifacts from ECOTOX usage counts.
# Produces:
#   - dev/lifestage/provenance/lifestage_taxon_intersections.csv
#   - dev/lifestage/lifestage_taxon_profile.csv
#   - dev/lifestage/lifestage_taxon_priority_nonresolved.csv

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

csv_path <- function(filename) {
  file.path("dev", "lifestage", "source", filename)
}

cli::cli_h1("Lifestage Taxon Router Build")

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
  "  COALESCE(s.eco_group, 'Unknown') AS eco_group,",
  "  COALESCE(s.kingdom, 'Unknown') AS kingdom,",
  "  COALESCE(s.class, 'Unknown') AS class_name,",
  "  COUNT(DISTINCT t.test_id) AS test_count,",
  "  COUNT(DISTINCT t.reference_number) AS citation_count,",
  "  COUNT(DISTINCT COALESCE(c.dtxsid, t.test_cas)) AS compound_count,",
  "  COUNT(DISTINCT t.species_number) AS species_count",
  "FROM lifestage_codes lc",
  "LEFT JOIN tests t ON lc.code = t.organism_lifestage",
  "LEFT JOIN species s ON t.species_number = s.species_number",
  "LEFT JOIN chemicals c ON t.test_cas = c.cas_number",
  "GROUP BY 1,2,3,4",
  sep = "\n"
)

taxon_counts <- DBI::dbGetQuery(con, sql) |>
  tibble::as_tibble() |>
  dplyr::mutate(
    taxon_signal_score = (3 * .data$compound_count) + (2 * .data$citation_count) + .data$species_count
  ) |>
  dplyr::group_by(.data$org_lifestage) |>
  dplyr::mutate(
    total_taxon_signal = sum(.data$taxon_signal_score, na.rm = TRUE),
    taxon_signal_share = dplyr::if_else(
      .data$total_taxon_signal > 0,
      .data$taxon_signal_score / .data$total_taxon_signal,
      0
    )
  ) |>
  dplyr::ungroup()

taxon_intersections <- taxon_counts |>
  dplyr::mutate(
    route_family = vapply(
      seq_len(dplyr::n()),
      function(i) {
        .eco_lifestage_taxon_route_family(
          eco_group = .data$eco_group[[i]],
          kingdom = .data$kingdom[[i]],
          class_name = .data$class_name[[i]]
        )
      },
      character(1)
    )
  )

dominant_taxon <- taxon_counts |>
  dplyr::arrange(
    .data$org_lifestage,
    dplyr::desc(.data$taxon_signal_score),
    dplyr::desc(.data$compound_count),
    dplyr::desc(.data$citation_count),
    dplyr::desc(.data$species_count),
    .data$eco_group
  ) |>
  dplyr::group_by(.data$org_lifestage) |>
  dplyr::slice(1) |>
  dplyr::ungroup() |>
  dplyr::mutate(
    route_family = vapply(
      seq_len(n()),
      function(i) {
        .eco_lifestage_taxon_route_family(
          eco_group = .data$eco_group[[i]],
          kingdom = .data$kingdom[[i]],
          class_name = .data$class_name[[i]]
        )
      },
      character(1)
    )
  )

dominant_keys <- dominant_taxon |>
  dplyr::transmute(
    org_lifestage,
    eco_group,
    kingdom,
    class_name,
    dominant_route = TRUE
  )

taxon_intersections <- taxon_intersections |>
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
  dplyr::left_join(
    dominant_keys,
    by = c("org_lifestage", "eco_group", "kingdom", "class_name")
  ) |>
  dplyr::mutate(
    dominant_route = dplyr::coalesce(.data$dominant_route, FALSE)
  ) |>
  dplyr::select(
    "org_lifestage",
    "eco_group",
    "kingdom",
    "class_name",
    "route_family",
    "compound_count",
    "species_count",
    "citation_count",
    "test_count",
    "taxon_signal_score",
    "total_taxon_signal",
    "taxon_signal_share",
    "dominant_route",
    "source_match_status",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "candidate_score"
  ) |>
  dplyr::arrange(
    .data$org_lifestage,
    dplyr::desc(.data$taxon_signal_score),
    .data$eco_group,
    .data$kingdom,
    .data$class_name
  )

profile <- taxon_intersections |>
  dplyr::filter(.data$dominant_route) |>
  dplyr::select(
    "org_lifestage",
    "source_match_status",
    "eco_group",
    "kingdom",
    "class_name",
    "route_family",
    "compound_count",
    "species_count",
    "citation_count",
    "test_count",
    "taxon_signal_score",
    "taxon_signal_share",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "candidate_score"
  ) |>
  dplyr::arrange(
    dplyr::desc(.data$compound_count),
    dplyr::desc(.data$citation_count),
    dplyr::desc(.data$species_count),
    .data$org_lifestage
  )

nonresolved_priority <- profile |>
  dplyr::filter(.data$source_match_status != "resolved") |>
  dplyr::arrange(
    dplyr::desc(.data$compound_count),
    dplyr::desc(.data$citation_count),
    dplyr::desc(.data$species_count),
    .data$org_lifestage
  )

profile_path <- file.path("dev", "lifestage", "lifestage_taxon_profile.csv")
priority_path <- file.path("dev", "lifestage", "lifestage_taxon_priority_nonresolved.csv")
intersections_path <- file.path("dev", "lifestage", "provenance", "lifestage_taxon_intersections.csv")

utils::write.csv(taxon_intersections, intersections_path, row.names = FALSE, na = "")
utils::write.csv(profile, profile_path, row.names = FALSE, na = "")
utils::write.csv(nonresolved_priority, priority_path, row.names = FALSE, na = "")

cache_dir <- tools::R_user_dir("ComptoxR", "cache")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(profile, file.path(cache_dir, "lifestage_taxon_profile.csv"), row.names = FALSE, na = "")

cli::cli_alert_success(
  "Wrote taxon intersections to {.path {intersections_path}}."
)
cli::cli_alert_success(
  "Wrote taxon profile to {.path {profile_path}}."
)
cli::cli_alert_success(
  "Wrote non-resolved taxon priority queue to {.path {priority_path}}."
)

cli::cli_h2("Top 15 Non-Resolved Taxon Routes")
print(
  nonresolved_priority |>
    dplyr::select(
      "org_lifestage",
      "eco_group",
      "route_family",
      "compound_count",
      "species_count",
      "citation_count"
    ) |>
    utils::head(15),
  n = 15
)
