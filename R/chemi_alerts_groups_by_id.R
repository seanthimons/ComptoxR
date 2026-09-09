#' Alerts Groups
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param id Primary query parameter. Type: string
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts_groups_by_id(id = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_alerts_groups_by_id <- function(id) {
  params <- list("id" = id)
  result <- generic_request(
    "query" = params[["id"]],
    "endpoint" = "alerts/groups/",
    "method" = "GET",
    "batch_limit" = 1,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE
  )
  result
}
