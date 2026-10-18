#' View error page with filter (POST)
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Native canonical contract. Session and authorization behavior is server-defined; this function does not manage credentials or session state.
#' @param showhide showhide
#' @return Decoded JSON, text, or raw bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_auth_errorpage_showhide_post <- function(showhide) {
  if (base::is.null(showhide)) {
    base::stop("Required input: showhide")
  }
  .api_validation$parameter_values(
    base::list("showhide" = showhide),
    list(showhide = list(type = "string")),
    .api_validation$body_value,
    c(showhide = "path")
  )
  params <- base::list("showhide" = showhide)
  result <- .ct_request(
    method = "POST",
    path = "/auth/errorpage/{showhide}",
    path_params = base::list("showhide" = params[["showhide"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
