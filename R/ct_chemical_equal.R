#' Get chemicals for a batch of exact values
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_equal()
#' }
ct_chemical_equal <- function() {
  result <- generic_request(
    endpoint = "chemical/search/equal/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


