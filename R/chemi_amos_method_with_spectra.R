#' Returns information about a method with linked spectra, given an ID for either a spectrum or a method.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param search_type How to search the database.  Valid values are "spectrum" and "method".
#' @param internal_id Unique ID of the spectrum or method of interest.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_method_with_spectra(search_type = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_method_with_spectra <- function(search_type, internal_id = NULL) {
  params <- list("search_type" = search_type, "internal_id" = internal_id)
  result <- generic_request(
    "query" = params[["search_type"]],
    "endpoint" = "amos/method_with_spectra/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "path_params" = c("internal_id" = params[["internal_id"]])
  )
  result
}
