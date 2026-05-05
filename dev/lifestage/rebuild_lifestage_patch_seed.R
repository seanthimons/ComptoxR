# Rebuild the installed ECOTOX lifestage patch seed from maintainer inputs.
# Run from project root:
#   Rscript dev/lifestage/rebuild_lifestage_patch_seed.R

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

source_dir <- file.path("dev", "lifestage", "source")
curation_dir <- file.path("dev", "lifestage", "curation")
seed_path <- file.path("inst", "extdata", "ecotox", "lifestage_patch_seed.csv")
queue_path <- file.path(curation_dir, "lifestage_curation_queue.csv")

abort <- function(message) {
  stop(message, call. = FALSE)
}

required_queue_cols <- c(
  "org_lifestage",
  "current_status",
  "proposed_action",
  "query_override",
  "source_ontology",
  "source_term_id",
  "source_term_label",
  "harmonized_life_stage",
  "reproductive_stage",
  "reviewer",
  "decision_notes"
)
allowed_actions <- c(
  "accept_unresolved",
  "requery",
  "force_candidate",
  "force_unresolved",
  "change_derivation"
)

baseline <- read_csv(file.path(source_dir, "lifestage_baseline.csv"), show_col_types = FALSE)
derivation <- read_csv(file.path(source_dir, "lifestage_derivation.csv"), show_col_types = FALSE)
queue <- read_csv(queue_path, show_col_types = FALSE)

missing_queue_cols <- setdiff(required_queue_cols, names(queue))
if (length(missing_queue_cols) > 0L) {
  abort(paste("Curation queue missing column(s):", paste(missing_queue_cols, collapse = ", ")))
}

invalid_actions <- setdiff(unique(queue$proposed_action), allowed_actions)
if (length(invalid_actions) > 0L) {
  abort(paste("Curation queue has invalid proposed_action value(s):", paste(invalid_actions, collapse = ", ")))
}

duplicates <- queue |>
  count(.data$org_lifestage) |>
  filter(.data$n > 1L)
if (nrow(duplicates) > 0L) {
  abort(paste("Duplicate curation queue decision(s):", paste(duplicates$org_lifestage, collapse = ", ")))
}

force_candidate_gaps <- queue |>
  filter(.data$proposed_action == "force_candidate") |>
  filter(
    is.na(.data$source_ontology) |
      is.na(.data$source_term_id) |
      is.na(.data$source_term_label) |
      is.na(.data$harmonized_life_stage) |
      is.na(.data$reproductive_stage)
  )
if (nrow(force_candidate_gaps) > 0L) {
  abort(paste("force_candidate row(s) missing required source/derivation fields:", paste(force_candidate_gaps$org_lifestage, collapse = ", ")))
}

unresolved_note_gaps <- queue |>
  filter(.data$proposed_action %in% c("accept_unresolved", "force_unresolved")) |>
  filter(is.na(.data$reviewer) | is.na(.data$decision_notes) | !nzchar(.data$decision_notes))
if (nrow(unresolved_note_gaps) > 0L) {
  abort(paste("unresolved decision row(s) missing reviewer notes:", paste(unresolved_note_gaps$org_lifestage, collapse = ", ")))
}

resolved_derivation <- derivation |>
  filter(.data$source_ontology != "ECOTOX_UNRESOLVED")
unresolved_derivation <- derivation |>
  filter(.data$source_ontology == "ECOTOX_UNRESOLVED") |>
  transmute(
    org_lifestage = .data$source_term_id,
    unresolved_harmonized_life_stage = .data$harmonized_life_stage,
    unresolved_reproductive_stage = .data$reproductive_stage,
    unresolved_derivation_source = .data$derivation_source
  )

seed <- baseline |>
  left_join(resolved_derivation, by = c("source_ontology", "source_term_id")) |>
  left_join(unresolved_derivation, by = "org_lifestage") |>
  mutate(
    harmonized_life_stage = if_else(
      .data$source_match_status != "resolved" & is.na(.data$harmonized_life_stage),
      .data$unresolved_harmonized_life_stage,
      .data$harmonized_life_stage
    ),
    reproductive_stage = if_else(
      .data$source_match_status != "resolved" & is.na(.data$reproductive_stage),
      .data$unresolved_reproductive_stage,
      .data$reproductive_stage
    ),
    derivation_source = if_else(
      .data$source_match_status != "resolved" & is.na(.data$derivation_source),
      .data$unresolved_derivation_source,
      .data$derivation_source
    ),
    candidate_reason = coalesce(.data$candidate_reason, .data$source_match_status, "needs_review")
  ) |>
  select(
    all_of(names(baseline)),
    "harmonized_life_stage",
    "reproductive_stage",
    "derivation_source"
  )

queue_terms <- queue |>
  distinct(.data$org_lifestage)
unresolved_terms <- seed |>
  filter(.data$source_match_status != "resolved") |>
  distinct(.data$org_lifestage)
missing_queue <- anti_join(unresolved_terms, queue_terms, by = "org_lifestage")
if (nrow(missing_queue) > 0L) {
  abort(paste("Unresolved lifestage row(s) missing from curation queue:", paste(missing_queue$org_lifestage, collapse = ", ")))
}

force_candidates <- queue |>
  filter(.data$proposed_action == "force_candidate") |>
  transmute(
    org_lifestage = .data$org_lifestage,
    source_provider = "Curated",
    source_ontology = .data$source_ontology,
    source_term_id = .data$source_term_id,
    source_term_label = .data$source_term_label,
    source_term_definition = NA_character_,
    source_release = "curation_queue",
    source_match_method = "curation_queue",
    source_match_status = "resolved",
    candidate_rank = 1L,
    candidate_score = 100,
    candidate_reason = coalesce(.data$decision_notes, "force_candidate"),
    ecotox_release = seed$ecotox_release[[1]],
    harmonized_life_stage = .data$harmonized_life_stage,
    reproductive_stage = as.logical(.data$reproductive_stage),
    derivation_source = "curation_queue"
  )

if (nrow(force_candidates) > 0L) {
  seed <- seed |>
    filter(!.data$org_lifestage %in% force_candidates$org_lifestage) |>
    bind_rows(force_candidates) |>
    arrange(.data$org_lifestage, .data$candidate_rank)
}

change_derivation <- queue |>
  filter(.data$proposed_action == "change_derivation") |>
  select(
    "org_lifestage",
    "harmonized_life_stage",
    "reproductive_stage",
    "decision_notes"
  )
if (nrow(change_derivation) > 0L) {
  seed <- seed |>
    left_join(
      change_derivation,
      by = "org_lifestage",
      suffix = c("", "_queue")
    ) |>
    mutate(
      harmonized_life_stage = coalesce(.data$harmonized_life_stage_queue, .data$harmonized_life_stage),
      reproductive_stage = coalesce(as.logical(.data$reproductive_stage_queue), .data$reproductive_stage),
      derivation_source = if_else(
        !is.na(.data$harmonized_life_stage_queue) | !is.na(.data$reproductive_stage_queue),
        "curation_queue",
        .data$derivation_source
      )
    ) |>
    select(-dplyr::ends_with("_queue"), -"decision_notes")
}

dir.create(dirname(seed_path), recursive = TRUE, showWarnings = FALSE)
write_csv(seed, seed_path, na = "")

review_rows <- seed |>
  filter(
    .data$source_match_status != "resolved" |
      is.na(.data$harmonized_life_stage) |
      is.na(.data$derivation_source)
  ) |>
  arrange(.data$org_lifestage)

message("Wrote ", seed_path, " with ", nrow(seed), " row(s).")
message("Review rows: ", nrow(review_rows), ".")
if (nrow(review_rows) > 0L) {
  message("Unresolved/review terms:")
  message(paste(review_rows$org_lifestage, collapse = "\n"))
}
