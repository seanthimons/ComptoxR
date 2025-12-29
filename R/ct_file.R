#' Get MOL file for a compound
#'
#' @param query A single DTXSID to retrieve MOL file for
#'
#' @return Returns a string containing the MOL file content
#' @export
ct_file <- function(query) {
  # Build request
  req <- httr2::request(Sys.getenv('ctx_burl')) %>%
    httr2::req_url_path_append('chemical/file/mol/search/by-dtxsid/') %>%
    httr2::req_url_path_append(query) %>%
    httr2::req_headers(`x-api-key` = ct_api_key()) %>%
    httr2::req_method("GET")

  # Perform request
  resp <- httr2::req_perform(req)

  # Check status and return
  if (httr2::resp_status(resp) == 200) {
    return(httr2::resp_body_string(resp))
  } else {
    cli::cli_warn("Bad file request for {query} (status: {httr2::resp_status(resp)})")
    return(NULL)
  }
}
