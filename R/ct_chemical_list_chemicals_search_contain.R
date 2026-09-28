#' Get DTXSIDs for list and containing substring in chemical name
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param list List Name. Type: string
#' @param word Chemical Name. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_search_contain(list = "40CFR1164")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_chemicals_search_contain <- function(list, word = NULL) {
  params <- base::list("list" = list, "word" = word)
  result <- generic_request(
    "query" = params[["list"]],
    "endpoint" = "chemical/list/chemicals/search/contain/",
    "method" = "GET",
    "batch_limit" = 1,
    "path_params" = base::c("word" = params[["word"]])
  )
  result
}
