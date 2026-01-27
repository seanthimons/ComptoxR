#' Get chemicals for a batch of exact values
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character string to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_search_equal_bulk(query = "DTXSID7020182")
#' }
ct_chemical_search_equal_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/search/equal/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "1000"))
  )

  return(result)
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


