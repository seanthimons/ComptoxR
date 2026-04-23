# Tests for committed ECOTOX lifestage CSV artifact integrity
# -----------------------------------------------------------

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
