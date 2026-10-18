#' Safety RQ codes
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param query Character vector of DTXSIDs, resolved before requesting RQ codes.
#' @return A tibble of available RQ codes with numeric rq_lbs and rq_kgs, or NULL when none are available.
#' @export
#' @examples
#' \dontrun{
#' chemi_safety_rqcodes(query = "DTXSID0020153")
#' }
# Generated with specmill; do not edit by hand.
chemi_safety_rqcodes <- function(query = NULL) {
  query <- base::get(
    ".ct_safety_sids",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  params <- base::c(base::list("query" = query), list(chemicals = NULL, idType = "DTXSID"))
  state <- run_hook("chemi_safety_rqcodes", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/safety/rqcodes",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = params[["chemicals"]],
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "safety/rqcodes"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result <- run_hook("chemi_safety_rqcodes", "post_response", base::list(result = result, params = params))
  result
}
