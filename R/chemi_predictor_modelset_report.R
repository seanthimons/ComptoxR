#' Predictor Modelset Report 
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param report_id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_modelset_report(report_id = "DTXSID7020182")
#' }
chemi_predictor_modelset_report <- function(report_id) {
  result <- generic_request(
    query = report_id,
    endpoint = "predictor/modelset_report/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


