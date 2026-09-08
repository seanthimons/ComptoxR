make_source_ecotox_db <- function(
  descriptions = "Adult",
  release = "ecotox_ascii_03_12_2026.zip",
  with_query_tables = TRUE,
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
