#' Get data for a batch of DTXSID(s).
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_hazard_toxval()
#' }
ct_hazard_toxval <- function() {
  result <- generic_request(
    endpoint = "hazard/toxval/search/by-dtxsid/",
    method = "POST",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


