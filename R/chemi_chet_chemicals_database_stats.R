#' Chemical stats and library names
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param total total
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_stats()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_database_stats <- function(total = NULL) {
  .api_validation$parameter_values(
    base::list("total" = total),
    list(total = list(type = "string")),
    .api_validation$body_value,
    c(total = "query")
  )
  params <- base::list("total" = total)
  if (base::is.character(params[["total"]]) && base::any(!base::nzchar(params[["total"]]))) {
    base::stop("Empty query parameter: total")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/database/stats",
    path_params = base::list(),
    query = base::list("total" = params[["total"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
