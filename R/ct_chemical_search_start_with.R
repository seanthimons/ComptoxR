#' Get chemicals by starting value
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param word Starting string of word to search for. Values supplied as the 'word' parameter can include chemical name, DTXSID, DTXCID, CAS Registry Number (CASRN), or InChIKey.. Type: string
#' @param top Optional parameter (default: 500)
#' @return Returns a scalar value
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_start_with(word = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_search_start_with <- function(word, top = 500) {
  params <- list("word" = word, "top" = top)
  result <- generic_request(
    "query" = params[["word"]],
    "endpoint" = "chemical/search/start-with/",
    "method" = "GET",
    "batch_limit" = 1,
    "top" = params[["top"]]
  )
  result
}
