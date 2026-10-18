#' Returns general information about a record by ID.
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
      method = "GET",
      path = "/api/amos/get_info_by_id/{internal_id}",
      path_params = base::list("internal_id" = params[["internal_id"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_http_policy_chemi_amos_get_info_by_id",
      server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      auth = list()
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
    warning = base::get(
      ".ct_batch_http_warning",
      envir = base::parent.env(base::environment()),
      mode = "function",
      inherits = FALSE
    )
  )
  base::attr(result, "failed") <- NULL
  kept <- base::attr(result, "failed", exact = TRUE)
  result <- run_hook("chemi_amos_get_info_by_id", "post_combine", base::list(result = result, params = params))
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "failed", exact = TRUE))) {
    base::attr(result, "failed") <- kept
  }
  result
}
