#' chemi hazard
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param full Optional parameter (default: TRUE)
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard <- function(query, full = TRUE, format = c("compact", "tidy", "raw")) {
  params <- base::list("query" = query, "full" = full, "format" = format)
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/hazard",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("query" = params[["query"]], "full" = params[["full"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      .ct_static_json_result(response, context, decode, "hazard")
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result <- run_hook("chemi_hazard", "post_response", base::list(result = result, params = params))
  result
}
