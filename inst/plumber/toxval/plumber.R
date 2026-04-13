# ToxValDB Plumber API — thin wrappers around ComptoxR toxval_*() functions
# -------------------------------------------------------------------
# Launch:
#   plumber::pr_run(plumber::pr("inst/plumber/toxval/plumber.R"), port = 5556)
#
# Configure DB path before launching (optional — defaults to toxval_server(1)):
#   options(ComptoxR.toxval_path = "/path/to/toxval.duckdb")

library(ComptoxR)

# Point at the local DuckDB. Users configure this path before launching.
# Default: toxval_server(1) uses R_user_dir resolution.
toxval_server(getOption("ComptoxR.toxval_path", default = 1))

# Note: Uses internal ComptoxR function. Requires matching ComptoxR version.
.get_con <- function() ComptoxR:::.tox_get_con()

#* @apiTitle ToxValDB API
#* @apiDescription Thin wrapper around ComptoxR toxval_*() functions

#* Restrict to localhost
#* @filter localhost_only
function(req, res) {
  ip <- req$REMOTE_ADDR %||% ""
  if (!grepl("^(127\\.0\\.0\\.1|::1|localhost)$", ip)) {
    res$status <- 403
    return(list(error = "Access restricted to localhost"))
  }
  plumber::forward()
}

#* Health check
#* @get /health-check
function() {
  toxval_health()
}

#* List all tables
#* @get /tables
function() {
  toxval_tables()
}

#* Column names for a table
#* @param table_name:str Table name
#* @get /fields/<table_name>
function(table_name) {
  toxval_fields(table_name)
}

#* List data sources
#* @get /sources
function() {
  toxval_sources()
}

#* Search by DTXSID
#* @param dtxsid A list of DTXSIDs
#* @param limit Maximum rows (default 1000)
#* @post /search
function(dtxsid, limit = 1000L, res) {
  limit_int <- suppressWarnings(as.integer(limit))
  if (is.null(dtxsid) || length(dtxsid) == 0) {
    res$status <- 400
    return(list(error = "dtxsid is required"))
  }
  if (is.na(limit_int) || limit_int < 1L) limit_int <- 1000L
  if (limit_int > 10000L) {
    res$status <- 400
    return(list(error = "limit exceeds maximum of 10000"))
  }
  tryCatch(
    toxval_search(dtxsid, limit = limit_int),
    error = function(e) { res$status <- 500; list(error = conditionMessage(e)) }
  )
}

#* Query ToxValDB results
#* @param dtxsid A list of DTXSIDs
#* @param casrn A list of CASRNs
#* @param source A list of source names
#* @param toxval_type A list of toxval types
#* @param species A list of species names
#* @param qc_status QC filter mode
#* @param cols Column selection mode
#* @post /results
function(dtxsid = NULL, casrn = NULL, source = NULL,
         toxval_type = NULL, species = NULL,
         qc_status = "pass_or_not_determined", cols = "default", res) {
  tryCatch(
    toxval_results(
      dtxsid = dtxsid, casrn = casrn, source = source,
      toxval_type = toxval_type, species = species,
      qc_status = qc_status, cols = cols
    ),
    error = function(e) { res$status <- 500; list(error = conditionMessage(e)) }
  )
}
