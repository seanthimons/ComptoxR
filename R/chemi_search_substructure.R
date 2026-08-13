#' Search Substructure
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_substructure(smiles = "DTXSID7020182")
#' }
chemi_search_substructure <- function(smiles, exportSmiles = NULL, exportMol = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_search_substructure",
    "pre_request",
    list(params = list(`smiles` = smiles, `exportSmiles` = exportSmiles, `exportMol` = exportMol, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("exportSmiles" %in% names(req_data$params)) {
    exportSmiles <- req_data$params[["exportSmiles"]]
  }
  if ("exportMol" %in% names(req_data$params)) {
    exportMol <- req_data$params[["exportMol"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(exportSmiles)) {
    options[['exportSmiles']] <- exportSmiles
  }
  if (!is.null(exportMol)) {
    options[['exportMol']] <- exportMol
  }
  result <- generic_request(
    endpoint = "search/substructure",
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
