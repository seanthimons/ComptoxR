#' chemi amos get similar structures
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param identifier_type identifier_type Accepts a vector: one request is sent per element and the results are combined.
#' @param identifier identifier
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_similar_structures(identifier_type = "DTXSID", identifier = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_similar_structures <- function(identifier_type, identifier) {
  identifier_type <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(identifier_type)
  if (base::is.null(identifier_type)) {
    base::stop("Required input: identifier_type")
  }
  if (base::is.null(identifier)) {
    base::stop("Required input: identifier")
  }
  .api_validation$parameter_values(
    base::list("identifier_type" = identifier_type, "identifier" = identifier),
    list(
      identifier_type = list(type = "array", items = list(name = "identifier_type", "in" = "path", type = "string")),
      identifier = list(name = "identifier", "in" = "path", type = "string")
    ),
    .api_validation$body_value,
    c(identifier_type = "path", identifier = "path")
  )
  params <- base::list("identifier_type" = identifier_type, "identifier" = identifier)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/get_similar_structures/{identifier_type}/{identifier}",
      path_params = base::list("identifier_type" = params[["identifier_type"]], "identifier" = params[["identifier"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["identifier_type"] <- base::list(chunk)
      send(params)
    },
    params[["identifier_type"]],
    1L,
    on_error = "drop"
  )
}
