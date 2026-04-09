# ToxValDB Plumber API — thin wrappers around ComptoxR tox_*() functions
# -------------------------------------------------------------------
# Launch:
#   plumber::pr_run(plumber::pr("inst/plumber/toxval/plumber.R"), port = 5556)
#
# Configure DB path before launching (optional — defaults to tox_server(1)):
#   options(ComptoxR.toxval_path = "/path/to/toxval.duckdb")

library(ComptoxR)

# Point at the local DuckDB. Users configure this path before launching.
# Default: tox_server(1) uses R_user_dir resolution.
tox_server(getOption("ComptoxR.toxval_path", default = 1))

# Note: Uses internal ComptoxR function. Requires matching ComptoxR version.
.get_con <- function() ComptoxR:::.tox_get_con()

#* @apiTitle ToxValDB API
#* @apiDescription Thin wrapper around ComptoxR tox_*() functions

#* Health check
#* @get /health-check
function() {
  tox_health()
}

#* List all tables
#* @get /tables
function() {
  tox_tables()
}

#* Column names for a table
#* @param table_name:str Table name
#* @get /fields/<table_name>
function(table_name) {
  tox_fields(table_name)
}

#* List data sources
#* @get /sources
function() {
  tox_sources()
}

#* Search by name or effect
#* @param pattern Search pattern (auto-wrapped with % wildcards)
#* @param field One of name, toxicological_effect
#* @param limit Maximum rows (default 100)
#* @get /search
function(pattern, field = "name", limit = 100L) {
  tox_search(pattern, field = field, limit = as.integer(limit))
}

#* Query ToxValDB results
#* @param dtxsid A list of DTXSIDs
#* @param casrn A list of CASRNs
#* @param source A list of source names
#* @param toxval_type A list of toxval types
#* @param species A list of species names
#* @param human_eco A list of human/eco classifications
#* @param qc_status QC filter mode
#* @param cols Column selection mode
#* @post /results
function(dtxsid = NULL, casrn = NULL, source = NULL,
         toxval_type = NULL, species = NULL, human_eco = NULL,
         qc_status = "pass_or_not_determined", cols = "default") {
  tox_results(
    dtxsid = dtxsid, casrn = casrn, source = source,
    toxval_type = toxval_type, species = species,
    human_eco = human_eco, qc_status = qc_status, cols = cols
  )
}
