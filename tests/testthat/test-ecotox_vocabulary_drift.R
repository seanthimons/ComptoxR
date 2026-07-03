drift_lifestage_seed_row <- function(org_lifestage = "Adult", ecotox_release = "ecotox_ascii_03_12_2026.zip") {
  tibble::tibble(
    org_lifestage = org_lifestage,
    source_provider = "test",
    source_ontology = "TEST",
    source_term_id = "TEST:1",
    source_term_label = org_lifestage,
    source_term_definition = NA_character_,
    source_release = "test",
    source_match_method = "test",
    source_match_status = "resolved",
    candidate_rank = 1L,
    candidate_score = 100,
    candidate_reason = "exact",
    ecotox_release = ecotox_release,
    harmonized_life_stage = "Adult",
    reproductive_stage = TRUE,
    derivation_source = "test"
  )
}

test_that("missing lifestage terms raise typed ECOTOX vocabulary drift", {
  release <- "ecotox_ascii_06_11_2026.zip"
  seed_release <- "ecotox_ascii_03_12_2026.zip"
  seed <- drift_lifestage_seed_row(ecotox_release = release)
  attr(seed, "seed_release") <- seed_release

  testthat::local_mocked_bindings(
    .eco_lifestage_load_seed_cache = function(...) {
      list(seed_cache = seed, refresh_mode = "auto", cache_source = "patch seed")
    },
    .package = "ComptoxR"
  )

  err <- tryCatch(
    .eco_lifestage_materialize_tables(
      org_lifestages = c("Adult", "Neonate"),
      ecotox_release = release,
      write_cache = FALSE
    ),
    error = function(e) e
  )

  expect_s3_class(err, "comptoxr_ecotox_lifestage_drift")
  expect_equal(err$ecotox_release, release)
  expect_equal(err$seed_release, seed_release)
  expect_equal(err$missing_terms, "Neonate")
})

test_that("ECOTOX vocabulary drift report records release, seed, and missing terms", {
  path <- file.path(withr::local_tempdir(), "ecotox-vocabulary-drift.json")
  cnd <- rlang::catch_cnd(
    .eco_lifestage_abort_vocabulary_drift(
      ecotox_release = "ecotox_ascii_06_11_2026.zip",
      seed_release = "ecotox_ascii_03_12_2026.zip",
      missing_terms = c("Neonate", "Smolt"),
      cache_source = "patch seed"
    )
  )

  .eco_lifestage_write_drift_report(cnd, path = path)
  report <- jsonlite::read_json(path, simplifyVector = TRUE)

  expect_equal(report$ecotox_release, "ecotox_ascii_06_11_2026.zip")
  expect_equal(report$seed_release, "ecotox_ascii_03_12_2026.zip")
  expect_equal(report$missing_terms, c("Neonate", "Smolt"))
})

test_that("non-drift ECOTOX failures do not create drift reports", {
  path <- file.path(withr::local_tempdir(), "ecotox-vocabulary-drift.json")

  tryCatch(
    cli::cli_abort("ordinary build failure"),
    comptoxr_ecotox_lifestage_drift = function(cnd) {
      .eco_lifestage_write_drift_report(cnd, path = path)
    },
    error = function(e) NULL
  )

  expect_false(file.exists(path))
})
