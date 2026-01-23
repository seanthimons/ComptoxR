# Internal package environment for session-level caching
.ComptoxREnv <- new.env(parent = emptyenv())

#' First time setup for functions

#'
#' Tests to see if APIs are up and tokens are present.
#'
#' @return Ping tests and API tokens.
#' @export

run_setup <- function() {
  cli::cli_rule(left = 'Configured API endpoints (ping test)')
  cli::cli_alert_warning(
  	'You can change these using the *_server() function!'
  )
	
	server_urls <- list(
  # Dynamically get the list of configured server URLs. Hardcoded until health endpoints are fully up.
		"CompTox Dashboard API" = list(
			display_url = Sys.getenv("ctx_burl"),
			ping_url = paste0(Sys.getenv("ctx_burl"), 'chemical/health')
		),
    "ECOTOX" = list(
    	display_url = Sys.getenv("eco_burl"),
    	ping_url = Sys.getenv("eco_burl")
    ),
    "EPI Suite API" = list(
    	display_url = Sys.getenv("epi_burl"),
    	ping_url = Sys.getenv("epi_burl")
    ),
		"Common Chemistry API" = list(
			display_url = Sys.getenv("cc_burl"),
			ping_url = Sys.getenv("cc_burl")
		)
    #,"Natural Products API" = 'https://app.naturalproducts.net/home'
  )

  # Filter out any endpoints with empty/unset URLs
  active_endpoints <- purrr::keep(
  	server_urls,
  	~ nzchar(.x$display_url) && !is.na(.x$display_url)
  )
  
  # Remove entries with duplicate URLs, keeping the first name. Using `unique()` would strip the names.
  ping_urls <- purrr::map_chr(active_endpoints, "ping_url")
  ping_list <- active_endpoints[!duplicated(ping_urls)]

  if (length(ping_list) == 0) {
    cli::cli_alert_info("No server endpoints are configured to ping.")
    cli::cli_end()
  } else {
    # A more informative and visually appealing check function
    check_url <- function(endpoint, name) {
    	url <- endpoint$ping_url
      tryCatch(
        {
          # Use HEAD request for efficiency; we just want to check connectivity
          req <- httr2::request(url) %>%
            httr2::req_method("HEAD") %>%
            httr2::req_timeout(5) %>%
            # Don't error on HTTP status, we check it manually
            httr2::req_error(is_error = \(resp) FALSE)
          
          start_time <- Sys.time()
          resp <- httr2::req_perform(req)
          end_time <- Sys.time()
          
          latency <- as.numeric(difftime(end_time, start_time, units = "secs"))
          latency_fmt <- paste0(round(latency * 1000), "ms")
          
          status <- httr2::resp_status(resp)
          
          status_text <- if (status >= 200 && status < 400) {
          	cli::col_green(cli::format_inline("OK ({status})"))
          } else {
          	cli::col_yellow(cli::format_inline("WARN ({status})"))
          }
          
          list(
          	name = name,
          	url = endpoint$display_url,
          	status_text = status_text,
          	latency = latency,
          	latency_fmt = latency_fmt
          )
        },
        error = function(e) {
          # Catch httr2-specific errors for more robust error messages
          error_msg <- if (inherits(e, "httr2_timeout")) {
            "Request timed out"
          } else if (inherits(e, "httr2_connect_error")){
            "Connection failed"
          } else {
            "Request failed" # Fallback for other errors
          }
          list(
          	name = name,
          	url = endpoint$display_url,
          	status_text = cli::col_red(cli::format_inline("ERROR ({error_msg})")),
          	latency = NA_real_,
          	latency_fmt = ""
          )
        }
      )
    }

		results <- purrr::imap(ping_list, check_url)

    # Check for active Cheminformatics endpoints ----
    tryCatch({
      start_time <- Sys.time()
      resp <- httr2::request(paste0(Sys.getenv('chemi_burl'), "/services/cim_component_info")) %>%
        httr2::req_perform()
      end_time <- Sys.time()
      
      latency <- as.numeric(difftime(end_time, start_time, units = "secs"))
      latency_fmt <- paste0(round(latency * 1000), "ms")

      endpoints <- resp %>%
        httr2::resp_body_json() %>%
        purrr::map(., ~ tibble::as_tibble(.x)) %>%
        purrr::list_rbind() %>% 
				dplyr::filter(!is.na(is_available))
      
      active_chemi_endpoints <- sum(endpoints$is_available, na.rm = TRUE)
      total_chemi_endpoints <- nrow(endpoints)
      
      chemi_status <- cli::col_green(
      	cli::format_inline("OK ({active_chemi_endpoints}/{total_chemi_endpoints} endpoints active)")
      )
      results <- c(results, list(list(
      	name = "Cheminformatics API",
      	url = Sys.getenv("chemi_burl"),
      	status_text = chemi_status,
      	latency = latency,
      	latency_fmt = latency_fmt
      )))
      
    }, error = function(e) {
      chemi_status <- cli::col_red("ERROR (Failed to get endpoints)")
      results <<- c(results, list(list(
      	name = "Cheminformatics API",
      	url = Sys.getenv("chemi_burl"),
      	status_text = chemi_status,
      	latency = NA_real_,
      	latency_fmt = ""
      )))
    })
    
    healthy_latency <- 0.3
    degrading_latency <- 1.0
    
    latency_colour <- function(latency, latency_fmt, healthy_latency, degrading_latency) {
    	if (latency_fmt == "") {
    		return("")
    	}
    	if (!is.finite(latency)) {
    		return(cli::col_yellow(latency_fmt))
    	}
    	if (latency <= healthy_latency) {
    		return(cli::col_green(latency_fmt))
    	}
    	if (latency <= degrading_latency) {
    		return(cli::col_yellow(latency_fmt))
    	}
    	cli::col_red(latency_fmt)
    }
    
    results_output <- purrr::map_chr(results, function(result) {
    	latency_display <- if (is.finite(result$latency)) {
    		paste0("[", latency_colour(result$latency, result$latency_fmt, healthy_latency, degrading_latency), "]")
    	} else {
    		""
    	}
    	url_display <- if (nzchar(result$url)) {
    		paste0(result$url, " - ")
    	} else {
    		""
    	}
    	
    	cli::format_inline(
    		"{.strong {result$name}}: {url_display}{result$status_text} {latency_display}"
    	)
    })
    
    cli::cli_li(items = results_output)
    cli::cli_end()
		
  }


  # Token check ----
  cli::cli_rule(left = 'API Token Status')
  # Directly check the environment variable to avoid aborting during package load
  api_key <- Sys.getenv("ctx_api_key")
  if (api_key == "") {
    cli::cli_alert_warning("CompTox API Key: {.strong NOT SET}. Use {.run Sys.setenv(ctx_api_key= 'YOUR_KEY_HERE')} to set it.")
  } else {
    cli::cli_alert_success(cli::col_green("CompTox API Key: {.strong SET}."))
  }
	api_key <- Sys.getenv("cc_api_key")
  if (api_key == "") {
    cli::cli_alert_warning("Common Chemistry API Key: {.strong NOT SET}. Use {.run Sys.setenv(cc_api_key= 'YOUR_KEY_HERE')} to set it.")
  } else {
    cli::cli_alert_success(cli::col_green("Common Chemistry API Key: {.strong SET}."))
  }
  
  invisible(NULL)
}


#' Set API endpoints for Comptox API endpoints
#'
#' @param server Defines what server to target. If `NULL` the server URL is
#'   reset. Valid options are:
#'   \itemize{
#'     \item Production: 1
#'     \item Staging: 2
#'     \item Development: 3
#'     \item Scraping: 9
#'   }
#'
#' @return Should return the Sys Env variable `ctx_burl`.
#' @export

ctx_server <- function(server = NULL) {
	if (is.null(server)) {
		{
			cli::cli_alert_danger("Server URL reset!")
			Sys.setenv("ctx_burl" = "")
		}
	} else {
		switch(
			as.character(server),
			"1" = Sys.setenv('ctx_burl' = 'https://comptox.epa.gov/ctx-api/'),
			"2" = Sys.setenv('ctx_burl' = 'https://ctx-api-stg.ccte.epa.gov/'),
			"3" = Sys.setenv('ctx_burl' = 'https://ctx-api-dev.ccte.epa.gov/'),
			"5" = Sys.setenv('ctx_burl' = 'https://comptoxstaging.rtpnc.epa.gov/ctx-api/'),
			"9" = Sys.setenv('ctx_burl' = 'https://comptox.epa.gov/dashboard-api/ccdapp2/'),
			{
				cli::cli_alert_warning("\nInvalid server option selected!\n")
				#cli::cli_alert_info("Valid options are 1 (Production), 2 (Staging), 3 (Development), and 9 (Scraping).")
				cli::cli_alert_warning("Server URL reset!")
				Sys.setenv("ctx_burl" = "")
			}
		)

		Sys.getenv('ctx_burl')
	}
}

#' Set API endpoints for Cheminformatics API endpoints
#'
#' This function sets the API endpoint for the Cheminformatics API based on the
#' specified server. If no server is specified, the function resets the API
#' endpoint to an empty string.
#'
#' @param server Defines what server to target. If `NULL`, the server URL is
#'   reset. Valid options are:
#'   \itemize{
#'     \item Production: 1
#'     \item Staging: 2
#'     \item Development: 3
#'   }
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
			"1" = Sys.setenv("chemi_burl" = "https://hcd.rtpnc.epa.gov/api"),
			# "2" = Sys.setenv("chemi_burl" = "https://hazard-dev.sciencedataexperts.com/api"),
			# "3" = Sys.setenv("chemi_burl" = "https://ccte-cced-cheminformatics.epa.gov/api"),
			"2" = Sys.setenv("chemi_burl" = "https://cim.sciencedataexperts.com/api"),
			"3" = Sys.setenv("chemi_burl" = "https://cim-dev.sciencedataexperts.com/api"), 
			{
				cli::cli_alert_warning("Invalid server option selected!")
				cli::cli_alert_info(
					"Valid options are 1 (Production), 2 (Staging), 3 (Development)."
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
				cli::cli_alert_warning("Invalid server option selected!")
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
			"1" = Sys.setenv("eco_burl" = "https://cfpub.epa.gov/ecotox/index.cfm"),
			"2" = Sys.setenv("eco_burl" = "https://hcd.rtpnc.epa.gov/"),
			"3" = Sys.setenv("eco_burl" = "http://127.0.0.1:5555"),
			{
				cli::cli_alert_warning("Invalid server option selected!")
				cli::cli_alert_info("Valid options are 1 (Dashboard), 2 (Production), 3 (Local).")
				cli::cli_alert_warning("Server URL reset!")
				Sys.setenv("eco_burl" = "")
			}
		)

		Sys.getenv("eco_burl")
	}
}

np_server <- function(server = NULL){
	if (is.null(server)) {
		{
			cli::cli_alert_danger("Server URL reset!")
			Sys.setenv("np_burl" = "")
		}
	} else {
		switch(
			as.character(server),
			"1" = Sys.setenv("np_burl" = "https://api.naturalproducts.net/latest/"),
			{
				cli::cli_alert_warning("Invalid server option selected!")
				cli::cli_alert_info("Valid options are 1 (Production).")
				cli::cli_alert_warning("Server URL reset!")
				Sys.setenv("np_burl" = "")
			}
		)

		Sys.getenv("np_burl")
	}
}

#' Set API endpoints for CAS Common Chemistry API
#' 
#' @param server Defines what server to target
#' 
#' @return Should return the Sys Env variable `cc_server`
#' @export

cc_server <- function(server = NULL){
if (is.null(server)) {
		{
			cli::cli_alert_danger("Server URL reset!")
			Sys.setenv("cc_burl" = "")
		}
	} else {
		switch(
			as.character(server),
			"1" = Sys.setenv("cc_burl" = "https://commonchemistry.cas.org/api/"),
			{
				cli::cli_alert_warning("Invalid server option selected!")
				cli::cli_alert_info("Valid options are 1 (Production).")
				cli::cli_alert_warning("Server URL reset!")
				Sys.setenv("cc_burl" = "")
			}
		)

		Sys.getenv("cc_burl")
	}
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
	if (is.logical(verbose)) {
		Sys.setenv("run_verbose" = as.character(verbose))
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
		Sys.setenv("run_verbose" = "FALSE")
	}
}

#' Set batch limit for POST requests
#'
#' Sets the global batch limit for POST requests. Defaults to 200. 
#' @param limit Numeric number
#' @export

batch_limit <- function(limit = 200){

	# Initial setting if not detected

	if (is.null(Sys.getenv("batch_limit")) || Sys.getenv("batch_limit") == ""){
		Sys.setenv("batch_limit" = "200")
	}

	if (is.numeric(limit)) {
		Sys.setenv("batch_limit" = as.character(limit))

	}else{
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
	# Reset Natural Products server URL
	np_server()
	# Reset Common Chemistry server URL
	cc_server()
}

# Attach -----------------------------------------------------------------

.onAttach <- function(libname, pkgname) {

	# Conditionally swap to DEV / STAG environments if in the DEV version
	# Only set default servers if they haven't been explicitly configured
	# Suppress messages during package attach to comply with CRAN policy
	suppressMessages({
		if (is.na(utils::packageDate('ComptoxR'))) {
			# DEV version defaults (only if not already set)
			if (Sys.getenv("ctx_burl") == "") ctx_server(server = 2)
			if (Sys.getenv("chemi_burl") == "") chemi_server(server = 3)
			if (Sys.getenv("epi_burl") == "") epi_server(server = 1)
			if (Sys.getenv("eco_burl") == "") eco_server(server = 3)
			if (Sys.getenv("np_burl") == "") np_server(server = 1)
			if (Sys.getenv("cc_burl") == "") cc_server(server = 1)
			# Only set verbose if not already configured
			if (Sys.getenv("run_verbose") == "") {
				run_verbose(verbose = FALSE)
			}
			if (Sys.getenv("run_debug") == "") {
				run_debug(debug = FALSE)
			}
			batch_limit(limit = 200)

		} else if (Sys.getenv('ctx_burl') == "") {
			# Production version defaults (only if not already set)
			ctx_server(server = 1)
			chemi_server(server = 1)
			epi_server(server = 1)
			eco_server(server = 1)
			np_server(server = 1)
			cc_server(server = 1)
			# Only set verbose if not already configured
			if (Sys.getenv("run_verbose") == "") {
				run_verbose(verbose = FALSE)
			}
			if (Sys.getenv("run_debug") == "") {
				run_debug(debug = FALSE)
			}

			batch_limit(limit = 200)
		}
	})

# Conditionally display startup message based on verbosity
	if (Sys.getenv("run_verbose") == "TRUE" && !identical(Sys.getenv("R_DEVTOOLS_LOAD"), "true")) {
		# Capture cli output and wrap in packageStartupMessage for CRAN compliance
		header_output <- paste(utils::capture.output(.header()), collapse = "\n")
		packageStartupMessage(header_output)
	}

}

# Load -------------------------------------------------------------------

# .extractor <- NULL
# .classifier <- NULL

# .onLoad is a special function that R runs when a package is loaded.
.onLoad <- function(libname, pkgname) {
	# Call the factory ONCE and assign the result to our placeholder.

  .ComptoxREnv$extractor <- create_formula_extractor_final()
	.ComptoxREnv$classifier <- create_compound_classifier()
	
	#message("Is .extractor a function? ", is.function(.extractor))
	#message("Is .classifier a function? ", is.function(.classifier))
}

	# (Optional) Silence R CMD check "no visible binding" notes
	utils::globalVariables(c(".ComptoxREnv"))

# Header -----------------------------------------------------------------

.header <- function() {
  if (is.na(utils::packageDate('ComptoxR'))) {
    build_date <- paste0(
      as.character(Sys.Date()),
      cli::style_bold(cli::col_red(" NIGHTLY BUILD"))
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
    
		cli::cli_rule(left = 'Run settings')
		debug_flag <- Sys.getenv("run_debug")
		verbose_flag <- Sys.getenv("run_verbose")
		debug_value <- if (debug_flag == "TRUE") {
			cli::col_red("TRUE")
		} else {
			cli::col_green("FALSE")
		}
		verbose_value <- if (verbose_flag == "TRUE") {
			cli::col_green("TRUE")
		} else {
			cli::col_red("FALSE")
		}
		cli::cli_dl(c(
			'Debug' = "{debug_value}",
			'Verbose' = "{verbose_value}",
			'Batch limit' = '{Sys.getenv("batch_limit")}'
		))
  })

  run_setup()
}
	
