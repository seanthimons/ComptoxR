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
  generic_request(
    endpoint = "stdizer",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    workflow = workflow,
    smiles = smiles
  )
}




#' Stdizer
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param request Required parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_stdizer_bulk(request = "DTXSID7020182")
#' }
chemi_stdizer_bulk <- function(request) {
  # Collect optional parameters
  options <- list()
  if (!is.null(request)) options[['request']] <- request
  generic_chemi_request(
    query = request,
    endpoint = "stdizer",
    options = options,
    tidy = FALSE
  )
}


