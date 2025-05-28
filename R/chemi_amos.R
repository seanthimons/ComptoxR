#' Get ClassyFire Classification for DTXSID
#'
#' This function retrieves the ClassyFire classification for a given DTXSID using the CCTE-CCED cheminformatics API.
#'
#' @param query A character vector of DTXSIDs to query.
#'
#' @return A list of ClassyFire classifications, one for each DTXSID in the input `query`.
#'         Returns `NULL` if there is an error or no data is found.
#'
#' @examples
#' \dontrun{
#'   # Get the ClassyFire classification for a single DTXSID
#'   result <- chemi_classyfire(query = "DTXSID6029626")
#'   print(result)
#'
#'   # Get the AMOS classification for multiple DTXSIDs
#'   results <- chemi_classyfire(query = c("DTXSID6029626", "DTXSID5029625"))
#'   print(results)
#' }
#'
#' @importFrom tidyverse purrr map
#' @importFrom httr2 request req_headers req_perform resp_body_json
#' @importFrom cli cli_alert_success cli_alert_warning cli_alert_danger
#' @export
chemi_classyfire <- function(query) {
  if (!is.character(query)) {
    cli::cli_alert_danger("The `query` parameter must be a character vector.")
    return(NULL)
  }

  fetch_data <- function(dtxsid) {
    
    cli::cli_alert_info("Making request for {.val {dtxsid}}")
    req <- httr2::request(Sys.getenv('chemi')) |>
      httr2::req_url_path_append(., 'api/amos/get_classification_for_dtxsid/')
      httr2::req_headers(accept = "application/json")

    resp <- tryCatch(
      httr2::req_perform(req),
      error = function(e) {
        cli::cli_alert_danger(
          "Request failed for {.val {dtxsid}}: {.val {e$message}}"
        )
        return(NULL)
      }
    )

    if (is.null(resp)) {
      return(NULL)
    }

    if (httr2::resp_status(resp) != 200) {
      cli::cli_alert_warning(
        "Request for {.val {dtxsid}} failed with status {.val {httr2::resp_status(resp)}}"
      )
      return(NULL)
    }

    tryCatch(
      httr2::resp_body_json(resp),
      error = function(e) {
        cli::cli_alert_danger(
          "Failed to parse JSON for {.val {dtxsid}}: {.val {e$message}}"
        )
        return(NULL)
      }
    )
  }

  if (length(query) > 1) {
    results <- purrr::map(query, fetch_data)
  } else {
    results <- list(fetch_data(query))
  }

  if (all(purrr::map_lgl(results, is.null))) {
    cli::cli_alert_danger("No data found for any of the DTXSIDs.")
    return(NULL)
  } else {
    cli::cli_alert_success("Successfully retrieved AMOS classifications.")
    return(results)
  }
}
