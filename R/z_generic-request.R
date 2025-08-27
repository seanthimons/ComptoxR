#' Perform a generalized, robust, and user-friendly API request
perform_request <- function(
	query
){

	#1. Check for Required Arguments ---- 


	#2. Define the Core Safe Action ----
	safe_perform_and_parse <- safely(\(req, ...) {
		req %>%
			req_perform(...) %>% 
			resp_body_json(simplifyVector = TRUE)
	})

	#3. Base Request Construction ----
	base_req <- request(base_url) %>%
		req_url_path_append(path) %>% 
		req_headers(
			`x-api-key` = ct_api_key(),
			"Accept" = "application/json"
		)

	#4. Method-Specific Logic ----
	##4.1. GET ----

	if (method == "GET") {

			perform_get_for_query <- function(q, req, ...) {
				
				request <- req %>%
					req_url_path_append(!!!q)

			}

			results <- map(
				query,
				perform_get_for_query,
				req = base_req,
				...,
				.progress = .progress
			)
		}
	
##4.2. POST ----
	
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
			request <- req %>% req_body_json(data = chunk)

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

	return(results)
}
