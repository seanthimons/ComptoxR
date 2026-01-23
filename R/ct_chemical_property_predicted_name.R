#' Get all predicted property options
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_property_predicted_name()
#' }
ct_chemical_property_predicted_name <- function() {
  result <- generic_request(
    endpoint = "chemical/property/predicted/name",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


