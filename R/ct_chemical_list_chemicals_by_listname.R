#' Get DTXSIDs by list
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param list Primary query parameter. Type: string
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_chemicals_by_listname(list = "40CFR1164")
#' }
ct_chemical_list_chemicals_by_listname <- function(list) {
  result <- generic_request(
    query = list,
    endpoint = "chemical/list/chemicals/search/by-listname/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


