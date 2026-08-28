#' Stdizer
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param workflow Required parameter
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer(workflow = "DTXSID7020182")
#' }
chemi_stdizer <- function(workflow, smiles) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer", "pre_request", list(params = list(`workflow` = workflow, `smiles` = smiles, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("workflow" %in% names(req_data$params)) {
    workflow <- req_data$params[["workflow"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(workflow)) options[['workflow']] <- workflow
  if (!is.null(smiles)) options[['smiles']] <- smiles
    result <- generic_request(
    endpoint = "stdizer",
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

#' Stdizer
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request.filesInfo Optional parameter
#' @param request.options.recordId Optional parameter
#' @param request.options.run Optional parameter
#' @param request.options.workflow Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_bulk(request.filesInfo = "DTXSID7020182")
#' }
chemi_stdizer_bulk <- function(request.filesInfo = NULL, request.options.recordId = NULL, request.options.run = NULL, request.options.workflow = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_stdizer_bulk", "pre_request", list(params = list(`request.filesInfo` = request.filesInfo, `request.options.recordId` = request.options.recordId, `request.options.run` = request.options.run, `request.options.workflow` = request.options.workflow, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("request.filesInfo" %in% names(req_data$params)) {
    request.filesInfo <- req_data$params[["request.filesInfo"]]
  }
  if ("request.options.recordId" %in% names(req_data$params)) {
    request.options.recordId <- req_data$params[["request.options.recordId"]]
  }
  if ("request.options.run" %in% names(req_data$params)) {
    request.options.run <- req_data$params[["request.options.run"]]
  }
  if ("request.options.workflow" %in% names(req_data$params)) {
    request.options.workflow <- req_data$params[["request.options.workflow"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
  if (!is.null(request.options.recordId)) options[['request.options.recordId']] <- request.options.recordId
  if (!is.null(request.options.run)) options[['request.options.run']] <- request.options.run
  if (!is.null(request.options.workflow)) options[['request.options.workflow']] <- request.options.workflow
    result <- generic_chemi_request(
    endpoint = "stdizer",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
