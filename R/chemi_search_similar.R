#' Search Similar
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param exportSmiles Optional parameter
#' @param exportMol Optional parameter
#' @param min Optional parameter
#' @param max Optional parameter
#' @param similarityType Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_search_similar(smiles = "DTXSID7020182")
#' }
chemi_search_similar <- function(
  smiles,
  exportSmiles = NULL,
  exportMol = NULL,
  min = NULL,
  max = NULL,
  similarityType = NULL
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_search_similar",
    "pre_request",
    list(
      params = list(
        `smiles` = smiles,
        `exportSmiles` = exportSmiles,
        `exportMol` = exportMol,
        `min` = min,
        `max` = max,
        `similarityType` = similarityType,
        `server` = server
      )
    )
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
  if ("min" %in% names(req_data$params)) {
    min <- req_data$params[["min"]]
  }
  if ("max" %in% names(req_data$params)) {
    max <- req_data$params[["max"]]
  }
  if ("similarityType" %in% names(req_data$params)) {
    similarityType <- req_data$params[["similarityType"]]
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
  if (!is.null(min)) {
    options[['min']] <- min
  }
  if (!is.null(max)) {
    options[['max']] <- max
  }
  if (!is.null(similarityType)) {
    options[['similarityType']] <- similarityType
  }
  result <- generic_request(
    endpoint = "search/similar",
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
