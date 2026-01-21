#' Detail
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param cas_rn Required parameter
#' @param uri Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_detail(cas_rn = "123-91-1")
#' }
cc_detail <- function(cas_rn, uri = NULL) {
  result <- generic_request(
    endpoint = "detail",
    method = "GET",
    batch_limit = 0,
    `cas_rn` = cas_rn,
    `uri` = uri
  )

  # Additional post-processing can be added here

  return(result)
}


