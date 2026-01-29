#' Predictor Report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param model_id Required parameter
#' @param smiles Required parameter
#' @param format Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_report(model_id = "DTXSID7020182")
#' }
chemi_predictor_report <- function(model_id, smiles, format = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(model_id)) options[['model_id']] <- model_id
  if (!is.null(smiles)) options[['smiles']] <- smiles
  if (!is.null(format)) options[['format']] <- format
    result <- generic_request(
    endpoint = "predictor/report",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


