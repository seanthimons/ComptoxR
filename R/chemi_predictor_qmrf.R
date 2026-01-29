#' Predictor Qmrf 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param qmrf_id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_qmrf(qmrf_id = "DTXSID7020182")
#' }
chemi_predictor_qmrf <- function(qmrf_id) {
  result <- generic_request(
    query = qmrf_id,
    endpoint = "predictor/qmrf/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


