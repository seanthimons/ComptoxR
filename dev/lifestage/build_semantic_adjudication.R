#!/usr/bin/env Rscript
# Build Phase 36.2 semantic adjudication artifacts from local lifestage CSVs.
# Run from project root: Rscript dev/lifestage/build_semantic_adjudication.R

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))

csv_path <- function(filename) {
  path <- file.path("inst", "extdata", "ecotox", filename)
  if (!file.exists(path)) {
    path <- system.file("extdata", "ecotox", filename, package = "ComptoxR")
  }
  stopifnot(file.exists(path))
  path
}

cli::cli_h1("Phase 36.2 Semantic Adjudication Build")

baseline <- readr::read_csv(csv_path("lifestage_baseline.csv"), show_col_types = FALSE)
derivation <- readr::read_csv(csv_path("lifestage_derivation.csv"), show_col_types = FALSE)
exceptions <- readr::read_csv(csv_path("lifestage_curated_exceptions.csv"), show_col_types = FALSE)
taxon_intersections <- readr::read_csv(
  csv_path("lifestage_taxon_intersections.csv"),
  show_col_types = FALSE
)

resolved_baseline <- baseline |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::arrange(.data$org_lifestage, .data$candidate_rank, dplyr::desc(.data$candidate_score)) |>
  dplyr::group_by(.data$org_lifestage) |>
  dplyr::slice(1) |>
  dplyr::ungroup() |>
  dplyr::select(
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "source_term_label"
  )

dominant_route_family <- taxon_intersections |>
  dplyr::filter(.data$dominant_route) |>
  dplyr::select("org_lifestage", dominant_route_family = "route_family")

exception_metadata <- exceptions |>
  dplyr::mutate(
    exception_changes_semantics = !is.na(.data$replacement_harmonized_life_stage) &
      (
        .data$replacement_harmonized_life_stage != .data$harmonized_life_stage |
          .data$replacement_reproductive_stage != .data$reproductive_stage
      )
  ) |>
  dplyr::select(
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "exception_reason",
    "replacement_status",
    "replacement_source_ontology",
    "replacement_source_term_id",
    "replacement_source_term_label",
    "replacement_harmonized_life_stage",
    "replacement_reproductive_stage",
    "exception_changes_semantics"
  )

broad_source_keys <- resolved_baseline |>
  dplyr::count(.data$source_ontology, .data$source_term_id, name = "term_count") |>
  dplyr::filter(.data$term_count > 1L) |>
  dplyr::semi_join(
    exception_metadata |> dplyr::filter(.data$exception_changes_semantics),
    by = c("source_ontology", "source_term_id")
  ) |>
  dplyr::mutate(broad_source_concept = TRUE) |>
  dplyr::select("source_ontology", "source_term_id", "broad_source_concept")

adjudication <- taxon_intersections |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::select(
    "org_lifestage",
    "eco_group",
    "kingdom",
    "class_name",
    "route_family",
    "taxon_signal_score",
    "taxon_signal_share",
    "dominant_route"
  ) |>
  dplyr::left_join(resolved_baseline, by = "org_lifestage") |>
  dplyr::left_join(derivation, by = c("source_ontology", "source_term_id")) |>
  dplyr::left_join(
    exception_metadata,
    by = c("org_lifestage", "source_ontology", "source_term_id")
  ) |>
  dplyr::left_join(broad_source_keys, by = c("source_ontology", "source_term_id")) |>
  dplyr::left_join(dominant_route_family, by = "org_lifestage") |>
  dplyr::mutate(
    broad_source_concept = dplyr::coalesce(.data$broad_source_concept, FALSE),
    context_scope = dplyr::case_when(
      .data$dominant_route ~ "dominant_context",
      .data$route_family == .data$dominant_route_family ~ "non_dominant_same_route_family",
      TRUE ~ "non_dominant_different_route_family"
    ),
    adjudication_status = dplyr::case_when(
      .data$exception_reason %in% c(
        "semantic_change",
        "ambiguous_route",
        "no_source_backed_candidate"
      ) ~ "approved_exception",
      is.na(.data$harmonized_life_stage) | is.na(.data$reproductive_stage) ~ "needs_manual_review",
      .data$broad_source_concept ~ "needs_context_aware_derivation",
      TRUE ~ "approved_same_semantics"
    ),
    adjudication_reason = dplyr::case_when(
      .data$exception_reason == "semantic_change" ~ "semantic_change",
      .data$exception_reason == "ambiguous_route" ~ "ambiguous_route",
      .data$exception_reason == "no_source_backed_candidate" ~ "no_source_backed_candidate",
      is.na(.data$harmonized_life_stage) | is.na(.data$reproductive_stage) ~ "missing_derivation",
      .data$broad_source_concept ~ "broad_source_concept",
      TRUE ~ "unchanged_harmonized_semantics"
    ),
    reviewer_notes = dplyr::case_when(
      .data$adjudication_status == "needs_context_aware_derivation" ~
        "Source concept is shared by multiple ECOTOX terms and has changed-semantics exception evidence.",
      .data$context_scope == "non_dominant_different_route_family" ~
        "Non-dominant route family differs from the dominant route; review if context changes derivation.",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::select(
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "harmonized_life_stage",
    "reproductive_stage",
    "derivation_source",
    "route_family",
    "eco_group",
    "kingdom",
    "class_name",
    "dominant_route",
    "taxon_signal_score",
    "taxon_signal_share",
    "adjudication_status",
    "adjudication_reason",
    "exception_reason",
    "replacement_status",
    "replacement_source_ontology",
    "replacement_source_term_id",
    "replacement_source_term_label",
    "replacement_harmonized_life_stage",
    "replacement_reproductive_stage",
    "context_scope",
    "reviewer_notes"
  ) |>
  dplyr::arrange(
    .data$org_lifestage,
    dplyr::desc(.data$dominant_route),
    dplyr::desc(.data$taxon_signal_score),
    .data$route_family,
    .data$eco_group,
    .data$kingdom,
    .data$class_name
  )

allowed_status <- c(
  "approved_same_semantics",
  "approved_exception",
  "policy_hold_unresolved",
  "needs_context_aware_derivation",
  "needs_manual_review"
)
allowed_reason <- c(
  "unchanged_harmonized_semantics",
  "semantic_change",
  "ambiguous_route",
  "no_source_backed_candidate",
  "broad_source_concept",
  "missing_derivation",
  "unresolved_policy_tail"
)

baseline_gaps <- resolved_baseline |>
  dplyr::distinct(.data$org_lifestage) |>
  dplyr::anti_join(adjudication |> dplyr::distinct(.data$org_lifestage), by = "org_lifestage")
if (nrow(baseline_gaps) > 0) {
  cli::cli_abort(
    "{nrow(baseline_gaps)} resolved baseline term(s) missing adjudication: {.val {baseline_gaps$org_lifestage}}"
  )
}

expected_contexts <- taxon_intersections |>
  dplyr::filter(.data$source_match_status == "resolved") |>
  dplyr::distinct(.data$org_lifestage, .data$eco_group, .data$kingdom, .data$class_name)
missing_contexts <- expected_contexts |>
  dplyr::anti_join(
    adjudication |>
      dplyr::distinct(.data$org_lifestage, .data$eco_group, .data$kingdom, .data$class_name),
    by = c("org_lifestage", "eco_group", "kingdom", "class_name")
  )
duplicate_contexts <- adjudication |>
  dplyr::count(.data$org_lifestage, .data$eco_group, .data$kingdom, .data$class_name) |>
  dplyr::filter(.data$n != 1L)
if (nrow(missing_contexts) > 0) {
  cli::cli_abort(
    "{nrow(missing_contexts)} resolved lifestage/species-group context(s) missing adjudication."
  )
}
if (nrow(duplicate_contexts) > 0) {
  cli::cli_abort(
    "{nrow(duplicate_contexts)} resolved lifestage/species-group context(s) have duplicate adjudication rows."
  )
}

if (length(setdiff(unique(adjudication$adjudication_status), allowed_status)) > 0) {
  cli::cli_abort("Adjudication artifact contains invalid status values.")
}
if (length(setdiff(unique(adjudication$adjudication_reason), allowed_reason)) > 0) {
  cli::cli_abort("Adjudication artifact contains invalid reason values.")
}

exception_gaps <- exceptions |>
  dplyr::anti_join(
    adjudication,
    by = c("org_lifestage", "source_ontology", "source_term_id")
  )
if (nrow(exception_gaps) > 0) {
  cli::cli_abort(
    "{nrow(exception_gaps)} curated exception row(s) missing adjudication coverage."
  )
}

changed_exception_bad_status <- adjudication |>
  dplyr::filter(
    !is.na(.data$replacement_harmonized_life_stage),
    .data$replacement_harmonized_life_stage != .data$harmonized_life_stage |
      .data$replacement_reproductive_stage != .data$reproductive_stage,
    .data$adjudication_status == "approved_same_semantics"
  )
if (nrow(changed_exception_bad_status) > 0) {
  cli::cli_abort(
    "{nrow(changed_exception_bad_status)} changed-semantics exception row(s) were approved as unchanged."
  )
}

action_report <- adjudication |>
  dplyr::filter(
    .data$adjudication_status %in% c(
      "needs_context_aware_derivation",
      "needs_manual_review"
    ) |
      .data$context_scope == "non_dominant_different_route_family"
  ) |>
  dplyr::arrange(
    dplyr::desc(.data$adjudication_status == "needs_manual_review"),
    dplyr::desc(.data$adjudication_status == "needs_context_aware_derivation"),
    .data$org_lifestage,
    dplyr::desc(.data$dominant_route),
    dplyr::desc(.data$taxon_signal_score)
  )

adjudication_path <- file.path(
  "inst",
  "extdata",
  "ecotox",
  "lifestage_semantic_adjudication.csv"
)
action_report_path <- file.path("dev", "lifestage", "semantic_derivation_action_report.csv")

utils::write.csv(adjudication, adjudication_path, row.names = FALSE, na = "")
utils::write.csv(action_report, action_report_path, row.names = FALSE, na = "")

cli::cli_alert_success(
  "Wrote semantic adjudication artifact to {.path {adjudication_path}} with {nrow(adjudication)} row(s)."
)
cli::cli_alert_success(
  "Wrote semantic derivation action report to {.path {action_report_path}} with {nrow(action_report)} row(s)."
)

cli::cli_h2("Adjudication Status Counts")
print(adjudication |> dplyr::count(.data$adjudication_status, sort = TRUE))

cli::cli_h2("Adjudication Reason Counts")
print(adjudication |> dplyr::count(.data$adjudication_reason, sort = TRUE))

cli::cli_h2("Context Scope Counts")
print(adjudication |> dplyr::count(.data$context_scope, sort = TRUE))

