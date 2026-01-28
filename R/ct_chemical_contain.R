#' Get chemicals by substring value
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param word Substring of word to seach for. Values supplied as the 'word' parameter can include chemical name, DTXSID, DTXCID, CAS Registry Number (CASRN), or InChIKey.. Type: string
#' @param top Optional parameter (default: 0)
#' @param projection Optional parameter (default: chemicalsearchall)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_contain(word = "DTXSID7020182")
#' }
ct_chemical_contain <- function(word, top = 0, projection = "chemicalsearchall") {
  result <- generic_request(
    query = word,
    endpoint = "chemical/search/contain/",
    method = "GET",
    batch_limit = 1,
    `top` = top,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


