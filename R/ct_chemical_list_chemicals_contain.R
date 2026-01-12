#' Get DTXSIDs for list and containing substring in chemical name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param list List Name
#' @param word Chemical Name
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_contain(list = "40CFR1164")
#' }
ct_chemical_list_chemicals_contain <- function(list, word = NULL) {
  generic_request(
    query = list,
    endpoint = "chemical/list/chemicals/search/contain/",
    method = "GET",
    batch_limit = 1,
    path_params = c(word = word)
  )
}

