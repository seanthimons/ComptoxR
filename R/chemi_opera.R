#' Opera
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @param format Format to return predictions in (json, csv, xlsx) (default: json)
#' @param standardize Standardize chemical before calculating predictions (default: FALSE)
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_opera(smiles = "DTXSID7020182")
#' }
chemi_opera <- function(smiles, format = "json", standardize = FALSE) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_opera",
    "pre_request",
    list(params = list(`smiles` = smiles, `format` = format, `standardize` = standardize, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("standardize" %in% names(req_data$params)) {
    standardize <- req_data$params[["standardize"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(format)) {
    options[['format']] <- format
  }
  if (!is.null(standardize)) {
    options[['standardize']] <- standardize
  }
  result <- generic_request(
    endpoint = "opera",
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
