#' @title Use the ClassyFire API to classify a chemical structure
#' @description This function takes a SMILES string as input, submits it to
#'   ClassyFire, polls for the result, and returns the classification.
#' @param query A character vector of SMILES strings to classify.
#' @returns A list containing the ClassyFire classification results.
#' @examples
#' \dontrun{
#' util_classyfire(query = "OC(=O)C1=C(C(O)=O)C(C(O)=O)=C(C(O)=O)C(C(O)=O)=C1C(O)=O")
#' }
#' @export
util_classyfire <- function(query) {
  # ---------------------------------------------------------------------------
  # --- Error handling
  # ---------------------------------------------------------------------------

  # --- Check if query is missing
  if (missing(query)) {
    cli::cli_abort("The `query` argument is missing. Please provide a SMILES string.")
  }

  # --- Check if query is a character vector
  if (!is.character(query)) {
    cli::cli_abort("The `query` argument must be a character vector of SMILES strings.")
  }

  # ---------------------------------------------------------------------------
  # --- Get environment variables
  # ---------------------------------------------------------------------------
  ctx_burl <- Sys.getenv("np_burl", unset = NA)
  run_debug <- as.logical(Sys.getenv("run_debug", unset = "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", unset = "FALSE"))

  if (is.na(ctx_burl)) {
    cli::cli_abort("The `np_burl` environment variable is not set. Please set it to the base API URL.")
  }

  # ---------------------------------------------------------------------------
  # --- Debugging information
  # ---------------------------------------------------------------------------
  cli::cli_rule(left = "ClassyFire payload options")
  cli::cli_dl(c(
    "Number of compounds" = "{length(query)}"
    # ,"Base URL (ctx_burl)" = "{ctx_burl}",
    # "Debug mode (run_debug)" = "{run_debug}",
    # "Verbose mode (run_verbose)" = "{run_verbose}"
  ))
  cli::cli_rule()
  cli::cli_end()

  # ---------------------------------------------------------------------------
  # --- Create the request wrapper
  # ---------------------------------------------------------------------------
  safe_classify_and_get_result <- purrr::possibly(
    .f = function(current_query, current_index, total_queries) {
      if (run_verbose) {
        cli::cli_alert_info("({current_index}/{total_queries}) Submitting SMILES for classification: {current_query}")
      }

      # --- Build submission request ---
      req_classify <-
        httr2::request(ctx_burl) %>%
        httr2::req_url_path_append(path = "/chem/classyfire/classify") %>%
        httr2::req_headers("accept" = "application/json") %>%
        httr2::req_url_query(smiles = current_query) %>%
        httr2::req_timeout(5) %>%
        httr2::req_retry(
          max_tries = 10,
          is_transient = ~ {
            status <- httr2::resp_status(.x)
            status == 429 || status >= 500
          }
        )

      # --- Handle debug mode (dry run) ---
      if (run_debug) {
        cli::cli_alert_info("Dry run for submission request:")
        httr2::req_dry_run(req_classify)

        cli::cli_alert_info("Dry run for result request (using placeholder job_id '12345'):")
        req_result_dryrun <-
          httr2::request(ctx_burl) %>%
          httr2::req_url_path_append(path = "/chem/classyfire/12345/result") %>%
          httr2::req_headers("accept" = "application/json")
        httr2::req_dry_run(req_result_dryrun)
      }

      # --- Perform submission ---
      resp_classify <- httr2::req_perform(req_classify)

      # --- Validate submission response ---
      submission_status <- httr2::resp_status(resp_classify)
      if (submission_status != 200) {
          cli::cli_alert_danger("Unexpected HTTP status {submission_status} during submission for SMILES: {current_query}")
          if (submission_status != 429) { # 429 is handled by httr2::req_retry
              return(NULL)
          }
      }
  
      
      job_id <- httr2::resp_body_json(resp_classify)$id

      # ! Temporary: print job_id
      print(paste("Job ID:", job_id))
      
      if (is.null(job_id)) {
        cli::cli_alert_danger("Could not find job ID in submission response for SMILES: {current_query}")
        return(NULL)
      }

      if (run_verbose) {
        cli::cli_alert_success("({current_index}/{total_queries}) Submission successful. Job ID: {job_id}")
        #cli::cli_alert_info("({current_index}/{total_queries}) Polling for results for job ID: {job_id}")
      }

      # --- Poll for results ---
      max_polls <- 20
      poll_interval <- 3

      for (i in seq_len(max_polls)) {
          if (run_verbose) {
          cli::cli_alert("({current_index}/{total_queries}) Polling for results for job ID: {job_id} (Attempt {i}/{max_polls})")
          }
        req_result <-
          httr2::request(ctx_burl) %>%
          httr2::req_url_path_append(path = glue::glue("chem/classyfire/{job_id}/result")) %>%
          httr2::req_headers("accept" = "application/json") %>%
          httr2::req_timeout(5) %>%
          httr2::req_retry(max_tries = 3, is_transient = \(resp) resp$status == 202)

        resp_result <- httr2::req_perform(req_result)
        status_code <- httr2::resp_status(resp_result)

        # ! Temporary: print status code
        #print(paste("Polling Status Code:", status_code))
        if (status_code == 200) {
          if (run_verbose) {
            cli::cli_alert_success("({current_index}/{total_queries}) Successfully retrieved result for job ID {job_id}")
          }
          return(httr2::resp_body_json(resp_result))
        } else if (status_code == 202) {
          if (run_verbose) {
            cli::cli_alert(".. result not ready, waiting {poll_interval}s (Attempt {i}/{max_polls})")
          }
          Sys.sleep(poll_interval)
        } else if (status_code == 400) {
          cli::cli_alert_danger("Bad request (400) for job ID {job_id}. The server could not understand the request.")
          return(NULL)
        } else if (status_code == 404) {
          cli::cli_alert_danger("Job ID {job_id} not found (404). It may have expired or never existed.")
          return(NULL)
        } else if (status_code == 422) {
          cli::cli_alert_danger("Unprocessable entity (422) for job ID {job_id}. The SMILES string may be invalid for classification.")
          return(NULL)
        } else {
          cli::cli_alert_danger("Unexpected HTTP error {status_code} when retrieving result for job ID {job_id}")
          return(NULL)
        }
      }

      cli::cli_alert_warning("Polling timed out after {max_polls} attempts for job ID {job_id}")
      return(NULL)
    },
    otherwise = NA
  )

  # --- Map over the query ---
  results <- purrr::map(
    .x = query,
    .f = safe_classify_and_get_result,
    current_index = seq_along(query),
    total_queries = length(query),
    .progress = TRUE
  )

  return(results)
}
