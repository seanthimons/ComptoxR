#' Perform a generalized, robust, and user-friendly API request
#'
#' This function handles iterative GET and POST requests with rich user feedback,
#' automatic batching for POST, and robust error handling.
#'
#' It also includes a dry-run mode for debugging. If the system environment
#' variable `run_debug` is set to "TRUE" (e.g., via `Sys.setenv(run_debug = "TRUE")`),
#' the function will print the request details to the console instead of
#' performing the live API call.
#'
#' @param base_url The base URL of the API (e.g., "http://httpbin.org").
#' @param path The specific endpoint path to be appended (e.g., "/get" or "/post").
#' @param method The HTTP method to use, either "GET" or "POST".
#' @param query For GET requests, a named list or a list of named lists to
#'   iterate over. Each list is passed to `httr2::req_url_query()`.
#' @param body For POST requests, a list of items to be sent as the JSON body.
#'   The list will be automatically split into batches of 100.
#' @param verbose A logical. If TRUE, detailed alerts are printed for each
#'   request and its status.
#' @param .progress A logical. If TRUE, a progress bar is displayed for any
#'   iterative operation.
#' @param ... Additional arguments passed on to `httr2::req_perform()`.
#'
#' @return A list of lists. Each inner list contains two elements: `result`
#'   (the parsed JSON body on success, or a dry-run message) and `error`
#'   (the error object on failure).
#'
perform_request <- function(
	base_url,
	path,
	method = c("GET", "POST"),
	query = NULL,
	body = NULL,
	verbose = FALSE,
	.progress = FALSE,
	...
) {
	# --- 1. Input Validation and Setup ---
	method <- arg_match(method)
	is_dry_run <- Sys.getenv("run_debug", unset = "FALSE") == "TRUE"

	if (is_dry_run) {
		cli_alert_warning("DRY RUN MODE IS ACTIVE. No live requests will be sent.")
	}

	if (method == "POST" && is.null(body)) {
		cli_abort("Error: A `body` must be provided for POST requests.")
	}
	if (method == "GET" && !is.null(body)) {
		cli_warn("A `body` was provided for a GET request and will be ignored.")
	}
	if (method == "POST" && !is.null(query)) {
		cli_warn("A `query` was provided for a POST request and will be ignored.")
	}

	# --- 2. Define the Core Safe Action ---
	safe_perform_and_parse <- safely(\(req, ...) {
		req |>
			req_perform(...) |>
			resp_body_json(simplifyVector = TRUE)
	})

	# --- 3. Base Request Construction ---
	base_req <- request(base_url) |>
		req_url_path_append(path) |>
		req_headers("Accept" = "application/json")

	# --- 4. Method-Specific Logic ---
	if (method == "GET") {
		if (is.null(query)) {
			cli_rule(left = "Performing Single GET Request")
			if (verbose) {
				cli_alert_info("Target: {.url {base_url}{path}}")
			}

			if (is_dry_run) {
				req_dry_run(base_req)
				results <- list(list(
					result = "DRY RUN: Request details printed above.",
					error = NULL
				))
			} else {
				results <- list(safe_perform_and_parse(base_req, ...))
			}
		} else {
			cli_rule(left = "Performing Iterative GET Requests")
			cli_dl(c("Number of queries" = "{length(query)}"))

			perform_get_for_query <- function(q, req, ...) {
				if (verbose) {
					cli_alert_info("Querying with: {.val {names(q)}} = {.val {q}}")
				}
				request <- req |> req_url_query(!!!q)

				if (is_dry_run) {
					req_dry_run(request)
					return(list(
						result = "DRY RUN: Request details printed above.",
						error = NULL
					))
				} else {
					return(safe_perform_and_parse(request, ...))
				}
			}

			results <- map(
				query,
				perform_get_for_query,
				req = base_req,
				...,
				.progress = .progress
			)
		}
	}

	if (method == "POST") {
		if (length(body) > 100) {
			body_chunks <- split(body, ceiling(seq_along(body) / 100))
			cli_rule(left = "Performing Batched POST Request")
			cli_dl(c(
				"Total items" = "{length(body)}",
				"Batch size" = "100",
				"Number of batches" = "{length(body_chunks)}"
			))
		} else {
			body_chunks <- list(body)
			cli_rule(left = "Performing Single POST Request")
		}

		perform_post_for_chunk <- function(chunk, req, ...) {
			if (verbose) {
				cli_alert_info("Preparing batch of {length(chunk)} items.")
			}
			request <- req |> req_body_json(data = chunk)

			if (is_dry_run) {
				req_dry_run(request)
				return(list(
					result = "DRY RUN: Request details printed above.",
					error = NULL
				))
			} else {
				return(safe_perform_and_parse(request, ...))
			}
		}

		results <- map(
			body_chunks,
			perform_post_for_chunk,
			req = base_req,
			...,
			.progress = .progress
		)
	}

	cli_rule()
	return(results)
}
