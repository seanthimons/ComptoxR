#' Perform a generalized and robust API request
#'
#' This function can perform either a GET or a POST request. For POST requests,
#' it automatically splits the body into batches of 100 and sends each batch
#' in a separate, safe request.
#'
#' @param base_url The base URL of the API (e.g., "http://httpbin.org").
#' @param path The specific endpoint path to be appended (e.g., "/post").
#' @param method The HTTP method to use, either "GET" or "POST".
#' @param body An R list or vector to be sent as the JSON body for a POST request.
#' @param ... Additional arguments passed on to `httr2::req_perform()`.
#'
#' @return For GET requests, a single list with 'result' and 'error' components.
#'   For POST requests, a list of lists. Each inner list corresponds to a
#'   batch and contains 'result' and 'error' components.
#'
perform_api_request <- function(
	base_url,
	path,
	method = c("GET", "POST"),
	body = NULL,
	...
) {
	# --- 1. Input Validation ---
	method <- arg_match(method) # Match against the provided choices ("GET", "POST")

	if (method == "POST" && is.null(body)) {
		stop("Error: A `body` must be provided for POST requests.")
	}
	if (method == "GET" && !is.null(body)) {
		warning(
			"Warning: A `body` was provided for a GET request and will be ignored."
		)
	}

	# --- 2. Base Request Construction ---
	# Build the initial request object with the base URL and path
	base_req <- request(base_url) |>
		req_url_path_append(path) |>
		req_headers("Accept" = "application/json") # Assume we want JSON back

	# --- 3. Method-Specific Logic ---
	if (method == "GET") {
		message(paste(
			"Performing a single GET request to:",
			paste0(base_url, path)
		))

		# Create a "safe" version of req_perform
		safe_perform <- safely(\(req, ...) req_perform(req, ...))

		# Execute and return the single, safe request
		result <- safe_perform(base_req, ...)
		return(result)
	}

	if (method == "POST") {
		# --- Batching Logic ---
		if (length(body) > 100) {
			# Split the body into a list of chunks, each with max 100 items
			body_chunks <- split(body, ceiling(seq_along(body) / 100))
			message(
				paste0("Body has ", length(body), " items. Splitting into ", length(body_chunks), " batches of up to 100 each.")
			)
		} else {
			# If 100 or fewer items, just wrap it in a list to keep the data structure consistent
			body_chunks <- list(body)
			message(
				paste("Performing a single POST request to:", paste0(base_url, path))
			)
		}

		# --- Iteration Logic ---
		# Define a safe function that takes one chunk, adds it to the body, and performs the request
		safe_post_perform <- safely(\(chunk, req, ...) {
			req |>
				req_body_json(data = chunk) |>
				req_perform(...)
		})

		# Use purrr::map() to apply this safe function to every chunk.
		# The base request object and any other arguments (...) are passed along.
		results <- map(body_chunks, safe_post_perform, req = base_req, ...)

		return(results)
	}
}
