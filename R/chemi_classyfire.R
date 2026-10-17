#' Get Classyfire classification for DTXSID
#'
#' @noMd
#' @description
#' This function retrieves Classyfire classifications for a given DTXSID using the EPA's cheminformatics API.
#' @param query A character vector of DTXSIDs to query. Accepts a vector: one request is sent per element and the results are combined.
#' @return A tibble of Classyfire classifications corresponding to the input DTXSIDs.
#' @export
#' @examples
#' \dontrun{
#' chemi_classyfire(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_classyfire <- function(query) {
  query <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  if (base::is.null(query)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("query" = query),
    list(
      query = list(
        type = "array",
        items = list(
          description = "A character vector of DTXSIDs to query.",
          "in" = "path",
          name = "dtxsid",
          type = "string"
        )
      )
    ),
    .api_validation$body_value,
    c(query = "path")
  )
  params <- base::list("query" = query)
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/api/amos/get_classification_for_dtxsid/{dtxsid}",
      "path_params" = base::list("dtxsid" = params[["query"]]),
      "query" = structure(list(), names = character(0)),
      "body" = NULL,
      "headers" = list(Accept = "application/json"),
      "server" = list(),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      "auth" = list(),
      "response_policy" = ".ct_tidy"
    )
    result
  }
  result <- .ct_request_each(
    function(chunk) {
      params["query"] <- base::list(chunk)
      send(params)
    },
    params[["query"]],
    1L,
    on_error = "drop"
  )
  kept <- base::attr(result, "failed", exact = TRUE)
  result <- run_hook("chemi_classyfire", "post_combine", base::list(result = result, params = params))
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "failed", exact = TRUE))) {
    base::attr(result, "failed") <- kept
  }
  result
}
