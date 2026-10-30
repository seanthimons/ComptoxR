#' Returns general information about a record by ID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id Unique ID of the record of interest. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_get_info_by_id(internal_id = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_get_info_by_id <- function(internal_id) {
  internal_id <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(internal_id)
  if (base::is.null(internal_id)) {
    base::stop("Required input: internal_id")
  }
  .api_validation$parameter_values(
    base::list("internal_id" = internal_id),
    list(
      internal_id = list(
        type = "array",
        items = list(
          description = "Unique ID of the record of interest.",
          "in" = "path",
          name = "internal_id",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(internal_id = "path")
  )
  params <- base::list("internal_id" = internal_id)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/api/amos/get_info_by_id/{internal_id}",
      "path_params" = base::list("internal_id" = params[["internal_id"]]),
      "query" = structure(list(), names = character(0)),
      "body" = NULL,
      "headers" = list(Accept = "application/json"),
      "server" = list(url = "https://hcd.rtpnc.epa.gov"),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        .ct_collect_response(response, context, decode, length(internal_id), "amos/get_info_by_id/")
      }
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["internal_id"] <- base::list(chunk)
      send(params)
    },
    params[["internal_id"]],
    1L,
    on_error = list(single = "stop", multiple = "drop"),
    warning = FALSE
  )
  base::attr(result, "failed") <- NULL
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  base::get(
    "format_legacy_list_result",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = FALSE
  )(base::list(result = result, params = params))
}
