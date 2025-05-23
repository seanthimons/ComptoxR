#' Resolve chemical identifiers using an external API.

#'
#' This function takes a vector of chemical identifiers as input and uses an external API
#' to resolve them. It sends a POST request to the API endpoint, passing the identifiers
#' in the request body. The API response is then parsed to extract the 'chemical' field
#' from each returned object.
#'
#' @param query A character vector of chemical identifiers to resolve.
#' @return A list containing the resolved chemical names. Each element of the list
#'   corresponds to an identifier in the input `query`.  Returns an empty list if the
#'   API returns no results for a given query. If `dry_run` is TRUE, returns the constructed
#'   request object.
#'
#' @examples
#' \dontrun{
#' # Example usage with a single identifier:
#' resolved_name <- chemi_resolver(c("aspirin"))
#' print(resolved_name)
#'
#' # Example usage with multiple identifiers:
#' resolved_names <- chemi_resolver(c("aspirin", "ibuprofen", "water"))
#' print(resolved_names)
#'
#' # Example usage with dry_run:
#' request_obj <- chemi_resolver(c("aspirin"), dry_run = TRUE)
#' print(request_obj)
#' }
#' @export
chemi_resolver <- function(query) {
  req <- request(Sys.getenv('chemi_burl')) %>%
    req_method("POST") %>%
    req_url_path_append("api/resolver/lookup") %>%
    req_headers(Accept = "application/json, text/plain, */*") %>%
    req_body_json(
      list(
        fuzzy = "Not",
        ids = query,
        idsType = "DTXSID",
        mol = TRUE
      ),
      auto_unbox = TRUE
    )

  resp <- req %>%
    req_perform()

  if (resp_status(resp) < 200 || resp_status(resp) >= 300) {
    cli::cli_abort(paste("API request failed with status", resp_status(resp)))
  }

  body <- resp_body_json(resp)

  if (length(body) == 0) {
    cli::cli_alert_warning("No results found for the given query.")
    return(list())
  }

  map(body, ~ pluck(.x, 'chemical'))
}
