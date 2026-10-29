#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param inchikey InChIKey to search by. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_ms_ready_methods <- function(inchikey) {
  inchikey <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(inchikey)
  if (base::is.null(inchikey)) {
    base::stop("Required input: inchikey")
  }
  .api_validation$parameter_values(
    base::list("inchikey" = inchikey),
    list(
      inchikey = list(
        type = "array",
        items = list(description = "InChIKey to search by.", "in" = "path", name = "inchikey", type = "string")
      )
    ),
    .api_validation$body_value,
    c(inchikey = "path")
  )
  params <- base::list("inchikey" = inchikey)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/get_ms_ready_methods/{inchikey}",
      path_params = base::list("inchikey" = params[["inchikey"]]),
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
      params["inchikey"] <- base::list(chunk)
      send(params)
    },
    params[["inchikey"]],
    1L,
    on_error = "drop"
  )
}
