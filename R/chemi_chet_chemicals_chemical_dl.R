#' Download the CheT chemical list
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Required JSON object body. Use stats::setNames(list(), character()) for an empty object. GET bodies have undefined interoperability semantics in OpenAPI 3.1 and may be rejected by intermediaries.
#' @param body Request body.
#' @return CSV text for text/csv responses, or raw bytes for application/octet-stream.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_chemical_dl <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(body, list(additionalProperties = TRUE, type = "object")),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "GET",
    path = "/chemicals/chemical_DL",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
    auth = list()
  )
  result
}
