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
# Generated with specmill; do not edit by hand.
chemi_services_layout <- function(smiles) {
  params <- base::list("smiles" = smiles)
  result <- generic_request(
    "endpoint" = "services/layout",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("smiles" = params[["smiles"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
