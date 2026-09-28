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
  # Collect optional parameters
  options <- list()
  if (!is.null(workflow)) {
    options[['workflow']] <- workflow
  }
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  result <- generic_request(
    endpoint = "stdizer",
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
