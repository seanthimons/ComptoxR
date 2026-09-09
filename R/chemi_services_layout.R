#' Services Layout
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_layout(smiles = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_services_layout <- function(smiles) {
  params <- list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "services/layout",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("smiles" = params[["smiles"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
