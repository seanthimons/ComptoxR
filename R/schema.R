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
	serv = list(
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
				ct_server(idx)

				url_to_check <- paste0(Sys.getenv('burl'), 'docs/', endpoint, '.json')

				if (ping_url(url_to_check)) {
					download.file(
						url = url_to_check,
						destfile = here::here(
							'schema',
							paste0("ctx_", endpoint, '_', server, '.json')
						)
					)
				}
			})
		},
		.progress = TRUE
	)

	invisible(ct_server(1))
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
	serv = list(
		'prod' = 1,
		'staging' = 2,
		'dev' = 3
	)

	endpoints <- c(
		# Modules ----
		'hazard',
		'safety',
		'amos',
		'alerts',
		'webtest', # Predict v1
		'predictor', # Predict v2
		'search',
		'stdizer',
		'toxprints',
		'utilities',
		# Tools ----
		'descriptors',
		'resolver',
		'services', # AUX
		# Models -----
		'arn_cats',
		'pfas_cats',
		'ncc_cats',
		'pfas_atlas'
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

	map(
		endpoints,
		function(endpoint) {
			imap(serv, function(idx, server) {
				# Sets the path
				chemi_server(idx)

				url_to_check <- paste0(
					Sys.getenv('chemi_burl'),
					"/",
					endpoint,
					'/api-docs'
				)

				if (ping_url(url_to_check)) {
					download.file(
						url = url_to_check,
						destfile = here::here(
							'schema',
							paste0("chemi_", endpoint, '_', server, '.json')
						)
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
								paste0("chemi_", endpoint, '_', server, '.json')
							)
						)
					}
				}
			})
		},
		.progress = TRUE
	)

	invisible(chemi_server(1))
}
