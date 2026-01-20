#' Stdizer
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param workflow Required parameter
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer(workflow = "DTXSID7020182")
#' }
chemi_stdizer <- function(workflow, smiles) {
  # Collect optional parameters
  options <- list()
  if (!is.null(workflow)) options[['workflow']] <- workflow
  if (!is.null(smiles)) options[['smiles']] <- smiles
    result <- generic_request(
    query = NULL,
    endpoint = "stdizer",
    method = "GET",
    batch_limit = NULL,
    server = "chemi_burl",
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
#' @param request.filesInfo Required parameter
#' @param request.options.workflow Optional parameter
#' @param request.options.run Optional parameter
#' @param request.options.recordId Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_bulk(request.filesInfo = "DTXSID7020182")
#' }
chemi_stdizer_bulk <- function(request.filesInfo, request.options.workflow = NULL, request.options.run = NULL, request.options.recordId = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request.filesInfo)) options[['request.filesInfo']] <- request.filesInfo
  if (!is.null(request.options.workflow)) options[['request.options.workflow']] <- request.options.workflow
  if (!is.null(request.options.run)) options[['request.options.run']] <- request.options.run
  if (!is.null(request.options.recordId)) options[['request.options.recordId']] <- request.options.recordId
    result <- generic_chemi_request(
    query = NULL,
    endpoint = "stdizer",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


