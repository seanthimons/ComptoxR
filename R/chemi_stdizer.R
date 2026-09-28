#' Stdizer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param workflow Required parameter
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer(workflow = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer <- function(workflow, smiles) {
  params <- base::list("workflow" = workflow, "smiles" = smiles)
  result <- generic_request(
    "endpoint" = "stdizer",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(
        base::Negate(base::is.null),
        base::list("workflow" = params[["workflow"]], "smiles" = params[["smiles"]])
      )
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
