#' First time setup for functions
#'
#' Tests to see if APIs are up and tokens are present.
#'
#' @return Ping tests and API tokens.
#' @export

run_setup <- function() {
  cli::cli_rule()
  cli::cli_alert_warning(
    '\nAttempting ping test...'
  )
  #cli::cli_text()

  # Ping -------------------------------------------------------------------

  ping_list <-
    list(
      'https://api-ccte.epa.gov/exposure/health',
      'https://api-ccte.epa.gov/hazard/health',
      'https://api-ccte.epa.gov/bioactivity/health',
      'https://api-ccte.epa.gov/chemical/health',

      'https://hcd.rtpnc.epa.gov/#/', #prod
      'https://hazard-dev.sciencedataexperts.com/#/', #dev

      'https://episuite.dev/EpiWebSuite/#/',
      "https://cfpub.epa.gov/ecotox/index.cfm"
    )

  # Ping results -----------------------------------------------------------

  check_url <- function(url) {
    tryCatch(
      {
        response <- httr::GET(url, httr::timeout(5))
        status_code <- httr::status_code(response)
        return(paste(url, ": ", status_code))
      },
      error = function(e) {
        if (grepl("Could not resolve host", e$message)) {
          return(paste(url, "- Error: Could not resolve host"))
        } else if (grepl("Timeout", e$message)) {
          return(paste(url, "- Error: Request timed out"))
        } else {
          return(paste(url, "- Error:", e$message))
        }
      }
    )
  }

  results <- lapply(ping_list, check_url)

  cli::cli_li(items = results)
  cli::cli_end()

  # Token check ------------------------------------------------------------

  cli::cli_rule()
  cli::cli_alert_warning('Looking for API tokens...')
  cli::cli_text('{ct_api_key()}')
}

.header <- function() {
  if (is.na(build_date <- utils::packageDate('ComptoxR'))) {
    build_date <- paste0(
      as.character(Sys.Date()),
      cli::style_bold(cli::col_red(" DEV"))
    )
  } else {
    build_date <- as.character(utils::packageDate('ComptoxR'))
  }

  cli::cli({
    cli::cli_rule()

    cli::cli_alert_success(
      c(
        "This is version ",
        {
          as.character(utils::packageVersion('ComptoxR'))
        },
        " of ComptoxR"
      )
    )
    cli::cli_alert_success(
      c('Built on: ', {
        build_date
      })
    )
    cli::cli_rule()
    cli::cli_alert_warning('Available API endpoints:')
    cli::cli_alert_warning(
      'You can change these using the *_server() function!'
    )
    cli::cli_dl(c(
      'CompTox Chemistry Dashboard' = '{Sys.getenv("burl")}',
      'Cheminformatics' = '{Sys.getenv("chemi_burl")}',
      'ECOTOX' = '{Sys.getenv("eco_burl")}',
      'EPI Suite' = '{Sys.getenv("epi_burl")}'
    ))
  })

  run_setup()
}

#' Set API endpoints for Comptox API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable 'burl'
#' @export

ct_server <- function(server = NULL) {
  if (is.null(server)) {
    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("burl" = "")
    }
  } else {
    switch(
      as.character(server),
      "1" = Sys.setenv('burl' = 'https://api-ccte.epa.gov/'),
      "2" = Sys.setenv('burl' = 'https://api-ccte-stg.epa.gov/'),
      "3" = Sys.setenv(
        'burl' = 'https://comptox.epa.gov/dashboard-api/ccdapp2/'
      ),
      {
        cli::cli_alert_warning("\nInvalid server option selected!\n")
        cli::cli_alert_info("Valid options are 1 (Production) and 2 (Staging).")
        cli::cli_alert_warning("Server URL reset!")
        Sys.setenv("burl" = "")
      }
    )

    Sys.getenv('burl')
  }
}

#' Set API endpoints for Cheminformatics API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `chemi_burl`
#' @export

chemi_server <- function(server = NULL) {
  if (is.null(server)) {
    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("chemi_burl" = "")
    }
  } else {
    switch(
      as.character(server),
      "1" = Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/"),
      "2" = Sys.setenv(
        "chemi_burl" = "https://hazard-dev.sciencedataexperts.com/"
      ),
      "3" = Sys.setenv(
        "chemi_burl" = "https://ccte-cced-cheminformatics.epa.gov/"
      ),
      {
        cli::cli_alert_warning("\nInvalid server option selected!\n")
        cli::cli_alert_info(
          "Valid options are 1 (Production), 2 (Development), and 3 (Internal)."
        )
        cli::cli_alert_warning("Server URL reset!")
        Sys.setenv("chemi_burl" = "")
      }
    )

    Sys.getenv("chemi_burl")
  }
}

#' Set API endpoints for EPI Suite API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `epi_burl`
#' @export

epi_server <- function(server = NULL) {
  if (is.null(server)) {
    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("epi_burl" = "")
    }
  } else {
    switch(
      as.character(server),
      "1" = Sys.setenv("epi_burl" = "https://episuite.dev/EpiWebSuite/api"),
      {
        cli::cli_alert_warning("\nInvalid server option selected!\n")
        cli::cli_alert_info("Valid option is 1 (Production).")
        cli::cli_alert_warning("Server URL reset!")
        Sys.setenv("epi_burl" = "")
      }
    )

    Sys.getenv("epi_burl")
  }
}

#' Set API endpoints for ECOTOX API endpoints
#'
#' @param server Defines what server to target
#'
#' @return Should return the Sys Env variable `eco_burl`
#' @export

eco_server <- function(server = NULL) {
  if (is.null(server)) {
    {
      cli::cli_alert_danger("Server URL reset!")
      Sys.setenv("eco_burl" = "")
    }
  } else {
    switch(
      as.character(server),
      "2" = Sys.setenv("eco_burl" = "https://hcd.rtpnc.epa.gov/"),
      "1" = Sys.setenv("eco_burl" = "http://127.0.0.1:5555"),
      {
        cli::cli_alert_warning("\nInvalid server option selected!\n")
        cli::cli_alert_info("Valid options are 1 (Local) and 2 (Production).")
        cli::cli_alert_warning("Server URL reset!")
        Sys.setenv("eco_burl" = "")
      }
    )

    Sys.getenv("eco_burl")
  }
}

#' Reset all servers

reset_servers <- function() {
  ct_server()
  chemi_server()
  epi_server()
  eco_server()
}

#' Set debug mode
#'
#' @param debug A logical value to enable or disable debug mode.
#'
#' @return Should return the Sys Env variable `run_debug`
#' @export
run_debug <- function(debug = FALSE) {
  if (is.logical(debug)) {
    Sys.setenv("run_debug" = as.character(debug))
  } else {
    cli::cli_alert_warning(
      "\nInvalid debug option selected!\n"
    )
    cli::cli_alert_info("Valid options are TRUE or FALSE.")
    cli::cli_alert_warning("Debug mode set to FALSE.")
    Sys.setenv("run_debug" = "FALSE")
  }
}

#' Set verbose mode
#'
#' Sets the verbosity of the execution.
#'
#' @param verbose A logical value indicating whether verbose mode should be enabled.
#'   Defaults to `FALSE`. If a non-logical value is provided, a warning is issued,
#'   and verbose mode is set to `FALSE`.
#'
#' @details
#' This function sets the `"run_verbose"` environment variable based on the
#' `verbose` argument. If `verbose` is `TRUE`, the environment variable is set
#' to `"TRUE"`. Otherwise, it is set to `"FALSE"`. If an invalid value is
#' provided for `verbose`, a warning message is displayed, and the environment
#' variable is set to `"FALSE"`.
#'
#' @examples
#' \dontrun{
#' # Enable verbose mode
#' set_verbose(TRUE)
#'
#' # Disable verbose mode
#' set_verbose(FALSE)
#'
#' # Attempt to set verbose mode with an invalid value
#' set_verbose("hello")
#' }
#' @export
set_verbose <- function(verbose = FALSE) {
  if (is.logical(verbose)) {
    Sys.setenv("run_verbose" = as.character(verbose))
  } else {
    cli::cli_alert_warning(
      "\nInvalid verbose option selected!\n"
    )
    cli::cli_alert_info("Valid options are TRUE or FALSE.")
    cli::cli_alert_warning("Verbose mode set to FALSE.")
    Sys.setenv("run_verbose" = "FALSE")
  }
}

# Attach -----------------------------------------------------------------

.onAttach <- function(libname, pkgname) {
  if (Sys.getenv('burl') == "" | Sys.getenv("chemi_burl") == "") {
    ct_server(server = 1)
    chemi_server(server = 1)
    epi_server(server = 1)
    eco_server(server = 1)
    run_debug(debug = FALSE)
    set_verbose(verbose = TRUE)
  }

  packageStartupMessage(
    .header()
  )
}

# Load -------------------------------------------------------------------

.extractor <- NULL
.classifier <- NULL

# .onLoad is a special function that R runs when a package is loaded.
.onLoad <- function(libname, pkgname) {
  # Call the factory ONCE and assign the result to our placeholder.
  # The "super-assignment" operator (<<-) ensures we modify the .extractor
  # in the package's namespace, not just a local copy.
  .extractor <<- create_formula_extractor_final()
  .classifier <<- create_compound_classifier()
  #message("Is .extractor a function? ", is.function(.extractor))
  #message("Is .classifier a function? ", is.function(.classifier))
}
