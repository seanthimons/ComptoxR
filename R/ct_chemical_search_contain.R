#' Get chemicals by substring value
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param word Substring of word to seach for. Values supplied as the 'word' parameter can include chemical name, DTXSID, DTXCID, CAS Registry Number (CASRN), or InChIKey.. Type: string
#' @param top Optional parameter (default: 0)
#' @param projection Optional parameter (default: chemicalsearchall)
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_contain(word = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_search_contain <- function(word, top = 0, projection = "chemicalsearchall") {
  params <- list("word" = word, "top" = top, "projection" = projection)
  result <- generic_request(
    "query" = params[["word"]],
    "endpoint" = "chemical/search/contain/",
    "method" = "GET",
    "batch_limit" = 1,
    "top" = params[["top"]],
    "projection" = params[["projection"]]
  )
  result
}
