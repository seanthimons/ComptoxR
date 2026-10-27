#' Padel
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Chemical structures or resolvable identifiers
#' @param x2d Calculate two-dimensional descriptors
#' @param x3d Calculate three-dimensional descriptors
#' @param fp Calculate fingerprints
#' @param headers Request descriptor headers
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_padel_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_padel_bulk <- function(
  query,
  x2d = TRUE,
  x3d = FALSE,
  fp = FALSE,
  headers = FALSE,
  timeout = NULL,
  output = c("wide", "raw")
) {
  params <- base::list(
    "query" = query,
    "x2d" = x2d,
    "x3d" = x3d,
    "fp" = fp,
    "headers" = headers,
    "timeout" = timeout,
    "output" = output
  )
  state <- run_hook("chemi_padel_bulk", "pre_request", base::list(params = params))
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
  result <- run_hook("chemi_padel_bulk", "post_response", state)
  result
}
