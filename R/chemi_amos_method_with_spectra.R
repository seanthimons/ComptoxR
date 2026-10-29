#' Returns information about a method with linked spectra, given an ID for either a spectrum or a method
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param search_type How to search the database.  Valid values are "spectrum" and "method". Accepts a vector: one request is sent per element and the results are combined.
#' @param internal_id Unique ID of the spectrum or method of interest.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_method_with_spectra(search_type = "method", internal_id = "1")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_method_with_spectra <- function(search_type, internal_id) {
  search_type <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(search_type)
  if (base::is.null(search_type)) {
    base::stop("Required input: search_type")
  }
  if (base::is.null(internal_id)) {
    base::stop("Required input: internal_id")
  }
  .api_validation$parameter_values(
    base::list("search_type" = search_type, "internal_id" = internal_id),
    list(
      search_type = list(
        type = "array",
        items = list(
          description = "How to search the database.  Valid values are \"spectrum\" and \"method\".",
          "in" = "path",
          name = "search_type",
          type = "string"
        )
      ),
      internal_id = list(
        description = "Unique ID of the spectrum or method of interest.",
        "in" = "path",
        name = "internal_id",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(search_type = "path", internal_id = "path")
  )
  params <- base::list("search_type" = search_type, "internal_id" = internal_id)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/api/amos/method_with_spectra/{search_type}/{internal_id}",
      "path_params" = base::list("search_type" = params[["search_type"]], "internal_id" = params[["internal_id"]]),
      "query" = list(),
      "body" = NULL,
      "response_policy" = function(response, context, decode) {
        context$query <- params[["search_type"]]
        .ct_list(response, context, decode)
      },
      "server" = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["search_type"] <- base::list(chunk)
      send(params)
    },
    params[["search_type"]],
    1L,
    on_error = "drop"
  )
}
