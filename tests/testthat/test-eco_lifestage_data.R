# Tests for the installed ECOTOX lifestage patch seed and curation queue

lifestage_seed_path <- function() {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_patch_seed.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_patch_seed.csv not found in installed package"
  )
  path
}

lifestage_read_seed <- function() {
  readr::read_csv(lifestage_seed_path(), show_col_types = FALSE)
}

lifestage_project_file <- function(...) {
  path <- file.path(...)
  if (!file.exists(path)) {
    path <- file.path("..", "..", ...)
  }
  path
}

test_that("only the lifestage patch seed is installed as ECOTOX lifestage data", {
  extdata_dir <- dirname(lifestage_seed_path())
  lifestage_files <- list.files(extdata_dir, pattern = "^lifestage_.*[.]csv$")

  testthat::expect_equal(lifestage_files, "lifestage_patch_seed.csv")
})

test_that("lifestage_patch_seed.csv has the installed seed schema", {
  seed <- lifestage_read_seed()
  expected_cols <- c(
    "org_lifestage",
    "source_provider",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "source_term_definition",
    "source_release",
    "source_match_method",
    "source_match_status",
    "candidate_rank",
    "candidate_score",
    "candidate_reason",
    "ecotox_release",
    "harmonized_life_stage",
    "reproductive_stage",
    "derivation_source"
  )

  testthat::expect_equal(names(seed), expected_cols)
  testthat::expect_gt(nrow(seed), 0L)
})

test_that("lifestage_patch_seed.csv is release-scoped and covers every release lifestage", {
  seed <- lifestage_read_seed()
  source_baseline_path <- lifestage_project_file(
    "dev",
    "lifestage",
    "source",
    "lifestage_baseline.csv"
  )
  testthat::skip_if_not(file.exists(source_baseline_path), "maintainer source baseline not available")
  source_baseline <- readr::read_csv(source_baseline_path, show_col_types = FALSE)

  testthat::expect_equal(length(unique(seed$ecotox_release)), 1L)
  testthat::expect_equal(
    sort(unique(seed$org_lifestage)),
    sort(unique(source_baseline$org_lifestage))
  )
  testthat::expect_equal(nrow(seed), dplyr::n_distinct(seed$org_lifestage))
})

test_that("resolved seed rows have complete derivation fields", {
  seed <- lifestage_read_seed()
  resolved <- dplyr::filter(seed, .data$source_match_status == "resolved")
  gaps <- dplyr::filter(
    resolved,
    is.na(.data$source_ontology) |
      is.na(.data$source_term_id) |
      is.na(.data$source_term_label) |
      is.na(.data$harmonized_life_stage) |
      is.na(.data$reproductive_stage) |
      is.na(.data$derivation_source)
  )

  testthat::expect_gt(nrow(resolved), 0L)
  testthat::expect_equal(nrow(gaps), 0L)
})

test_that("review seed rows have explicit status and reason", {
  seed <- lifestage_read_seed()
  review <- dplyr::filter(seed, .data$source_match_status != "resolved")
  gaps <- dplyr::filter(
    review,
    is.na(.data$source_match_status) |
      is.na(.data$candidate_reason) |
      !nzchar(.data$candidate_reason)
  )

  testthat::expect_equal(nrow(review), 38L)
  testthat::expect_equal(nrow(gaps), 0L)
})

test_that("lifestage curation queue covers unresolved and disputed rows", {
  queue_path <- lifestage_project_file(
    "dev",
    "lifestage",
    "curation",
    "lifestage_curation_queue.csv"
  )
  testthat::skip_if_not(file.exists(queue_path), "lifestage curation queue not available")
  seed <- lifestage_read_seed()
  queue <- readr::read_csv(queue_path, show_col_types = FALSE)
  required_cols <- c(
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
  unresolved_terms <- seed |>
    dplyr::filter(.data$source_match_status != "resolved") |>
    dplyr::distinct(.data$org_lifestage)
  queue_unresolved <- queue |>
    dplyr::semi_join(unresolved_terms, by = "org_lifestage") |>
    dplyr::distinct(.data$org_lifestage)

  testthat::expect_equal(names(queue), required_cols)
  testthat::expect_equal(setdiff(unique(queue$proposed_action), allowed_actions), character())
  testthat::expect_equal(nrow(unresolved_terms), 38L)
  testthat::expect_equal(
    sort(queue_unresolved$org_lifestage),
    sort(unresolved_terms$org_lifestage)
  )
})

test_that("lifestage curation queue decisions are internally valid", {
  queue_path <- lifestage_project_file(
    "dev",
    "lifestage",
    "curation",
    "lifestage_curation_queue.csv"
  )
  testthat::skip_if_not(file.exists(queue_path), "lifestage curation queue not available")
  queue <- readr::read_csv(queue_path, show_col_types = FALSE)

  duplicate_decisions <- queue |>
    dplyr::count(.data$org_lifestage) |>
    dplyr::filter(.data$n > 1L)
  force_candidate_gaps <- queue |>
    dplyr::filter(.data$proposed_action == "force_candidate") |>
    dplyr::filter(
      is.na(.data$source_ontology) |
        is.na(.data$source_term_id) |
        is.na(.data$source_term_label) |
        is.na(.data$harmonized_life_stage) |
        is.na(.data$reproductive_stage)
    )
  unresolved_note_gaps <- queue |>
    dplyr::filter(.data$proposed_action %in% c("accept_unresolved", "force_unresolved")) |>
    dplyr::filter(
      is.na(.data$reviewer) |
        is.na(.data$decision_notes) |
        !nzchar(.data$decision_notes)
    )

  testthat::expect_equal(nrow(duplicate_decisions), 0L)
  testthat::expect_equal(nrow(force_candidate_gaps), 0L)
  testthat::expect_equal(nrow(unresolved_note_gaps), 0L)
})
