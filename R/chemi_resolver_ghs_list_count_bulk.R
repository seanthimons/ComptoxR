#' Count GHS list entries using a JSON request
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param body JSON object represented by a named list whose values are lists of string arrays.
#' @return A list of H-code count records returned by the resolver.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_ghs_list_count_bulk()
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_ghs_list_count_bulk <- function(body = structure(list(), names = character(0))) {
  params <- list("body" = body)
  result <- generic_chemi_request("endpoint" = "resolver/ghs-list-count", "body" = params[["body"]], "tidy" = FALSE)
  result
}
