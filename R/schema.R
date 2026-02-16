#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the various ComptoxAI API
#' endpoints (chemical, hazard, bioactivity, exposure) and for each server
#' environment (production, staging, development). The schemas are saved in the
#' 'schema' directory of the project.
#'
#' @param timeout Maximum time (in seconds) to wait for each download. Default: 30.
#'
#' @return Invisibly sets the server to production and returns `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  ct_schema()
#' }
ct_schema <- function(timeout = 30) {
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

	map(
		endpoints,
		function(endpoint) {
			imap(serv, function(idx, server) {
				# Sets the path
				ctx_server(idx)

				url <- paste0(Sys.getenv('ctx_burl'), 'docs/', endpoint, '.json')
				destfile <- here::here('schema', paste0("ctx-", endpoint, '-', server, '.json'))

				tryCatch(
					{
						req <- httr2::request(url) %>%
							httr2::req_timeout(timeout) %>%
							httr2::req_error(is_error = \(resp) FALSE)

						resp <- httr2::req_perform(req)
						status <- httr2::resp_status(resp)

						if (status >= 200 && status < 400) {
							body_raw <- httr2::resp_body_raw(resp)
							writeBin(body_raw, destfile)
							cli::cli_alert_success("Downloaded {endpoint} schema from {server} server")
						} else if (status >= 500) {
							cli::cli_alert_warning("Server error ({status}) downloading {endpoint} from {server}")
						} else {
							cli::cli_alert_warning("HTTP {status} downloading {endpoint} from {server}")
						}
					},
					httr2_timeout = function(e) {
						cli::cli_alert_warning("Timeout downloading {endpoint} schema from {server} ({timeout}s limit)")
					},
					error = function(e) {
						cli::cli_alert_warning("Network error downloading {endpoint} from {server}: {conditionMessage(e)}")
					}
				)
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
#' @param record Logical. If TRUE, returns a tibble logging all download attempts.
#' @param timeout Maximum time (in seconds) to wait for each download. Default: 30.
#'
#' @return Invisibly sets the server to production and returns `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  chemi_schema()
#' }
chemi_schema <- function(record = FALSE, timeout = 30) {
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

	# Attempt to GET and save a schema, returning list(success, status).
	attempt_download <- function(url, endpoint, server) {
		req <- httr2::request(url) %>%
			httr2::req_timeout(timeout) %>%
			httr2::req_error(is_error = \(resp) FALSE)

		resp <- try(httr2::req_perform(req), silent = TRUE)
		if (inherits(resp, "try-error")) {
			return(list(success = FALSE, status = NA_integer_))
		}

		status <- httr2::resp_status(resp)
		if (!(status >= 200 && status < 400)) {
			return(list(success = FALSE, status = status))
		}

		body_raw <- httr2::resp_body_raw(resp)
		headers <- httr2::resp_headers(resp)
		ct <- NULL
		if (length(headers) > 0) {
			nm <- tolower(names(headers))
			idx <- match('content-type', nm)
			if (!is.na(idx)) ct <- headers[[idx]]
		}
		if (is.null(ct)) ct <- ""

		# If server returned HTML (common 404 pages), skip saving.
		if (grepl('html', ct, ignore.case = TRUE)) {
			return(list(success = FALSE, status = status))
		}

		# Inspect a small text preview of the body for HTML markers as extra protection
		text_preview <- tryCatch(rawToChar(body_raw), error = function(e) "")
		if (nzchar(text_preview) && grepl('<!DOCTYPE|<html|<head|<body', text_preview, ignore.case = TRUE)) {
			return(list(success = FALSE, status = status))
		}

		# Determine extension using Content-Type or heuristics from body preview
		ext <- if (grepl('json', ct, ignore.case = TRUE)) {
			'.json'
		} else if (grepl('yaml|yml', ct, ignore.case = TRUE)) {
			'.yaml'
		} else if (nzchar(text_preview) && grepl('^\\s*\\{', text_preview)) {
			'.json'
		} else if (nzchar(text_preview) && grepl('swagger|openapi', text_preview, ignore.case = TRUE) && grepl('yaml|openapi:|swagger:', text_preview, ignore.case = TRUE)) {
			'.yaml'
		} else {
			'.json'
		}

		destfile <- here::here('schema', paste0('chemi-', endpoint, '-', server, ext))
		# Pretty-print JSON for readable diffs; fall back to raw bytes for YAML/errors
		if (ext == '.json') {
			parsed <- tryCatch(
				jsonlite::fromJSON(text_preview, simplifyVector = FALSE),
				error = function(e) NULL
			)
			if (!is.null(parsed)) {
				jsonlite::write_json(parsed, destfile, pretty = TRUE, auto_unbox = TRUE)
			} else {
				writeBin(body_raw, destfile)
			}
		} else {
			writeBin(body_raw, destfile)
		}
		return(list(success = TRUE, status = status))
	}

	any_schemas_downloaded <- FALSE

	imap(
		serv,
		function(idx, server) {
			# Sets the path
			chemi_server(idx)

			endpoints <-
				tryCatch(
					{
						request(paste0(
							Sys.getenv('chemi_burl'),
							'/services/cim_component_info'
						)) %>%
							req_timeout(timeout) %>%
							req_perform() %>%
							resp_body_json() %>%
							map(., ~ as_tibble(.x)) %>%
							list_rbind() %>%
							pull(name)
					},
					error = function(e) {
						cli::cli_alert_warning("Could not reach chemi server ({server}): {conditionMessage(e)}")
						NULL
					}
				)

			if (is.null(endpoints)) {
				cli::cli_alert_warning("Could not retrieve endpoints for {server} server. Attempting to use development server as a fallback.")

				# Set server to last in list (dev) and try again
				chemi_server(last(serv))

				endpoints <-
					tryCatch(
						{
							request(paste0(
								Sys.getenv('chemi_burl'),
								'/services/cim_component_info'
							)) %>%
								req_timeout(timeout) %>%
								req_perform() %>%
								resp_body_json() %>%
								map(., ~ as_tibble(.x)) %>%
								list_rbind() %>%
								pull(name)
						},
						error = function(e) {
							NULL
						}
					)

				# Set server back to original for downloads
				chemi_server(idx)

				if (is.null(endpoints)) {
					cli::cli_alert_warning("Fallback failed. Could not retrieve any endpoints for {server} server.")
					return()
				}
			}

			map(endpoints, function(endpoint) {
				# initialize log tibble if requested
				if (record && !exists('.__chemi_schema_log', envir = .GlobalEnv)) {
					assign('.__chemi_schema_log', tibble::tibble(
						server = character(),
						endpoint = character(),
						url = character(),
						status = integer(),
						success = logical()
					), envir = .GlobalEnv)
				}

				# Candidate URL permutations to try (ordered by likelihood)
				url_candidates <- c(
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/api-docs'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/openapi.json'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/openapi.yaml'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/swagger.json'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/swagger.yaml'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/swagger.yml'),
					paste0(Sys.getenv('chemi_burl'), '/api/', endpoint, '/openapi.json'),
					paste0(Sys.getenv('chemi_burl'), '/api/', endpoint, '/openapi.yaml'),
					paste0(Sys.getenv('chemi_burl'), '/api/', endpoint, '/swagger.yaml'),
					paste0(Sys.getenv('chemi_burl'), '/api/', endpoint, '/swagger.json'),
					paste0(Sys.getenv('chemi_burl'), '/api/', endpoint, '/api-docs'),
					paste0(Sys.getenv('chemi_burl'), '/services/', endpoint, '/api-docs'),
					paste0(Sys.getenv('chemi_burl'), '/services/', endpoint, '/swagger.json'),
					paste0(Sys.getenv('chemi_burl'), "/", endpoint, '/swagger?format=json')
				)

				for (u in url_candidates) {
					res_try <- attempt_download(u, endpoint, server)
					if (record) {
						log_tbl <- get('.__chemi_schema_log', envir = .GlobalEnv)
						log_tbl <- dplyr::bind_rows(log_tbl, tibble::tibble(
							server = server,
							endpoint = endpoint,
							url = u,
							status = ifelse(is.na(res_try$status), NA_integer_, as.integer(res_try$status)),
							success = isTRUE(res_try$success)
						))
						assign('.__chemi_schema_log', log_tbl, envir = .GlobalEnv)
					}
					if (isTRUE(res_try$success)) {
						cli::cli_alert_info("Downloaded schema for {endpoint} from {u}")
						any_schemas_downloaded <<- TRUE
						break
					}
				}
			})

			# after mapping endpoints for this server, if record requested, move on
		},
		.progress = TRUE
	)

	# Reset to production server
	chemi_server(1)

	# Warn if no schemas were downloaded across all servers
	if (!any_schemas_downloaded && !isTRUE(record)) {
		cli::cli_alert_warning("No chemi schemas could be downloaded from any server")
	}

	if (isTRUE(record)) {
		if (exists('.__chemi_schema_log', envir = .GlobalEnv)) {
			res_log <- get('.__chemi_schema_log', envir = .GlobalEnv)
			rm(list = '.__chemi_schema_log', envir = .GlobalEnv)
			return(res_log)
		} else {
			return(tibble::tibble(server = character(), endpoint = character(), url = character(), status = integer(), success = logical()))
		}
	}

	invisible(NULL)
}

#' Download API schemas
#'
#' @description
#' This function downloads the JSON schemas for the CAS Common Chemistry API
#' endpoints. The schemas are saved in the 'schema' directory of the project.
#'
#' @param timeout Maximum time (in seconds) to wait for each download. Default: 30.
#'
#' @return `NULL`.
#'
#' @examples
#' if (interactive()) {
#'  cc_schema()
#' }
cc_schema <- function(timeout = 30) {
	# Create schema directory if it doesn't exist
	schema_dir <- here::here('schema')
	if (!dir.exists(schema_dir)) {
		dir.create(schema_dir, recursive = TRUE)
	}

	endpoints <- list(
		'https://commonchemistry.cas.org/swagger/commonchemistry-swagger.json'
	)

	map(
		endpoints,
		function(endpoint) {
			url <- endpoint
			destfile <- here::here('schema', "commonchemistry-prod.json")

			tryCatch(
				{
					req <- httr2::request(url) %>%
						httr2::req_timeout(timeout) %>%
						httr2::req_error(is_error = \(resp) FALSE)

					resp <- httr2::req_perform(req)
					status <- httr2::resp_status(resp)

					if (status >= 200 && status < 400) {
						body_raw <- httr2::resp_body_raw(resp)
						writeBin(body_raw, destfile)
						cli::cli_alert_success("Downloaded Common Chemistry schema")
					} else if (status >= 500) {
						cli::cli_alert_warning("Server error ({status}) downloading Common Chemistry schema")
					} else {
						cli::cli_alert_warning("HTTP {status} downloading Common Chemistry schema")
					}
				},
				httr2_timeout = function(e) {
					cli::cli_alert_warning("Timeout downloading Common Chemistry schema ({timeout}s limit)")
				},
				error = function(e) {
					cli::cli_alert_warning("Network error downloading Common Chemistry schema: {conditionMessage(e)}")
				}
			)
		},
		.progress = TRUE
	)
	invisible(NULL)
}