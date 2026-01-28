#' Get chemicals by starting value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param word Starting string of word to search for. Values supplied as the 'word' parameter can include chemical name, DTXSID, DTXCID, CAS Registry Number (CASRN), or InChIKey.. Type: string
#' @param top Optional parameter (default: 500)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_start_with(word = "DTXSID7020182")
#' }
ct_chemical_start_with <- function(word, top = 500) {
  result <- generic_request(
    query = word,
    endpoint = "chemical/search/start-with/",
    method = "GET",
    batch_limit = 1,
    `top` = top
  )

  # Additional post-processing can be added here

  return(result)
}


