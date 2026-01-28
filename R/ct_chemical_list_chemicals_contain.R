#' Get DTXSIDs for list and containing substring in chemical name
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param list List Name. Type: string
#' @param word Chemical Name. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_contain(list = "40CFR1164")
#' }
ct_chemical_list_chemicals_contain <- function(list, word = NULL) {
  result <- generic_request(
    query = list,
    endpoint = "chemical/list/chemicals/search/contain/",
    method = "GET",
    batch_limit = 1,
    path_params = c(word = word)
  )

  # Additional post-processing can be added here

  return(result)
}


