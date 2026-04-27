# Tests for committed ECOTOX lifestage CSV artifact integrity
# -----------------------------------------------------------

lifestage_extdata_path <- function(filename) {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    filename,
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    paste0(filename, " not found in installed package")
  )
  path
}

lifestage_read_extdata <- function(filename) {
  readr::read_csv(lifestage_extdata_path(filename), show_col_types = FALSE)
}

lifestage_function_body <- function(function_name) {
  source_path <- file.path("R", "eco_lifestage_patch.R")
  if (!file.exists(source_path)) {
    source_path <- file.path("..", "..", "R", "eco_lifestage_patch.R")
  }
  lines <- readLines(source_path, warn = FALSE)
  start <- grep(paste0(function_name, " <- function"), lines, fixed = TRUE)
  testthat::expect_length(start, 1L)

  markers <- grep("^#' @keywords internal", lines)
  next_marker <- markers[markers > start]
  end <- if (length(next_marker) > 0) next_marker[[1]] - 1L else length(lines)
  lines[start:end]
}

lifestage_candidate <- function(source_provider, source_ontology, source_term_id, source_term_label) {
  tibble::tibble(
    source_provider = source_provider,
    source_ontology = source_ontology,
    source_term_id = source_term_id,
    source_term_label = source_term_label,
    source_term_definition = NA_character_,
    candidate_aliases = source_term_label,
    source_release = "test",
    source_match_method = "test"
  )
}

test_that("lifestage_baseline.csv has correct schema columns", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_baseline.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
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
    "ecotox_release"
  )
  testthat::expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("lifestage_derivation.csv has correct schema columns", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_derivation.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c(
    "source_ontology",
    "source_term_id",
    "harmonized_life_stage",
    "reproductive_stage",
    "derivation_source"
  )
  testthat::expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("every resolved baseline key has a derivation partner (cross-check gate)", {
  testthat::skip_if_not_installed("readr")
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(baseline_path) == 0 || nchar(derivation_path) == 0,
    "CSV artifacts not found in installed package"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)

  resolved <- dplyr::filter(baseline, source_match_status == "resolved")
  resolved_keys <- dplyr::distinct(resolved, source_ontology, source_term_id)
  gaps <- dplyr::anti_join(
    resolved_keys,
    derivation,
    by = c("source_ontology", "source_term_id")
  )
  testthat::expect_equal(
    nrow(gaps),
    0L,
    label = paste0(
      nrow(gaps),
      " resolved baseline key(s) have no derivation partner: ",
      paste(
        unique(paste0(gaps$source_ontology, ":", gaps$source_term_id)),
        collapse = ", "
      )
    )
  )
})

test_that("lifestage_baseline.csv has no GO:0040007 contamination", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_baseline.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  go_rows <- df[!is.na(df$source_term_id) & df$source_term_id == "GO:0040007", ]
  testthat::expect_equal(
    nrow(go_rows),
    0L,
    info = "GO:0040007 (growth) is a biological process, not a life stage"
  )
})

test_that("lifestage_baseline.csv has non-zero rows", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_baseline.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  testthat::expect_gt(nrow(df), 0L)
})

test_that("lifestage_derivation.csv has non-zero rows", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_derivation.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  testthat::expect_gt(nrow(df), 0L)
})

test_that("lifestage_audit.csv has correct schema columns", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_audit.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_audit.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c(
    "candidate_source",
    "notes",
    "org_lifestage",
    "resolution_path",
    "triage_bucket"
  )
  testthat::expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("lifestage_aliases.csv has correct schema columns", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_aliases.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_aliases.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c("normalized_query", "org_lifestage")
  testthat::expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("lifestage_aliases.csv has no duplicate org_lifestage keys", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_aliases.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_aliases.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  testthat::expect_equal(
    nrow(df),
    dplyr::n_distinct(df$org_lifestage),
    label = "lifestage_aliases.csv should have no duplicate org_lifestage keys"
  )
})

test_that("lifestage_curated_candidates.csv has correct schema columns", {
  testthat::skip_if_not_installed("readr")
  path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_curated_candidates.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(path) == 0,
    "lifestage_curated_candidates.csv not found in installed package"
  )
  df <- readr::read_csv(path, show_col_types = FALSE)
  expected_cols <- c(
    "candidate_aliases",
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "source_term_label"
  )
  testthat::expect_equal(sort(names(df)), sort(expected_cols))
})

test_that("lifestage_curated_candidates.csv has reviewable keyed rows", {
  testthat::skip_if_not_installed("readr")
  curated_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_curated_candidates.csv",
    package = "ComptoxR"
  )
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(curated_path) == 0 ||
      nchar(baseline_path) == 0 ||
      nchar(derivation_path) == 0,
    "CSV artifacts not found in installed package"
  )
  curated <- readr::read_csv(curated_path, show_col_types = FALSE)
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)

  forced_unresolved <- dplyr::filter(
    baseline,
    source_match_method == "forced_unresolved"
  ) |>
    dplyr::distinct(org_lifestage)
  forced_curated <- dplyr::semi_join(curated, forced_unresolved, by = "org_lifestage")
  curated_key_gaps <- curated |>
    dplyr::distinct(source_ontology, source_term_id) |>
    dplyr::anti_join(derivation, by = c("source_ontology", "source_term_id"))

  testthat::expect_equal(
    nrow(curated),
    dplyr::n_distinct(curated$org_lifestage),
    label = "lifestage_curated_candidates.csv should have no duplicate org_lifestage keys"
  )
  testthat::expect_equal(nrow(forced_curated), 0L)
  testthat::expect_equal(nrow(curated_key_gaps), 0L)
})

test_that("lifestage_forced_unresolved.csv has valid policy data", {
  forced <- lifestage_read_extdata("lifestage_forced_unresolved.csv")
  audit <- lifestage_read_extdata("lifestage_audit.csv")
  expected_cols <- c(
    "org_lifestage",
    "reason",
    "triage_bucket",
    "resolution_path"
  )
  uncovered <- dplyr::anti_join(forced, audit, by = "org_lifestage")

  testthat::expect_equal(sort(names(forced)), sort(expected_cols))
  testthat::expect_equal(
    nrow(forced),
    dplyr::n_distinct(forced$org_lifestage),
    label = "lifestage_forced_unresolved.csv should have no duplicate org_lifestage keys"
  )
  testthat::expect_equal(nrow(uncovered), 0L)
})

test_that("lifestage_domain_patterns.csv has valid policy data", {
  patterns <- lifestage_read_extdata("lifestage_domain_patterns.csv")
  expected_cols <- c("domain", "pattern")
  valid_domains <- c("aquatic", "amphibian", "plant")

  testthat::expect_equal(sort(names(patterns)), sort(expected_cols))
  testthat::expect_equal(setdiff(unique(patterns$domain), valid_domains), character())
  testthat::expect_equal(
    nrow(patterns),
    nrow(dplyr::distinct(patterns, domain, pattern)),
    label = "lifestage_domain_patterns.csv should have no duplicate domain/pattern keys"
  )
})

test_that("lifestage_taxon_route_families.csv has valid policy data", {
  routes <- lifestage_read_extdata("lifestage_taxon_route_families.csv")
  expected_cols <- c("field", "value", "route_family")
  valid_fields <- c("eco_group", "kingdom", "class_name")
  valid_route_families <- c(
    "plant",
    "aquatic",
    "invertebrate",
    "amphibian",
    "vertebrate",
    "fungi",
    "algae",
    "unknown"
  )

  testthat::expect_equal(sort(names(routes)), sort(expected_cols))
  testthat::expect_equal(setdiff(unique(routes$field), valid_fields), character())
  testthat::expect_equal(
    setdiff(unique(routes$route_family), valid_route_families),
    character()
  )
  testthat::expect_equal(
    nrow(routes),
    nrow(dplyr::distinct(routes, field, value)),
    label = "lifestage_taxon_route_families.csv should have no duplicate field/value keys"
  )
})

test_that("lifestage_route_ontology_priorities.csv has valid policy data", {
  priorities <- lifestage_read_extdata("lifestage_route_ontology_priorities.csv")
  expected_cols <- c("route_family", "source_provider", "source_ontology", "ontology_priority")
  valid_route_families <- c(
    "plant",
    "aquatic",
    "invertebrate",
    "amphibian",
    "vertebrate",
    "fungi",
    "algae",
    "unknown",
    "default"
  )

  testthat::expect_equal(sort(names(priorities)), sort(expected_cols))
  testthat::expect_equal(
    setdiff(unique(priorities$route_family), valid_route_families),
    character()
  )
  testthat::expect_true(all(!is.na(priorities$ontology_priority)))
  testthat::expect_true("default" %in% priorities$route_family)
  testthat::expect_equal(
    nrow(priorities),
    nrow(dplyr::distinct(priorities, route_family, source_provider, source_ontology)),
    label = "lifestage_route_ontology_priorities.csv should have no duplicate route/provider/ontology keys"
  )
})

test_that("lifestage_taxon_intersections.csv has auditable ECOTOX route evidence", {
  intersections <- lifestage_read_extdata("lifestage_taxon_intersections.csv")
  baseline <- lifestage_read_extdata("lifestage_baseline.csv")
  expected_cols <- c(
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
  )
  valid_route_families <- c(
    "plant",
    "aquatic",
    "invertebrate",
    "amphibian",
    "vertebrate",
    "fungi",
    "algae",
    "unknown"
  )

  testthat::expect_equal(sort(names(intersections)), sort(expected_cols))
  testthat::expect_equal(
    nrow(intersections),
    nrow(dplyr::distinct(intersections, org_lifestage, eco_group, kingdom, class_name)),
    label = "lifestage_taxon_intersections.csv should have unique lifestage/taxon intersections"
  )
  testthat::expect_equal(
    setdiff(unique(intersections$route_family), valid_route_families),
    character()
  )
  testthat::expect_equal(
    setdiff(baseline$org_lifestage, intersections$org_lifestage),
    character()
  )

  dominant_counts <- intersections |>
    dplyr::filter(.data$dominant_route) |>
    dplyr::count(.data$org_lifestage)
  testthat::expect_equal(nrow(dominant_counts), nrow(baseline))
  testthat::expect_true(all(dominant_counts$n == 1L))
})

test_that("lifestage_curated_exceptions.csv documents retained curated rows", {
  exceptions <- lifestage_read_extdata("lifestage_curated_exceptions.csv")
  curated <- lifestage_read_extdata("lifestage_curated_candidates.csv")
  expected_cols <- c(
    "org_lifestage",
    "source_ontology",
    "source_term_id",
    "source_term_label",
    "exception_reason",
    "replacement_status",
    "replacement_source_ontology",
    "replacement_source_term_id",
    "replacement_source_term_label",
    "replacement_candidate_score",
    "harmonized_life_stage",
    "reproductive_stage",
    "replacement_harmonized_life_stage",
    "replacement_reproductive_stage",
    "notes"
  )
  valid_reasons <- c("semantic_change", "ambiguous_route", "no_source_backed_candidate")

  testthat::expect_equal(sort(names(exceptions)), sort(expected_cols))
  testthat::expect_equal(setdiff(unique(exceptions$exception_reason), valid_reasons), character())
  testthat::expect_equal(
    nrow(dplyr::anti_join(curated, exceptions, by = c("org_lifestage", "source_ontology", "source_term_id"))),
    0L
  )

  sapling <- dplyr::filter(exceptions, org_lifestage == "Sapling")
  testthat::expect_equal(sapling$exception_reason, "semantic_change")
  testthat::expect_equal(sapling$source_ontology, "S11")
  testthat::expect_equal(sapling$source_term_id, "S1127")
  testthat::expect_equal(sapling$replacement_source_ontology, "PO")
  testthat::expect_equal(sapling$replacement_source_term_id, "PO:0007134")
  testthat::expect_equal(sapling$harmonized_life_stage, "Juvenile")
  testthat::expect_false(sapling$reproductive_stage)
  testthat::expect_equal(sapling$replacement_harmonized_life_stage, "Adult")
})

test_that("every unresolved baseline term has an audit classification", {
  testthat::skip_if_not_installed("readr")
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  audit_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_audit.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(baseline_path) == 0 || nchar(audit_path) == 0,
    "CSV artifacts not found in installed package"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  audit <- readr::read_csv(audit_path, show_col_types = FALSE)
  unresolved <- dplyr::filter(baseline, source_match_status == "unresolved")
  gaps <- dplyr::anti_join(unresolved, audit, by = "org_lifestage")
  testthat::expect_equal(
    nrow(gaps),
    0L,
    label = paste0(
      nrow(gaps),
      " unresolved term(s) have no audit classification: ",
      paste(unique(gaps$org_lifestage), collapse = ", ")
    )
  )
})

test_that("every unresolved baseline term has an explicit unresolved derivation row", {
  testthat::skip_if_not_installed("readr")
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(baseline_path) == 0 || nchar(derivation_path) == 0,
    "CSV artifacts not found in installed package"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)
  unresolved <- dplyr::filter(baseline, source_match_status == "unresolved") |>
    dplyr::distinct(org_lifestage)
  explicit_unresolved <- dplyr::filter(
    derivation,
    source_ontology == "ECOTOX_UNRESOLVED"
  ) |>
    dplyr::transmute(org_lifestage = source_term_id)
  gaps <- dplyr::anti_join(unresolved, explicit_unresolved, by = "org_lifestage")
  testthat::expect_equal(
    nrow(gaps),
    0L,
    label = paste0(
      nrow(gaps),
      " unresolved term(s) have no ECOTOX_UNRESOLVED derivation row: ",
      paste(unique(gaps$org_lifestage), collapse = ", ")
    )
  )
})

test_that("resolved lifestage metadata is not left in review-only states", {
  testthat::skip_if_not_installed("readr")
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  audit_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_audit.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(baseline_path) == 0 ||
      nchar(derivation_path) == 0 ||
      nchar(audit_path) == 0,
    "CSV artifacts not found in installed package"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)
  audit <- readr::read_csv(audit_path, show_col_types = FALSE)

  resolved_terms <- dplyr::filter(baseline, source_match_status == "resolved") |>
    dplyr::distinct(org_lifestage)
  resolved_keys <- dplyr::filter(baseline, source_match_status == "resolved") |>
    dplyr::distinct(source_ontology, source_term_id)
  pending_audit <- dplyr::semi_join(audit, resolved_terms, by = "org_lifestage") |>
    dplyr::filter(resolution_path == "pending_probe")
  auto_unmatched <- dplyr::filter(
    derivation,
    derivation_source == "auto_unmatched_needs_review"
  ) |>
    dplyr::semi_join(resolved_keys, by = c("source_ontology", "source_term_id"))

  testthat::expect_equal(nrow(pending_audit), 0L)
  testthat::expect_equal(nrow(auto_unmatched), 0L)
})

test_that("high-risk lifestage policy decisions are locked", {
  testthat::skip_if_not_installed("readr")
  baseline_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_baseline.csv",
    package = "ComptoxR"
  )
  derivation_path <- system.file(
    "extdata",
    "ecotox",
    "lifestage_derivation.csv",
    package = "ComptoxR"
  )
  testthat::skip_if(
    nchar(baseline_path) == 0 || nchar(derivation_path) == 0,
    "CSV artifacts not found in installed package"
  )
  baseline <- readr::read_csv(baseline_path, show_col_types = FALSE)
  derivation <- readr::read_csv(derivation_path, show_col_types = FALSE)

  forced_terms <- c(
    "Gamete",
    "Gestation",
    "Pollen, pollen grain",
    "Rooted cuttings",
    "Rootstock",
    "Shoot"
  )
  forced_rows <- baseline |>
    dplyr::filter(org_lifestage %in% forced_terms)
  sapling <- baseline |>
    dplyr::filter(org_lifestage == "Sapling")
  reproductive_flags <- derivation |>
    dplyr::filter(
      paste(source_ontology, source_term_id, sep = ":") %in%
        c(
          "UBERON:UBERON:0000113",
          "PO:PO:0025528",
          "PO:PO:0025279",
          "PO:PO:0025280"
        )
    ) |>
    dplyr::transmute(
      key = paste(source_ontology, source_term_id, sep = ":"),
      reproductive_stage
    )

  testthat::expect_equal(
    sort(forced_rows$source_match_status),
    rep("unresolved", length(forced_terms))
  )
  testthat::expect_equal(unique(forced_rows$source_match_method), "forced_unresolved")
  testthat::expect_equal(sapling$source_ontology, "S11")
  testthat::expect_equal(sapling$source_term_id, "S1127")
  sapling_derivation <- derivation |>
    dplyr::filter(source_ontology == "S11", source_term_id == "S1127")
  po_vegetative <- derivation |>
    dplyr::filter(source_ontology == "PO", source_term_id == "PO:0007134")
  testthat::expect_equal(sapling_derivation$harmonized_life_stage, "Juvenile")
  testthat::expect_false(sapling_derivation$reproductive_stage)
  testthat::expect_equal(po_vegetative$harmonized_life_stage, "Adult")
  testthat::expect_false(reproductive_flags$reproductive_stage[reproductive_flags$key == "UBERON:UBERON:0000113"])
  testthat::expect_false(reproductive_flags$reproductive_stage[reproductive_flags$key == "PO:PO:0025528"])
  testthat::expect_true(reproductive_flags$reproductive_stage[reproductive_flags$key == "PO:PO:0025279"])
  testthat::expect_true(reproductive_flags$reproductive_stage[reproductive_flags$key == "PO:PO:0025280"])
})

test_that("curated minimization promotes only unchanged harmonized semantics", {
  report_path <- file.path("dev", "lifestage", "minimized_curated_candidates_report.csv")
  if (!file.exists(report_path)) {
    report_path <- file.path("..", "..", "dev", "lifestage", "minimized_curated_candidates_report.csv")
  }
  testthat::skip_if_not(
    file.exists(report_path),
    "minimized_curated_candidates_report.csv not available in installed package"
  )

  report <- readr::read_csv(report_path, show_col_types = FALSE)
  promoted <- report |>
    dplyr::filter(.data$action == "promoted_non_curated")
  semantic_changes <- promoted |>
    dplyr::filter(
      .data$current_stage != .data$rerun_stage |
        .data$current_rep != .data$rerun_rep
    )

  testthat::expect_gt(nrow(promoted), 0L)
  testthat::expect_equal(nrow(semantic_changes), 0L)
})

test_that("forced-unresolved behavior is preserved from CSV policy", {
  testthat::skip_if_not(exists(".eco_lifestage_forced_unresolved_terms"))
  testthat::skip_if_not(exists(".eco_lifestage_resolve_term"))

  terms <- .eco_lifestage_forced_unresolved_terms()
  resolved <- .eco_lifestage_resolve_term("Gamete", "test_release")

  testthat::expect_true(all(c("Gamete", "Rootstock", "Unspecified") %in% terms))
  testthat::expect_equal(resolved$source_match_status, "unresolved")
  testthat::expect_equal(resolved$source_match_method, "forced_unresolved")
})

test_that("domain pattern behavior is preserved from CSV policy", {
  testthat::skip_if_not(exists(".eco_lifestage_detect_domains"))

  testthat::expect_equal(.eco_lifestage_detect_domains("Fry"), "aquatic")
  testthat::expect_equal(.eco_lifestage_detect_domains("Tadpole"), "amphibian")
  testthat::expect_equal(.eco_lifestage_detect_domains("Sapling"), "plant")
})

test_that("taxon route family behavior is preserved from CSV policy", {
  testthat::skip_if_not(exists(".eco_lifestage_taxon_route_family"))

  testthat::expect_equal(
    .eco_lifestage_taxon_route_family(eco_group = "Fish", kingdom = "PLANTAE"),
    "aquatic"
  )
  testthat::expect_equal(
    .eco_lifestage_taxon_route_family(eco_group = NA, kingdom = "PLANTAE"),
    "plant"
  )
  testthat::expect_equal(
    .eco_lifestage_taxon_route_family(eco_group = NA, class_name = "Amphibia"),
    "amphibian"
  )
})

test_that("route family ontology priorities resolve representative candidates deterministically", {
  testthat::skip_if_not(exists(".eco_lifestage_rank_candidates"))

  cases <- list(
    plant = list(
      term = "Seedling",
      winner = c("PO", "PO:test"),
      candidates = dplyr::bind_rows(
        lifestage_candidate("PlantOntologyOBO", "PO", "PO:test", "Seedling"),
        lifestage_candidate("NVS", "S11", "S11:test", "Seedling")
      )
    ),
    aquatic = list(
      term = "Fingerling",
      winner = c("S11", "S11:test"),
      candidates = dplyr::bind_rows(
        lifestage_candidate("NVS", "S11", "S11:test", "Fingerling"),
        lifestage_candidate("OLS4", "UBERON", "UBERON:test", "Fingerling")
      )
    ),
    invertebrate = list(
      term = "Adult",
      winner = c("S11", "S11:test"),
      candidates = dplyr::bind_rows(
        lifestage_candidate("NVS", "S11", "S11:test", "Adult"),
        lifestage_candidate("OLS4", "UBERON", "UBERON:test", "Adult")
      )
    ),
    amphibian = list(
      term = "Tadpole",
      winner = c("XAO", "XAO:test"),
      candidates = dplyr::bind_rows(
        lifestage_candidate("OLS4", "XAO", "XAO:test", "Tadpole"),
        lifestage_candidate("OLS4", "UBERON", "UBERON:test", "Tadpole")
      )
    ),
    vertebrate = list(
      term = "Gestation",
      winner = c("UBERON", "UBERON:test"),
      candidates = dplyr::bind_rows(
        lifestage_candidate("OLS4", "UBERON", "UBERON:test", "Gestation"),
        lifestage_candidate("NVS", "S11", "S11:test", "Gestation")
      )
    )
  )

  for (case in cases) {
    ranked <- .eco_lifestage_rank_candidates(case$term, case$candidates)
    testthat::expect_equal(ranked$source_match_status[[1]], "resolved")
    testthat::expect_equal(ranked$source_ontology[[1]], case$winner[[1]])
    testthat::expect_equal(ranked$source_term_id[[1]], case$winner[[2]])
  }
})

test_that("lifestage policy literals are not reintroduced in target helpers", {
  forced_body <- lifestage_function_body(".eco_lifestage_forced_unresolved_terms")
  domain_body <- lifestage_function_body(".eco_lifestage_detect_domains")
  route_body <- lifestage_function_body(".eco_lifestage_taxon_route_family")

  forced_literals <- c("Gamete", "Rootstock", "Stationary growth phase")
  domain_literals <- c("alevin", "tadpole", "sapling")
  route_literals <- c("Flowers/Trees/Shrubs/Ferns", "Fish", "PLANTAE", "AMPHIBIA")

  testthat::expect_false(any(vapply(
    forced_literals,
    function(literal) any(grepl(literal, forced_body, fixed = TRUE)),
    logical(1)
  )))
  testthat::expect_false(any(vapply(
    domain_literals,
    function(literal) any(grepl(literal, domain_body, fixed = TRUE)),
    logical(1)
  )))
  testthat::expect_false(any(vapply(
    route_literals,
    function(literal) any(grepl(literal, route_body, fixed = TRUE)),
    logical(1)
  )))
})
