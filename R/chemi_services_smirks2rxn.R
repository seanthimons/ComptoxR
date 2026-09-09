#' Services Smirks2rxn
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smirks Required parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_smirks2rxn(smirks = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_services_smirks2rxn <- function(smirks) {
  params <- list("smirks" = smirks)
  result <- generic_request(
    "endpoint" = "services/smirks2rxn",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("smirks" = params[["smirks"]]))
      if (length(.body)) .body else list()
    })
  )
  result
}
