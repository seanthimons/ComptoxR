#' Verify a DTXSID against DSSTOX
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Primary query parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_verify(dtxsid = "DTXSID7020182")
#' }
chemi_chet_chemicals_verify <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemicals/verify/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


