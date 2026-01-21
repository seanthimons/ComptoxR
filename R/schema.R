#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the various ComptoxAI API
#' endpoints (chemical, hazard, bioactivity, exposure) and for each server
#' environment (production, staging, development). The schemas are saved in the
#' 'schema' directory of the project.
#'
#' @return Invisibly sets the server to production and returns `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  ct_schema()
#' }
ct_schema <- function() {
	# Create schema directory if it doesn't exist
	schema_dir <- here::here('schema')
	if (!dir.exists(schema_dir)) {
		dir.create(schema_dir, recursive = TRUE)
	}

	serv <- list(
		'prod' = 1,
		'staging' = 2,
		'dev' = 3
	)

	endpoints <- c(
		'chemical',
		'hazard',
		'bioactivity',
		'exposure'
	)

	ping_url <- function(url) {
		req <- httr2::request(url) %>%
			httr2::req_method("HEAD") %>%
			httr2::req_timeout(5) %>%
			httr2::req_error(is_error = \(resp) FALSE)

		resp <- try(httr2::req_perform(req), silent = TRUE)

		if (inherits(resp, "try-error")) {
			cli::cli_alert_warning("URL is not reachable, skipping download: {url}")
			return(FALSE)
		}

		status <- httr2::resp_status(resp)

		if (status >= 200 && status < 400) {
			return(TRUE)
		} else {
			cli::cli_alert_warning(
				"URL returned status {status}, skipping download: {url}"
			)
			return(FALSE)
		}
	}

	map(
		endpoints,
		function(endpoint) {
			imap(serv, function(idx, server) {
				# Sets the path
				ctx_server(idx)

				url_to_check <- paste0(Sys.getenv('ctx_burl'), 'docs/', endpoint, '.json')

				if (ping_url(url_to_check)) {
					download.file(
						url = url_to_check,
						destfile = here::here(
							'schema',
							paste0("ctx-", endpoint, '-', server, '.json')
						),
						mode = 'wb'
					)
				}
			})
		},
		.progress = TRUE
	)

	invisible(ctx_server(1))
}

#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the various Cheminformatic API
#' endpoints (hazard, safety, etc.) and for each server
#' environment (production, staging, development). The schemas are saved in the
#' 'schema' directory of the project.
#'
#' @return Invisibly sets the server to production and returns `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  chemi_schema()
#' }
chemi_schema <- function() {
	# Create schema directory if it doesn't exist
	schema_dir <- here::here('schema')
	if (!dir.exists(schema_dir)) {
		dir.create(schema_dir, recursive = TRUE)
	}

	serv <- list(
		'prod' = 1,
		'staging' = 2,
		'dev' = 3
	)

	ping_url <- function(url) {
		req <- httr2::request(url) %>%
			httr2::req_method("HEAD") %>%
			httr2::req_timeout(5) %>%
			httr2::req_error(is_error = \(resp) FALSE)

		resp <- try(httr2::req_perform(req), silent = TRUE)

		if (inherits(resp, "try-error")) {
			cli::cli_alert_warning("URL is not reachable, skipping download: {url}")
			return(FALSE)
		}

		status <- httr2::resp_status(resp)

		if (status >= 200 && status < 400) {
			return(TRUE)
		} else {
			cli::cli_alert_warning(
				"URL returned status {status}, skipping download: {url}"
			)
			cli::cat_line()
			return(FALSE)
		}
	}

	imap(
		serv,
		function(idx, server) {
			# Sets the path
			chemi_server(idx)

			endpoints <-
				try(
					request(paste0(
						Sys.getenv('chemi_burl'),
						'/services/cim_component_info'
					)) %>%
						req_perform() %>%
						resp_body_json() %>%
						map(., ~ as_tibble(.x)) %>%
						list_rbind() %>%
						pull(name),
					silent = TRUE
				)

			if (inherits(endpoints, "try-error")) {
				cli::cli_alert_warning("Could not retrieve endpoints for {server} server. Attempting to use development server as a fallback.")
				
				# Set server to last in list (dev) and try again
				chemi_server(last(serv))
				
				endpoints <-
					try(
						request(paste0(
							Sys.getenv('chemi_burl'),
							'/services/cim_component_info'
						)) %>%
							req_perform() %>%
							resp_body_json() %>%
							map(., ~ as_tibble(.x)) %>%
							list_rbind() %>%
							pull(name),
						silent = TRUE
					)
				
				# Set server back to original for downloads
				chemi_server(idx)
				
				if (inherits(endpoints, "try-error")) {
					cli::cli_alert_danger("Fallback failed. Could not retrieve any endpoints for {server} server.")
					return()
				}
			}

			map(endpoints, function(endpoint) {
				url_to_check <-
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/api-docs')

				if (ping_url(url_to_check)) {
					download.file(
						url = url_to_check,
						destfile = here::here(
							'schema',
							paste0("chemi-", endpoint, '-', server, '.json')
						),
						mode = 'wb'
					)
				} else {
					# TODO remove when harmonized
					# Attempt 2 for other sites

					url_to_check <- paste0(
						Sys.getenv('chemi_burl'),
						"/",
						endpoint,
						'/swagger.json'
					)

					if (ping_url(url_to_check)) {
						download.file(
							url = url_to_check,
							destfile = here::here(
								'schema',
								paste0("chemi-", endpoint, '-', server, '.json')
							),
							mode = 'wb'
						)
					}
				}
			})
		},
		.progress = TRUE
	)

	invisible(chemi_server(1))
}

#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the CAS Common Chemistry API
#' endpoints. The schemas are saved in the 'schema' directory of the project.
#'
#' @return `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  cc_schema()
#' }
cc_schema <- function() {
	# Create schema directory if it doesn't exist
	schema_dir <- here::here('schema')
	if (!dir.exists(schema_dir)) {
		dir.create(schema_dir, recursive = TRUE)
	}

	endpoints <- list(
		'https://commonchemistry.cas.org/swagger/commonchemistry-swagger.json'
	)

	ping_url <- function(url) {
		req <- httr2::request(url) %>%
			httr2::req_method("HEAD") %>%
			httr2::req_timeout(5) %>%
			httr2::req_error(is_error = \(resp) FALSE)

		resp <- try(httr2::req_perform(req), silent = TRUE)

		if (inherits(resp, "try-error")) {
			cli::cli_alert_warning("URL is not reachable, skipping download: {url}")
			return(FALSE)
		}

		status <- httr2::resp_status(resp)

		if (status >= 200 && status < 400) {
			return(TRUE)
		} else {
			cli::cli_alert_warning(
				"URL returned status {status}, skipping download: {url}"
			)
			return(FALSE)
		}
	}

	map(
		endpoints,
		function(endpoint) {
				# Sets the path
	
				url_to_check <- endpoint

				#if (ping_url(url_to_check)) {
					download.file(
						url = url_to_check,
						destfile = here::here(
							'schema',
							paste0("commonchemistry-prod.json")
						),
						mode = 'wb'
					)
				#}
		},
		.progress = TRUE
	)
	invisible(NULL)
}