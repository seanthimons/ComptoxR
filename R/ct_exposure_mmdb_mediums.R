#' Get all Media options
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_mediums()
#' }
ct_exposure_mmdb_mediums <- function() {
  result <- generic_request(
    endpoint = "exposure/mmdb/mediums",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


