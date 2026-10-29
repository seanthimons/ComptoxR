#' Batch search reactions and chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids Required parameter
#' @param search_level Required parameter. Options: chemical, reaction
#' @return A list of decoded response records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_batchsearch(dtxsids = "DTXSID7020182", search_level = "chemical")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_batchsearch <- function(dtxsids, search_level) {
  params <- base::list("dtxsids" = function() dtxsids, "search_level" = function() search_level)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/chet/reaction/batchsearch",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      level <- params[["search_level"]]()
      ids <- .ct_toxprint_query(params[["dtxsids"]]())
      c(list(dtxsids = I(ids)), Filter(Negate(is.null), list(search_level = level)))
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "chet/reaction/batchsearch"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
