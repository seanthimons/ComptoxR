# Internal package environment for session-level caching
.ComptoxREnv <- new.env(parent = emptyenv())

.run_debug_enabled <- function() {
  isTRUE(.ComptoxREnv$run_debug)
}

.run_verbose_enabled <- function() {
  isTRUE(getOption("ComptoxR.run_verbose", FALSE))
}

#' First time setup for functions

#'
#' Tests to see if APIs are up and tokens are present.
#'
#' @details Uses the same service checks as [ComptoxR_package_sitrep()],
#' with a compact summary and names of failed or unverified checks. Also reports
#' local database installation and API key presence, without opening databases
#' or printing credentials. It does not create a diagnostic log.
#'
#' @return Invisibly returns `NULL` after displaying the setup summary.
#' @export

run_setup <- function() {
  cli::cli_rule(left = "Services")
  results <- .sitrep_checks()
  for (result in results) {
    status <- switch(
      result$status,
      OK = cli::col_green(result$status),
      ERROR = cli::col_red(result$status),
      cli::col_yellow(result$status)
    )
    up <- sum(result$endpoints$status == "OK")
    total <- nrow(result$endpoints)
    cli::cli_text("{.strong {result$name}}: {status} ({up}/{total} checks OK, {round(result$latency * 1000)}ms)")
    if (!is.null(result$endpoint_list) && result$endpoint_list$status != "OK") {
      cli::cli_text("  Endpoint list: {result$endpoint_list$message}; using {result$source} probes")
    }
    failed <- result$endpoints[result$endpoints$status != "OK", ]
    if (nrow(failed)) {
      details <- paste0(failed$name, " (", failed$message, ")", collapse = "; ")
      cli::cli_text("  Check failures or unverified: {details}")
    }
  }

  cli::cli_rule(left = "Local databases")
  databases <- list(DSSTox = dss_path(), ECOTOX = eco_path(), ToxValDB = toxval_path())
  installers <- c(DSSTox = "dss_install()", ECOTOX = "eco_install()", ToxValDB = "toxval_install()")
  for (name in names(databases)) {
    path <- databases[[name]]
    if (file.exists(path)) {
      size <- round(file.size(path) / 1024^2)
      cli::cli_text("{name}: installed ({size} MB)")
    } else {
      cli::cli_text("{name}: not installed; run {.code {installers[[name]]}}")
    }
  }

  key_set <- nzchar(Sys.getenv("ctx_api_key"))
  cli::cli_text("CompTox API key: {if (key_set) 'SET' else 'NOT SET'}")
  cli::cli_text("Full diagnostics: {.code ComptoxR_package_sitrep()}. Change services with {.code *_server()}.")
  invisible(NULL)
}


#' Set the CompTox endpoint
#'
#' @param server Use 1 for production, or supply an explicit HTTP(S) URL.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.ctx_burl` takes precedence over the lowercase
#'   environment variable `ctx_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
ctx_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint('ctx_burl', server, url_only, list('1' = .endpoint_default('ctx_burl')))
}

#' Set the Cheminformatics endpoint
#'
#' @param server Use 1 for production, or supply an explicit HTTP(S) URL.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.chemi_burl` takes precedence over the lowercase
#'   environment variable `chemi_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
chemi_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint('chemi_burl', server, url_only, list('1' = .endpoint_default('chemi_burl')))
}

#' Set the EPI Suite endpoint
#'
#' @param server Use 1 for production, or supply an explicit HTTP(S) URL.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.epi_burl` takes precedence over the lowercase
#'   environment variable `epi_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
epi_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint('epi_burl', server, url_only, list('1' = .endpoint_default('epi_burl')))
}

#' Set the ECOTOX endpoint
#'
#' @param server Use 1 for the local database, 2 for localhost Plumber, or 3 for the public browser site. The browser site is not a REST API. A database file path or HTTP(S) URL is also accepted.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.eco_burl` takes precedence over the lowercase
#'   environment variable `eco_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
eco_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint(
    'eco_burl',
    server,
    url_only,
    list('1' = eco_path(), '2' = 'http://127.0.0.1:5555', '3' = 'https://cfpub.epa.gov/ecotox/index.cfm')
  )
}

#' Set the ToxValDB endpoint
#'
#' @param server Use 1 for the local database, 2 for localhost Plumber, or 3 for the public browser site. The browser site is not a REST API. A database file path or HTTP(S) URL is also accepted.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.toxval_burl` takes precedence over the lowercase
#'   environment variable `toxval_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
toxval_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint(
    'toxval_burl',
    server,
    url_only,
    list(
      '1' = toxval_path(),
      '2' = 'http://127.0.0.1:5556',
      '3' = 'https://comptox.epa.gov/dashboard/chemical-lists/TOXVAL'
    )
  )
}

#' Set the Natural Products endpoint
#'
#' @param server Use 1 for production, or supply an explicit HTTP(S) URL.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.np_burl` takes precedence over the lowercase
#'   environment variable `np_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @keywords internal
np_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint('np_burl', server, url_only, list('1' = .endpoint_default('np_burl')))
}

#' Set the PubChem endpoint
#'
#' @param server Use 1 for production, or supply an explicit HTTP(S) URL.
#'   NULL clears the environment setting and restores option/default resolution.
#' @param url_only Return the selected target without changing settings or connections.
#' @details The option `ComptoxR.pubchem_burl` takes precedence over the lowercase
#'   environment variable `pubchem_burl`. An unset option and empty environment variable
#'   use the package default. Removed development modes give a configuration error.
#' @return The selected target for `url_only = TRUE`; otherwise the effective target.
#' @export
pubchem_server <- function(server = NULL, url_only = FALSE) {
  .set_endpoint('pubchem_burl', server, url_only, list('1' = .endpoint_default('pubchem_burl')))
}

#' Set debug mode
#'
#' @param debug One nonmissing logical value to enable or disable debug mode.
#'
#' @details
#' Debug mode applies only to the current R session. It resets to `FALSE` each
#' time the package loads, so enable it again in each session with
#' `run_debug(TRUE)`. The old `run_debug` environment variable is no longer
#' supported.
#'
#' The setter also updates the generated request dry-run option. Use
#' `run_debug(FALSE)` to disable dry runs even when the native dry-run
#' environment flag is enabled.
#'
#' @return Invisibly returns `NULL`.
#' @export
run_debug <- function(debug = FALSE) {
  if (rlang::is_bool(debug)) {
    .ComptoxREnv$run_debug <- debug
    options(comptoxr_native.dry_run = debug)
    if (isTRUE(debug)) {
      cli::cli_alert_info(
        paste0("Debug mode is now ", cli::style_bold(cli::col_red("ON")))
      )
    } else {
      cli::cli_alert_info(
        paste0("Debug mode is now ", cli::style_bold(cli::col_green("OFF")))
      )
    }
  } else {
    cli::cli_alert_warning(
      "Invalid debug option selected!"
    )
    cli::cli_alert_info("Valid options are TRUE or FALSE.")
    cli::cli_alert_warning("Debug mode set to FALSE.")
    .ComptoxREnv$run_debug <- FALSE
    options(comptoxr_native.dry_run = FALSE)
  }

  invisible(NULL)
}

#' Set verbose mode
#'
#' Sets the verbosity of the execution.
#'
#' @param verbose One nonmissing logical value that enables or disables verbose
#'   mode. The default is `FALSE`. An invalid value gives a warning and sets
#'   verbose mode to `FALSE`.
#'
#' @details
#' This function sets the `ComptoxR.run_verbose` option for the current R
#' session. To enable verbose mode in future sessions, open the user profile
#' with `file.edit("~/.Rprofile")` and add:
#'
#' ```r
#' options(ComptoxR.run_verbose = TRUE)
#' ```
#'
#' Start a new R session before this setting affects the package startup
#' header. `run_verbose(FALSE)` overrides it only for the current session. The
#' package never creates or edits `.Rprofile`.
#'
#' Call `run_verbose(TRUE)` after loading the package to enable generated
#' request diagnostics too. Changing `ComptoxR.run_verbose` directly affects
#' startup and legacy diagnostics only.
#'
#' The old `Sys.setenv(run_verbose = "TRUE")` setting is no longer supported.
#'
#' @return Invisibly returns `NULL`.
#'
#' @examples
#' \dontrun{
#' # Enable verbose mode
#' run_verbose(TRUE)
#'
#' # Disable verbose mode
#' run_verbose(FALSE)
#'
#' # Attempt to set verbose mode with an invalid value
#' run_verbose("hello")
#' }
#' @export
run_verbose <- function(verbose = FALSE) {
  if (rlang::is_bool(verbose)) {
    options(ComptoxR.run_verbose = verbose, comptoxr_native.run_verbose = verbose)
    if (isTRUE(verbose)) {
      cli::cli_alert_info(
        paste0("Verbose mode is now ", cli::style_bold(cli::col_green("ON")))
      )
    } else {
      cli::cli_alert_info(
        paste0("Verbose mode is now ", cli::style_bold(cli::col_red("OFF")))
      )
    }
  } else {
    cli::cli_alert_warning(
      "Invalid verbose option selected!"
    )
    cli::cli_alert_info("Valid options are TRUE or FALSE.")
    cli::cli_alert_warning("Verbose mode set to FALSE.")
    options(ComptoxR.run_verbose = FALSE, comptoxr_native.run_verbose = FALSE)
  }

  invisible(NULL)
}

#' Set batch limit for POST requests
#'
#' Sets the global batch limit for POST requests. Defaults to 200.
#' Only wrappers that read the `batch_limit` setting use it. Wrappers that
#' split requests at a fixed size set per API (100 items for CTX) ignore it.
#' @param limit Numeric number
#' @return Called for its side effect of setting the `batch_limit`
#'   environment variable; returns the result of [Sys.setenv()] invisibly.
#'   Warns and returns `NULL` for non-numeric input.
#' @export

batch_limit <- function(limit = 200) {
  # Initial setting if not detected

  if (is.null(Sys.getenv("batch_limit")) || Sys.getenv("batch_limit") == "") {
    Sys.setenv("batch_limit" = "200")
  }

  if (is.numeric(limit)) {
    Sys.setenv("batch_limit" = as.character(limit))
  } else {
    cli::cli_alert_warning(
      "Invalid limit option selected!"
    )
  }
}

#' Reset all servers

reset_servers <- function() {
  # Reset CompTox Chemistry Dashboard server URL
  ctx_server()
  # Reset Cheminformatics server URL
  chemi_server()
  # Reset EPI Suite server URL
  epi_server()
  # Reset ECOTOX server URL
  eco_server()
  # Reset ToxValDB server URL
  toxval_server()
  # Reset Natural Products server URL
  np_server()
  # Reset PubChem PUG REST server URL
  pubchem_server()
}

# Attach -----------------------------------------------------------------

.onAttach <- function(libname, pkgname) {
  # Effective endpoints are resolved on use. Attach only handles startup messages.

  # Conditionally display startup message based on verbosity
  if (.run_verbose_enabled() && !identical(Sys.getenv("R_DEVTOOLS_LOAD"), "true")) {
    # Use cli's message handler to preserve ANSI formatting while remaining CRAN compliant
    # cli outputs through message() by default, which packageStartupMessage wraps
    withCallingHandlers(
      .header(),
      message = function(m) {
        # Strip trailing newline to preserve original spacing
        msg <- sub("\n$", "", conditionMessage(m))
        packageStartupMessage(msg)
        invokeRestart("muffleMessage")
      }
    )
  }
}

# Load -------------------------------------------------------------------

# .extractor <- NULL
# .classifier <- NULL

# .onLoad is a special function that R runs when a package is loaded.
# This runs for BOTH library() and namespace access (ComptoxR::function).
.onLoad <- function(libname, pkgname) {
  # Call the factory ONCE and assign the result to our placeholder.

  .ComptoxREnv$run_debug <- FALSE
  .ComptoxREnv$classifier <- create_compound_classifier()

  # Hook configuration is loaded lazily on first use via get_hook_config().

  # Register the custom @apiStage roxygen2 tag. s3_register only wires these up
  # when roxygen2 is loaded (e.g. during devtools::document()), so there is no
  # hard dependency on roxygen2 at load or run time.
  s3_register("roxygen2::roxy_tag_parse", "roxy_tag_apiStage")
  s3_register("roxygen2::roxy_tag_rd", "roxy_tag_apiStage")
  s3_register("base::format", "rd_section_apiStage")

  batch_limit(limit = 200)

  #message("Is .extractor a function? ", is.function(.extractor))
  #message("Is .classifier a function? ", is.function(.classifier))

  # Silence R CMD check notes for package-private state and data-mask symbols.
  utils::globalVariables(c(
    ".",
    ".ComptoxREnv",
    "GHS Codes",
    "H-Code",
    "Hazard Class",
    "NFPA",
    "Number",
    "Symbol",
    "bin",
    "chemical",
    "child",
    "class_stage1",
    "dtxsid",
    "dtxsidName",
    "flags",
    "h_code",
    "hazard_class",
    "health_bin",
    "is_available",
    "is_isotope_formula",
    "molFormula",
    "name",
    "nfpa_fire",
    "nfpa_health",
    "nfpa_special",
    "nfpa_stability",
    "parent",
    "relatedSubstanceDTXSID",
    "rq",
    "rq_kgs",
    "rq_lbs",
    "sid",
    "special_bin",
    "structuralSimilarity"
  ))
}

.onUnload <- function(libpath) {
  if (
    !is.null(.ComptoxREnv$dsstox_db) &&
      inherits(.ComptoxREnv$dsstox_db, "DBIConnection") &&
      DBI::dbIsValid(.ComptoxREnv$dsstox_db)
  ) {
    DBI::dbDisconnect(.ComptoxREnv$dsstox_db, shutdown = TRUE)
  }
  .eco_close_con()
  .tox_close_con()
}

# Header -----------------------------------------------------------------

.header <- function() {
  version <- as.character(utils::packageVersion("ComptoxR"))
  date <- utils::packageDate("ComptoxR")
  build <- if (is.na(date)) "Development build" else paste0("Built ", date)
  cli::cli_rule(left = paste("ComptoxR", version))
  cli::cli_text("{build}")
  debug <- .run_debug_enabled()
  verbose <- .run_verbose_enabled()
  cli::cli_text("Debug: {debug} | Verbose: {verbose} | Batch limit: {Sys.getenv('batch_limit', unset = '200')}")
  run_setup()
}
