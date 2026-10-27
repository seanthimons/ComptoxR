#' Generate descriptors for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Chemical structures or resolvable identifiers
#' @param options Named list of additional dedicated Mordred options
#' @param headers Request descriptor headers
#' @param inchi Include InChI identifiers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_mordred_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_mordred_bulk <- function(chemicals, options = NULL, headers = NULL, inchi = NULL, output = c("wide", "raw")) {
  params <- base::list(
    "chemicals" = chemicals,
    "options" = options,
    "headers" = headers,
    "inchi" = inchi,
    "output" = output
  )
  state <- run_hook("chemi_mordred_bulk", "pre_request", base::list(params = params))
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  if (base::isTRUE(state$skip_request)) {
    result <- state$result
  } else {
    result <- .ct_request(
      "method" = "POST",
      "path" = state[["request"]][["endpoint"]],
      "path_params" = structure(list(), names = character(0)),
      "query" = structure(list(), names = character(0)),
      "body" = state[["request"]][["body"]],
      "headers" = base::list("Accept" = state[["request"]][["content_type"]]),
      "server" = base::list("url" = state[["request"]][["server"]]),
      "auth" = list(),
      "response_policy" = function(response, context, decode) {
        if (context$status >= 400L) {
          decode()
        }
        if (
          context$status >= 200L &&
            context$status < 300L &&
            grepl("^text/(csv|tab-separated-values|tsv)", state$request$content_type, ignore.case = TRUE)
        ) {
          observe_api_responses(list(response))
          value <- .ct_response_delimited(response, context, decode)
          return(if (!length(value)) list() else value)
        }
        context$endpoint <- state$request$endpoint
        .ct_chemi_result(response, context, decode, tidy = FALSE)
      },
      "request_controls" = list(preserve_errors = TRUE)
    )
  }
  state["result"] <- base::list(result)
  result <- run_hook("chemi_mordred_bulk", "post_response", state)
  result
}
