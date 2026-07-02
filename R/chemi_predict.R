#' Predict properties of chemical compounds using an external API.
#'
#' This function takes a vector of chemical identifiers as input, resolves them
#' using `chemi_resolver_lookup`, and then uses an external API to predict their properties.
#' It sends a POST request to the API endpoint, passing the resolved chemical names
#' in the request body.
#'
#' @param query A character vector of chemical identifiers to predict properties for.
#' @param report A character string specifying the report format. Must be one of
#'   "UNKNOWN", "SDF", "SMI", "MOL", "CSV", "TSV", "JSON", "XLSX", "PDF", "HTML",
#'   "XML", or "DOCX". Defaults to "JSON".
#'
#' @return A list containing the API response.  Returns NULL if the
#'   API returns no results for a given query.
#'
#' @examples
#' \dontrun{
#' # Example usage with a single identifier:
#' predicted_properties <- chemi_predict(c("aspirin"))
#' print(predicted_properties)
#'
#' # Example usage with multiple identifiers:
#' predicted_properties <- chemi_predict(c("aspirin", "ibuprofen", "water"))
#' print(predicted_properties)
#' }
#' @export
chemi_predict <- function(query, report = "JSON") {
  # Check if the query is missing. If so, abort with an error message.
  if (is.null(query) | missing(query)) {
    cli::cli_abort('Request missing')
  }

  # Resolve chemical identifiers using chemi_resolver_lookup
  resolved_chemicals <- chemi_resolver_lookup(query)

  # Check if chemi_resolver_lookup returned any results
  if (length(resolved_chemicals) == 0) {
    cli::cli_abort("No chemicals resolved for the given query.")
    return(NULL)
  }

  # Validate the report parameter
  allowed_reports <- c(
    "SDF",
    "SMI",
    "MOL",
    "CSV",
    "TSV",
    "JSON",
    "XLSX",
    "PDF",
    "HTML",
    "XML",
    "DOCX"
  )
  if (!(report %in% allowed_reports)) {
    cli::cli_warn(paste0(
      "Invalid report format '",
      report,
      "'. Defaulting to JSON."
    ))
    report <- "JSON"
  }

  # Display information about the prediction request.
  cli_rule(left = "Prediction request")
  cli_dl(
    c(
      "Number of compounds" = "{length(resolved_chemicals)}",
      "Report format" = "{report}"
    )
  )
  cli_rule()
  cli_end()

  resp <- request(Sys.getenv('chemi_burl')) %>%
    req_method("POST") %>%
    req_url_path_append("webtest/predict") %>%
    req_headers(Accept = "application/json, text/plain, */*") %>%
    req_body_json(
      list(structures = resolved_chemicals, report = report),
      auto_unbox = TRUE
    ) %>%
    req_perform()

  if (resp_status(resp) >= 400) {
    cli::cli_abort(paste("API request failed with status", resp_status(resp)))
  }

  resp_body_json(resp)
}
