#' Get chemicals for a batch of exact values
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param query Character vector of values to search for
#' @return A tibble with search results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_equal_bulk(query = c("DTXSID7020182", "DTXSID9020112"))
#' }
ct_chemical_search_equal_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/search/equal/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000")),
    body_type = "raw_text"
  )

  return(result)
}

#' Get chemicals by exact value
#'
#' @description
#' `r lifecycle::badge("stable")`
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

  return(result)
}
