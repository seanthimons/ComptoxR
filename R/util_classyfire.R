#' @title Use the ClassyFire API to classify a chemical structure
#' @description This function takes a SMILES string as input and returns the
#'   ClassyFire classification for that structure.
#' @param query A character vector of SMILES strings to classify.
#' @param path The API endpoint path.
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
  burl <- Sys.getenv("burl", unset = NA)
  run_debug <- as.logical(Sys.getenv("run_debug", unset = "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", unset = "FALSE"))

  # ---------------------------------------------------------------------------
  # --- Debugging information
  # ---------------------------------------------------------------------------
  cli::cli_rule(left = "ClassyFire payload options")
  cli::cli_dl(c("Number of compounds" = "{length(query)}"))
  cli::cli_rule()
  cli::cli_end()

  # ---------------------------------------------------------------------------
  # --- Check if debug mode is active
  # ---------------------------------------------------------------------------
  if (run_debug) {
    cli::cli_alert_info("Debug mode is active. Performing dry run.")
  }

  # ---------------------------------------------------------------------------
  # --- Create the request
  # ---------------------------------------------------------------------------
  safe_classify <- purrr::possibly(
    .f = function(current_query, current_index, total_queries) {
      # ---------------------------------------------------------------------------
    # --- Verbose output
      # ---------------------------------------------------------------------------
    if (isTRUE(as.logical(Sys.getenv('set_verbose')))) {
      cli::cli_alert_info("Processing query {current_index} of {total_queries}: item_id = {current_query}")
    }

  # ---------------------------------------------------------------------------
  # --- Build request
  # ---------------------------------------------------------------------------
    request <-
      httr2::request(Sys.getenv('np_burl')) %>%
      httr2::req_url_path_append(path = "/chem/classyfire/classify") %>%
        httr2::req_headers(
          "accept" = "application/json"
        ) %>%
      httr2::req_url_query(smiles = current_query) %>%
      httr2::req_timeout(5) %>% 
      httr2::req_retry(max_tries = 3)

  # ---------------------------------------------------------------------------
  # --- Dry run or execute request
  # ---------------------------------------------------------------------------
    if (isTRUE(as.logical(Sys.getenv('run_debug')))) {
      return(httr2::req_dry_run(request))
    } else {
      response <- httr2::req_perform(request)

  # -----------------------------------------------------------------------
  # --- Check for errors
  # -----------------------------------------------------------------------
      if (httr2::resp_is_error(response)) {
        cli::cli_alert_danger("HTTP error {response$status_code} for query {current_query}")
        return(NULL)
      } else {

        if (isTRUE(as.logical(Sys.getenv('set_verbose')))){
        cli::cli_alert_success("Successfully classified query {current_query}")}
      }

      # -----------------------------------------------------------------------
      # --- Parse response
      # -----------------------------------------------------------------------
      result <- httr2::resp_body_json(response)
      return(result)
    }
    },
    otherwise = NA
  )

  # ---------------------------------------------------------------------------
  # --- Map over the query
  # ---------------------------------------------------------------------------
  results <- purrr::map(
    .x = query,
    .f = safe_classify,
    current_index = seq_along(query),
    total_queries = length(query),
    .progress = TRUE
  )

  return(results)
}

