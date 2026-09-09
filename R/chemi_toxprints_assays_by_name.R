#' Toxprints Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param name Primary query parameter. Type: string
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_assays_by_name(name = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_toxprints_assays_by_name <- function(name) {
  params <- list("name" = name)
  result <- generic_request(
    "query" = params[["name"]],
    "endpoint" = "toxprints/assays/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
