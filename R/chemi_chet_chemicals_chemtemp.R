#' Fetch temporary chemical details
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Primary query parameter. Type: string
#' @param value Optional parameter. Type: string
#' @return Returns a list with result object
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemtemp(type = "DTXSID7020182")
#' }
chemi_chet_chemicals_chemtemp <- function(type, value = NULL) {
  result <- generic_request(
    query = type,
    endpoint = "chemicals/chemtemp/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(value = value)
  )

  # Additional post-processing can be added here

  return(result)
}


