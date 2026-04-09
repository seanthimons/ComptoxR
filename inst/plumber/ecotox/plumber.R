# ECOTOX Plumber API — thin wrappers around ComptoxR eco_*() functions
# -------------------------------------------------------------------
# Launch:
#   plumber::pr_run(plumber::pr("inst/plumber/ecotox/plumber.R"), port = 5555)
#
# Configure DB path before launching (optional — defaults to eco_server(1)):
#   options(ComptoxR.ecotox_path = "/path/to/ecotox.duckdb")

library(ComptoxR)

# Point at the local DuckDB. Users configure this path before launching.
# Default: eco_server(1) uses R_user_dir resolution.
eco_server(getOption("ComptoxR.ecotox_path", default = 1))

#* @apiTitle ECOTOX API
#* @apiDescription Thin wrapper around ComptoxR eco_*() functions

#* Health check
#* @get /health-check
function() {
  eco_health()
}

#* Chemical inventory
#* @get /inventory
function() {
  eco_inventory()
}

#* List all tables
#* @get /all_tbls
function() {
  eco_tables()
}

#* Column names for a table
#* @param table_name:str Table name
#* @get /fields/<table_name>
function(table_name) {
  eco_fields(table_name)
}

#* Raw table contents
#* @param table_name:str Table name
#* @get /tables/<table_name>
function(table_name) {
  con <- ComptoxR:::.eco_get_con()
  dplyr::tbl(con, table_name) |> dplyr::collect()
}

#* Species search
#* @param query Search pattern (SQL ILIKE wildcards, e.g. "Rainbow%")
#* @param field One of common_name, latin_name, eco_group
#* @get /species
function(query, field = "common_name") {
  eco_species(query, field)
}

#* Query ecotoxicology results
#* @param casrn A list of CASRNs to query
#* @param common_name A list of common species names to query
#* @param latin_name A list of latin species names to query
#* @param endpoint A list of endpoints to query
#* @param eco_group A list of ecotox groups to query
#* @param invasive boolean to filter by invasive species
#* @param standard boolean to filter by standard species
#* @param threatened boolean to filter by threatened species
#* @param test_cols Additional test table columns
#* @param results_cols Additional results table columns
#* @post /results
function(casrn = NULL, common_name = NULL, latin_name = NULL,
         endpoint = NULL, eco_group = NULL,
         invasive = FALSE, standard = FALSE, threatened = FALSE,
         test_cols = NULL, results_cols = NULL) {
  eco_results(
    casrn = casrn, common_name = common_name, latin_name = latin_name,
    endpoint = endpoint, eco_group = eco_group,
    invasive = invasive, standard = standard, threatened = threatened,
    test_cols = test_cols, results_cols = results_cols
  )
}
