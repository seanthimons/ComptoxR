#' Get chemicals for a batch of exact values
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Search for chemicals using exact string matching (batch).
#' Values are sent as newline-delimited plain text.
#'
#' @param query Character vector of search terms (chemical names, DTXSIDs, CAS, InChIKey)
#' @return A tibble with search results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_equal_bulk(query = c("DTXSID7020182", "DTXSID9020112"))
#' }
ct_chemical_search_equal_bulk <- function(query) {
  # Input validation
  if (is.list(query) && !is.data.frame(query)) {
    query <- as.character(unlist(query, use.names = FALSE))
  }
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & nzchar(query)]

  if (length(query) == 0) {
    cli::cli_abort("Query must contain at least one non-empty value.")
  }

  # Batch configuration (API max is 200)
  batch_limit <- as.numeric(Sys.getenv("batch_limit", "200"))
  batch_limit <- min(batch_limit, 200)  # Enforce API maximum

  # Split into batches
  if (length(query) > batch_limit) {
    batches <- split(query, ceiling(seq_along(query) / batch_limit))
  } else {
    batches <- list(query)
  }

  # Build and execute requests
  results <- purrr::map(batches, function(batch) {
    body_text <- paste(batch, collapse = "\n")

    req <- httr2::request(Sys.getenv("ctx_burl")) |>
      httr2::req_url_path_append("chemical/search/equal/") |>
      httr2::req_headers(
        Accept = "application/json",
        `x-api-key` = ct_api_key()
      ) |>
      httr2::req_body_raw(body_text, type = "text/plain")

    resp <- httr2::req_perform(req)

    if (httr2::resp_status(resp) >= 300) {
      cli::cli_warn("Request failed with status {httr2::resp_status(resp)}")
      return(NULL)
    }

    httr2::resp_body_json(resp)
  }, .progress = length(batches) > 1) |>
    purrr::list_flatten() |>
    purrr::compact()

  if (length(results) == 0) {
    return(tibble::tibble())
  }

  # Convert to tibble
  results |>
    purrr::map(function(x) {
      x[purrr::map_lgl(x, is.null)] <- NA
      tibble::as_tibble(x)
    }) |>
    purrr::list_rbind()
}


#' Get chemicals by exact value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param word Exact string of word to search for. Values supplied as the 'word' parameter can include chemical name, DTXSID, DTXCID, CAS Registry Number (CASRN), or InChIKey.. Type: string
#' @param projection Optional parameter (default: chemicalsearchall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_equal(word = "DTXSID7020182")
#' }
ct_chemical_search_equal <- function(word, projection = "chemicalsearchall") {
  result <- generic_request(
    query = word,
    endpoint = "chemical/search/equal/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


