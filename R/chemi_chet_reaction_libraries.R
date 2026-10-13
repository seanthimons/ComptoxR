#' List reaction libraries
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_libraries()
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_libraries <- function() {
  params <- base::list()
  result <- .ct_request(
    method = "GET",
    path = "/reaction/libraries",
    path_params = base::list(),
    query = base::list(),
    body = NULL,
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
