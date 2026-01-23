#' Get data for a batch of DTXSID(s)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_skin_eye()
#' }
ct_hazard_skin_eye <- function() {
  result <- generic_request(
    endpoint = "hazard/skin-eye/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


