# Tests for source-backed ECOTOX lifestage patching
# -------------------------------------------------

make_lifestage_cache_row <- function(
  org_lifestage,
  ecotox_release,
  source_provider = NA_character_,
  source_ontology = NA_character_,
  source_term_id = NA_character_,
  source_term_label = NA_character_,
  source_term_definition = NA_character_,
  source_release = NA_character_,
  source_match_method = "provider_rank",
  source_match_status = "resolved",
  candidate_rank = 1L,
  candidate_score = 100,
  candidate_reason = "exact_normalized_label"
) {
  .eco_lifestage_cache_schema() |>
    dplyr::add_row(
      org_lifestage = org_lifestage,
      source_provider = source_provider,
      source_ontology = source_ontology,
      source_term_id = source_term_id,
      source_term_label = source_term_label,
      source_term_definition = source_term_definition,
      source_release = source_release,
      source_match_method = source_match_method,
      source_match_status = source_match_status,
      candidate_rank = candidate_rank,
      candidate_score = candidate_score,
      candidate_reason = candidate_reason,
      ecotox_release = ecotox_release
    )
}

write_lifestage_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
}

make_provider_row <- function(
  source_provider,
  source_ontology,
  source_term_id,
  source_term_label,
  source_term_definition = NA_character_,
  candidate_aliases = NA_character_,
  source_release = "current",
  source_match_method = "provider_search"
) {
  tibble::tibble(
    source_provider = source_provider,
    source_ontology = source_ontology,
    source_term_id = source_term_id,
    source_term_label = source_term_label,
    source_term_definition = source_term_definition,
    candidate_aliases = candidate_aliases,
    source_release = source_release,
    source_match_method = source_match_method
  )
}

mock_ols_query <- function(rows) {
  force(rows)
  function(term, ontology = NULL, ...) {
    matched <- rows |>
      dplyr::filter(.data$source_provider == "OLS4")
    if (!is.null(ontology)) {
      matched <- matched |>
        dplyr::filter(.data$source_ontology %in% ontology)
    }
    matched
  }
}

mock_nvs_query <- function(rows) {
  force(rows)
  function(term) {
    rows |>
      dplyr::filter(.data$source_provider == "NVS")
  }
}

empty_lifestage_candidates <- function(...) {
  .eco_lifestage_candidate_schema()
}

make_patch_db <- function(
  descriptions = "Adult",
  release = "ecotox_ascii_03_12_2026.zip",
  with_query_tables = FALSE,
  include_release = TRUE
) {
  path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = path, read_only = FALSE)

  meta <- tibble::tibble(
    key = c("build_date", "builder"),
    value = c("2026-04-21", "test")
  )
  if (isTRUE(include_release)) {
    meta <- dplyr::bind_rows(
      meta,
      tibble::tibble(key = "ecotox_release", value = release)
    )
  }

  DBI::dbWriteTable(con, "_metadata", meta, overwrite = TRUE)
  DBI::dbWriteTable(
    con,
    "lifestage_codes",
    tibble::tibble(code = sprintf("L%03d", seq_along(descriptions)), description = descriptions),
    overwrite = TRUE
  )
  DBI::dbWriteTable(con, "sentinel_table", tibble::tibble(id = 1L, value = "keep"), overwrite = TRUE)

  if (isTRUE(with_query_tables)) {
    DBI::dbWriteTable(
      con,
      "tests",
      tibble::tibble(
        reference_number = 1L,
        test_id = 1L,
        test_cas = "50293",
        species_number = 1L,
        exposure_type = "AQUA",
        test_type = "T",
        organism_lifestage = "L001",
        application_freq_mean = NA_real_,
        application_freq_unit = "AF"
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "species",
      tibble::tibble(
        species_number = 1L,
        common_name = "Rainbow Trout",
        latin_name = "Oncorhynchus mykiss",
        family = "Salmonidae",
        genus = "Oncorhynchus",
        species = "mykiss",
        eco_group = "Fish",
        standard_test_species = TRUE,
        invasive_species = FALSE,
        endangered_threatened_species = FALSE
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "chemicals",
      tibble::tibble(
        cas_number = "50293",
        chemical_name = "DDT",
        dtxsid = "DTXSID6020014",
        ecotox_group = "Organochlorine"
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "results",
      tibble::tibble(
        result_id = 1L,
        test_id = 1L,
        endpoint = "LC50",
        effect = "MOR",
        measurement = "MORT",
        obs_duration_mean = "96",
        obs_duration_min = NA_character_,
        obs_duration_max = NA_character_,
        obs_duration_unit = "h",
        conc1_type = "AI",
        conc1_mean_op = "=",
        conc1_unit = "mg/L",
        conc1_mean = "1.0",
        conc1_min = NA_character_,
        conc1_max = NA_character_
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "app_exposure_types",
      tibble::tibble(exposure_group = "A", term = "AQUA", description = "Aquatic"),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "app_exposure_type_groups",
      tibble::tibble(term = "A", description = "Aquatic exposure"),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "app_effect_groups_and_measurements",
      tibble::tibble(
        measurement_term = "MORT",
        measurement_name = "Mortality",
        effect_code = "MOR",
        effect = "Mortality"
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "effect_groups_dictionary",
      tibble::tibble(term = "MOR", effect_group = "MOR", super_effect_description = "Mortality"),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "app_application_frequencies",
      tibble::tibble(term = "AF", description = "Application frequency"),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "unit_conversion",
      tibble::tibble(
        orig = "mg/L",
        cur_unit_result = "mg/L",
        suffix = "",
        cur_unit_type = "conc",
        conversion_factor_unit = 1,
        unit_domain = "water"
      ),
      overwrite = TRUE
    )
    DBI::dbWriteTable(
      con,
      "duration_conversion",
      tibble::tibble(code = "h", conversion_factor_duration = 1),
      overwrite = TRUE
    )
  }

  DBI::dbDisconnect(con, shutdown = TRUE)
  path
}

with_lifestage_files <- function(code, baseline, derivation, cache = NULL) {
  baseline_path <- tempfile(fileext = ".csv")
  derivation_path <- tempfile(fileext = ".csv")
  cache_path <- tempfile(fileext = ".csv")

  write_lifestage_csv(baseline, baseline_path)
  write_lifestage_csv(derivation, derivation_path)
  if (!is.null(cache)) {
    write_lifestage_csv(cache, cache_path)
  }

  testthat::with_mocked_bindings(
    .eco_lifestage_baseline_path = function() baseline_path,
    .eco_lifestage_derivation_path = function() derivation_path,
    .eco_lifestage_cache_path = function(ecotox_release) cache_path,
    .package = "ComptoxR",
    code
  )
}

test_that("patch write-open retries close/connect boundary before succeeding", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  cache <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )
  original_db_connect <- DBI::dbConnect
  attempts <- 0L

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        dbConnect = function(drv, dbdir, read_only = FALSE, ...) {
          if (!isFALSE(read_only)) {
            return(original_db_connect(drv, dbdir = dbdir, read_only = read_only, ...))
          }
          attempts <<- attempts + 1L
          if (attempts < 3L) {
            stop("simulated stale handle")
          }
          original_db_connect(drv, dbdir = dbdir, read_only = read_only, ...)
        },
        .package = "DBI",
        {
          result <- .eco_patch_lifestage(db_path = db_path, refresh = "cache")
          testthat::expect_equal(result$dictionary_rows, 1L)
        }
      )
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = derivation,
    cache = cache
  )

  testthat::expect_equal(attempts, 3L)
})

test_that("patch write-open retry exhaustion reports final DBI error", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  attempts <- 0L

  testthat::with_mocked_bindings(
    dbConnect = function(drv, dbdir, read_only = FALSE, ...) {
      if (!isFALSE(read_only)) {
        return(DBI::dbConnect(drv, dbdir = dbdir, read_only = read_only, ...))
      }
      attempts <<- attempts + 1L
      stop("simulated final DuckDB failure")
    },
    .package = "DBI",
    {
      testthat::expect_error(
        .eco_patch_lifestage(db_path = db_path, refresh = "cache"),
        "Unable to open ECOTOX database read-write for lifestage patch.*simulated final DuckDB failure"
      )
    }
  )

  testthat::expect_equal(attempts, 3L)
})

test_that("cache-hit patch path rewrites from cache only", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  cache <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )

  with_lifestage_files(
    {
      testthat::expect_no_error(
        testthat::with_mocked_bindings(
          .eco_lifestage_query_ols4 = function(...) stop("live lookup should not run"),
          .eco_lifestage_query_nvs = function(...) stop("live lookup should not run"),
          .package = "ComptoxR",
          {
            result <- .eco_patch_lifestage(db_path = db_path, refresh = "cache")
            testthat::expect_equal(result$dictionary_rows, 1L)
            testthat::expect_equal(result$review_rows, 0L)
          }
        )
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      dict <- tibble::as_tibble(DBI::dbReadTable(con, "lifestage_dictionary"))
      testthat::expect_equal(dict$source_term_id, "S1116")
      testthat::expect_equal(dict$derivation_source, "test_derivation")
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = derivation,
    cache = cache
  )
})

test_that("auto patch uses matching committed baseline without live lookup", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  baseline <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = function(...) stop("live lookup should not run"),
        .eco_lifestage_query_nvs = function(...) stop("live lookup should not run"),
        .package = "ComptoxR",
        {
          result <- .eco_patch_lifestage(db_path = db_path, refresh = "auto")
          testthat::expect_equal(result$dictionary_rows, 1L)
          testthat::expect_equal(result$refresh_mode, "auto")
        }
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      dict <- tibble::as_tibble(DBI::dbReadTable(con, "lifestage_dictionary"))
      testthat::expect_equal(dict$org_lifestage, "Adult")
    },
    baseline = baseline,
    derivation = derivation,
    cache = NULL
  )
})

test_that("baseline-seeded patch path writes cache and dictionary", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  baseline <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = function(...) stop("live lookup should not run"),
        .eco_lifestage_query_nvs = function(...) stop("live lookup should not run"),
        .package = "ComptoxR",
        {
          .eco_patch_lifestage(db_path = db_path, refresh = "baseline")
          seeded <- .eco_lifestage_cache_read(release, required = TRUE)
          testthat::expect_equal(seeded$org_lifestage, "Adult")
        }
      )
    },
    baseline = baseline,
    derivation = derivation,
    cache = NULL
  )
})

test_that("baseline patch aborts on release mismatch without live lookup", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  baseline <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = "ecotox_ascii_01_01_2020.zip",
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = function(...) stop("live lookup should not run"),
        .eco_lifestage_query_nvs = function(...) stop("live lookup should not run"),
        .package = "ComptoxR",
        {
          testthat::expect_error(
            .eco_patch_lifestage(db_path = db_path, refresh = "baseline"),
            "Matching committed lifestage baseline is required"
          )
        }
      )
    },
    baseline = baseline,
    derivation = tibble::tibble(
      source_ontology = character(),
      source_term_id = character(),
      harmonized_life_stage = character(),
      reproductive_stage = logical(),
      derivation_source = character()
    ),
    cache = NULL
  )
})

test_that("live-refresh patch path rebuilds cache from mocked providers", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )
  provider_rows <- make_provider_row(
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity"
  )

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = mock_ols_query(provider_rows),
        .eco_lifestage_query_nvs = mock_nvs_query(provider_rows),
        .eco_lifestage_query_devstage_ontology = empty_lifestage_candidates,
        .eco_lifestage_query_po_obo = empty_lifestage_candidates,
        .eco_lifestage_query_bioportal = empty_lifestage_candidates,
        .eco_lifestage_query_wikidata = empty_lifestage_candidates,
        .eco_lifestage_query_agrovoc = empty_lifestage_candidates,
        .eco_lifestage_curated_candidates = empty_lifestage_candidates,
        .package = "ComptoxR",
        {
          .eco_patch_lifestage(db_path = db_path, refresh = "live")
          seeded <- .eco_lifestage_cache_read(release, required = TRUE)
          testthat::expect_equal(seeded$source_term_id, "S1116")
        }
      )
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = derivation,
    cache = NULL
  )
})

test_that("force patch bypasses local seeds and uses live providers", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  cache <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "STALE",
    source_term_label = "stale adult",
    source_release = "old"
  )
  baseline <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "STALE_BASELINE",
    source_term_label = "stale baseline adult",
    source_release = "old"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )
  provider_rows <- make_provider_row(
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity"
  )
  nvs_calls <- 0L

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = mock_ols_query(provider_rows),
        .eco_lifestage_query_nvs = function(...) {
          nvs_calls <<- nvs_calls + 1L
          mock_nvs_query(provider_rows)(...)
        },
        .eco_lifestage_query_devstage_ontology = empty_lifestage_candidates,
        .eco_lifestage_query_po_obo = empty_lifestage_candidates,
        .eco_lifestage_query_bioportal = empty_lifestage_candidates,
        .eco_lifestage_query_wikidata = empty_lifestage_candidates,
        .eco_lifestage_query_agrovoc = empty_lifestage_candidates,
        .eco_lifestage_curated_candidates = empty_lifestage_candidates,
        .package = "ComptoxR",
        {
          result <- .eco_patch_lifestage(db_path = db_path, refresh = "baseline", force = TRUE)
          testthat::expect_equal(result$refresh_mode, "live")
        }
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      dict <- tibble::as_tibble(DBI::dbReadTable(con, "lifestage_dictionary"))
      testthat::expect_equal(dict$source_term_id, "S1116")
    },
    baseline = baseline,
    derivation = derivation,
    cache = cache
  )

  testthat::expect_gt(nvs_calls, 0L)
})

test_that("ambiguous terms are quarantined during patch", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Larva", release = release)
  provider_rows <- dplyr::bind_rows(
    make_provider_row("OLS4", "UBERON", "UBERON:0000069", "larva"),
    make_provider_row("OLS4", "UBERON", "UBERON:0002548", "larva")
  )

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = mock_ols_query(provider_rows),
        .eco_lifestage_query_nvs = mock_nvs_query(provider_rows),
        .eco_lifestage_query_devstage_ontology = empty_lifestage_candidates,
        .eco_lifestage_query_po_obo = empty_lifestage_candidates,
        .eco_lifestage_query_bioportal = empty_lifestage_candidates,
        .eco_lifestage_query_wikidata = empty_lifestage_candidates,
        .eco_lifestage_query_agrovoc = empty_lifestage_candidates,
        .eco_lifestage_curated_candidates = empty_lifestage_candidates,
        .package = "ComptoxR",
        {
          .eco_patch_lifestage(db_path = db_path, refresh = "live")
        }
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      review <- tibble::as_tibble(DBI::dbReadTable(con, "lifestage_review"))
      testthat::expect_true(all(review$review_status == "ambiguous"))
      testthat::expect_true(nrow(review) >= 1L)
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = tibble::tibble(
      source_ontology = character(),
      source_term_id = character(),
      harmonized_life_stage = character(),
      reproductive_stage = logical(),
      derivation_source = character()
    ),
    cache = NULL
  )
})

test_that("unresolved terms are quarantined during patch", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Xylophage", release = release)

  with_lifestage_files(
    {
      testthat::with_mocked_bindings(
        .eco_lifestage_query_ols4 = function(...) tibble::tibble(),
        .eco_lifestage_query_nvs = function(...) tibble::tibble(),
        .eco_lifestage_query_devstage_ontology = empty_lifestage_candidates,
        .eco_lifestage_query_po_obo = empty_lifestage_candidates,
        .eco_lifestage_query_bioportal = empty_lifestage_candidates,
        .eco_lifestage_query_wikidata = empty_lifestage_candidates,
        .eco_lifestage_query_agrovoc = empty_lifestage_candidates,
        .eco_lifestage_curated_candidates = empty_lifestage_candidates,
        .package = "ComptoxR",
        {
          testthat::expect_warning(
            .eco_patch_lifestage(db_path = db_path, refresh = "live"),
            "not found in lifestage audit CSV"
          )
        }
      )

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
      review <- tibble::as_tibble(DBI::dbReadTable(con, "lifestage_review"))
      testthat::expect_equal(review$review_status, "unresolved")
      testthat::expect_equal(review$candidate_reason, "no_provider_candidates")
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = tibble::tibble(
      source_ontology = character(),
      source_term_id = character(),
      harmonized_life_stage = character(),
      reproductive_stage = logical(),
      derivation_source = character()
    ),
    cache = NULL
  )
})

test_that("patch updates only lifestage tables and _metadata", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release)
  cache <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )

  with_lifestage_files(
    {
      con_before <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      before_sentinel <- tibble::as_tibble(DBI::dbReadTable(con_before, "sentinel_table"))
      DBI::dbDisconnect(con_before, shutdown = TRUE)

      con_stale <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)
      stale_meta <- dplyr::bind_rows(
        tibble::as_tibble(DBI::dbReadTable(con_stale, "_metadata")),
        tibble::tibble(
          key = c("lifestage_patch_applied_at", "lifestage_patch_release", "lifestage_patch_method"),
          value = c("stale", "stale", "stale")
        )
      )
      DBI::dbWriteTable(con_stale, "_metadata", stale_meta, overwrite = TRUE)
      DBI::dbDisconnect(con_stale, shutdown = TRUE)

      result <- .eco_patch_lifestage(db_path = db_path, refresh = "cache")

      con_after <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con_after, shutdown = TRUE), add = TRUE)
      after_sentinel <- tibble::as_tibble(DBI::dbReadTable(con_after, "sentinel_table"))
      meta <- tibble::as_tibble(DBI::dbReadTable(con_after, "_metadata"))

      testthat::expect_equal(after_sentinel, before_sentinel)
      testthat::expect_true(all(
        c(
          "lifestage_patch_applied_at",
          "lifestage_patch_release",
          "lifestage_patch_method",
          "lifestage_patch_version"
        ) %in%
          meta$key
      ))
      patch_meta <- meta |>
        dplyr::filter(grepl("^lifestage_patch_", .data$key))
      testthat::expect_equal(nrow(patch_meta), 4L)
      testthat::expect_false(any(duplicated(patch_meta$key)))
      testthat::expect_true(all(nzchar(patch_meta$value)))
      testthat::expect_equal(
        patch_meta$value[patch_meta$key == "lifestage_patch_release"],
        release
      )
      testthat::expect_equal(
        patch_meta$value[patch_meta$key == "lifestage_patch_method"],
        result$refresh_mode
      )
      testthat::expect_equal(
        patch_meta$value[patch_meta$key == "lifestage_patch_version"],
        as.character(utils::packageVersion("ComptoxR"))
      )
      testthat::expect_equal(meta$value[meta$key == "builder"], "test")
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = derivation,
    cache = cache
  )
})

test_that("patch requires valid release metadata", {
  db_path <- make_patch_db("Adult", include_release = FALSE)

  testthat::expect_error(
    .eco_patch_lifestage(db_path = db_path, refresh = "auto"),
    "ecotox_release"
  )
})

test_that("patched DB uses compact default and detailed lifestage output contracts", {
  release <- "ecotox_ascii_03_12_2026.zip"
  db_path <- make_patch_db("Adult", release = release, with_query_tables = TRUE)
  cache <- make_lifestage_cache_row(
    org_lifestage = "Adult",
    ecotox_release = release,
    source_provider = "NVS",
    source_ontology = "S11",
    source_term_id = "S1116",
    source_term_label = "adult",
    source_term_definition = "An animal that has reached sexual maturity",
    source_release = "current"
  )
  derivation <- tibble::tibble(
    source_ontology = "S11",
    source_term_id = "S1116",
    harmonized_life_stage = "Adult",
    reproductive_stage = FALSE,
    derivation_source = "test_derivation"
  )

  with_lifestage_files(
    {
      .eco_patch_lifestage(db_path = db_path, refresh = "cache")

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = TRUE)
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

      withr::with_envvar(c(eco_burl = db_path), {
        result <- eco_results(casrn = "50-29-3", con = con)
        compact_cols <- c(
          "org_lifestage",
          "harmonized_life_stage",
          "reproductive_stage"
        )
        detail_only_cols <- c(
          "organism_lifestage",
          "source_term_label",
          "source_ontology",
          "source_term_id",
          "source_match_status",
          "source_match_method",
          "derivation_source",
          "ontology_id"
        )

        testthat::expect_true(all(
          compact_cols %in% names(result)
        ))
        compact_positions <- match(compact_cols, names(result))
        testthat::expect_equal(
          compact_positions,
          seq.int(compact_positions[[1]], length.out = length(compact_cols))
        )
        testthat::expect_false(any(detail_only_cols %in% names(result)))

        detailed <- eco_results(casrn = "50-29-3", lifestage_details = TRUE, con = con)
        detailed_cols <- c(
          "org_lifestage",
          "harmonized_life_stage",
          "reproductive_stage",
          "organism_lifestage",
          "source_term_label",
          "source_ontology",
          "source_term_id",
          "source_match_status",
          "source_match_method",
          "derivation_source"
        )
        testthat::expect_true(all(detailed_cols %in% names(detailed)))
        detailed_positions <- match(detailed_cols, names(detailed))
        testthat::expect_equal(
          detailed_positions,
          seq.int(detailed_positions[[1]], length.out = length(detailed_cols))
        )
        testthat::expect_equal(detailed$source_match_method, "provider_rank")
        testthat::expect_equal(detailed$source_term_label, "adult")
        testthat::expect_false("ontology_id" %in% names(result))
        testthat::expect_false("ontology_id" %in% names(detailed))
      })
    },
    baseline = .eco_lifestage_cache_schema(),
    derivation = derivation,
    cache = cache
  )
})

test_that("eco_results() aborts clearly for stale lifestage runtime schema", {
  release <- "ecotox_ascii_03_12_2026.zip"
  missing_dictionary <- make_patch_db("Adult", release = release, with_query_tables = TRUE)
  missing_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = missing_dictionary, read_only = TRUE)
  on.exit(DBI::dbDisconnect(missing_con, shutdown = TRUE), add = TRUE)

  withr::with_envvar(c(eco_burl = missing_dictionary), {
    testthat::expect_error(
      eco_results(casrn = "50-29-3", con = missing_con),
      "patch or rebuild"
    )
  })

  stale_dictionary <- make_patch_db("Adult", release = release, with_query_tables = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = stale_dictionary, read_only = FALSE)
  DBI::dbWriteTable(
    con,
    "lifestage_dictionary",
    dplyr::select(.eco_lifestage_dictionary_schema(), -dplyr::all_of("source_match_method")),
    overwrite = TRUE
  )
  DBI::dbDisconnect(con, shutdown = TRUE)
  stale_con <- DBI::dbConnect(duckdb::duckdb(), dbdir = stale_dictionary, read_only = TRUE)
  on.exit(DBI::dbDisconnect(stale_con, shutdown = TRUE), add = TRUE)

  withr::with_envvar(c(eco_burl = stale_dictionary), {
    testthat::expect_error(
      eco_results(casrn = "50-29-3", con = stale_con),
      "source_match_method.*patch or rebuild"
    )
  })
})

test_that(".eco_enrich_metadata() does not reference lifestage_review", {
  enrich_source <- paste(deparse(body(.eco_enrich_metadata)), collapse = "\n")
  testthat::expect_false(grepl("lifestage_review", enrich_source, fixed = TRUE))
})

test_that("NVS failure emits warning and returns empty tibble", {
  nvs_empty_index <- tibble::tibble(
    source_provider = character(),
    source_ontology = character(),
    source_term_id = character(),
    source_term_label = character(),
    source_term_definition = character(),
    source_release = character(),
    source_match_method = character(),
    candidate_aliases = character()
  )
  warned <- FALSE
  result <- withCallingHandlers(
    testthat::with_mocked_bindings(
      .eco_lifestage_nvs_index = function(refresh = FALSE) {
        cli::cli_warn("NVS S11 SPARQL endpoint unreachable. [TEST]")
        nvs_empty_index
      },
      .package = "ComptoxR",
      .eco_lifestage_query_nvs("Adult")
    ),
    warning = function(w) {
      if (grepl("NVS S11 SPARQL", conditionMessage(w))) {
        warned <<- TRUE
      }
      invokeRestart("muffleWarning")
    }
  )
  testthat::expect_true(warned)
  testthat::expect_s3_class(result, "tbl_df")
  testthat::expect_equal(nrow(result), 0L)
})

test_that("section 16 remains identical in both ECOTOX build scripts", {
  project_path <- function(...) {
    file.path(testthat::test_path("..", ".."), ...)
  }

  extract_section <- function(path) {
    contents <- paste(readLines(path, warn = FALSE), collapse = "\n")
    regmatches(
      contents,
      regexpr(
        "(?s)  # 16\\. Lifestage dictionary ---------------------------------------------------.*?  # 17\\. Effects super-group ----------------------------------------------------",
        contents,
        perl = TRUE
      )
    )
  }

  testthat::expect_identical(
    extract_section(project_path("data-raw", "ecotox.R")),
    extract_section(project_path("inst", "ecotox", "ecotox_build.R"))
  )
})
