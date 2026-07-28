#' Predictor Report
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param model_id Required parameter
#' @param smiles Required parameter
#' @param format Optional parameter
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_predictor_report(model_id = "DTXSID7020182")
#' }
chemi_predictor_report <- function(model_id, smiles, format = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_predictor_report",
    "pre_request",
    list(params = list(`model_id` = model_id, `smiles` = smiles, `format` = format, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("model_id" %in% names(req_data$params)) {
    model_id <- req_data$params[["model_id"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(model_id)) {
    options[['model_id']] <- model_id
  }
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(format)) {
    options[['format']] <- format
  }
  result <- generic_request(
    endpoint = "predictor/report",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}
