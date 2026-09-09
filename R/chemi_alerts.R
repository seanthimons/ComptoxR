#' Alerts
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.alerts Optional parameter
#' @param request.options.resolve Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_alerts(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with apipak; do not edit by hand.
chemi_alerts <- function(
  query,
  idType = "AnyId",
  options = NULL,
  request.filesInfo = NULL,
  request.options.alerts = NULL,
  request.options.resolve = NULL
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "options" = options,
    "request.filesInfo" = request.filesInfo,
    "request.options.alerts" = request.options.alerts,
    "request.options.resolve" = request.options.resolve
  )
  state <- run_hook("chemi_alerts", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "alerts",
    "options" = local({
      .body <- Filter(Negate(is.null), list("options" = params[["options"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]],
    "request.filesInfo" = params[["request.filesInfo"]],
    "request.options.alerts" = params[["request.options.alerts"]],
    "request.options.resolve" = params[["request.options.resolve"]]
  )
  result
}
