#' Get all list types
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_type()
#' }
ct_chemical_list_type <- function() {
  result <- generic_request(
    endpoint = "chemical/list/type",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


