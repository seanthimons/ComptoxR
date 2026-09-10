#' Hazard
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param full Optional parameter (default: TRUE)
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_hazard(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_hazard <- function(query, full = TRUE, format = c("compact", "tidy", "raw")) {
  params <- list("query" = query, "full" = full, "format" = format)
  result <- generic_request(
    "endpoint" = "hazard",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("query" = params[["query"]], "full" = params[["full"]]))
      if (length(.body)) .body else list()
    })
  )
  result <- run_hook("chemi_hazard", "post_response", list(result = result, params = params))
  result
}

#' Hazard
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param empty Optional parameter
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.analogsSearchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, TOXPRINTS, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param request.options.cts Optional parameter
#' @param request.options.minSimilarity Optional parameter
#' @param request.options.noRecords Optional parameter
#' @param request.options.usePredictions Optional parameter
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_hazard_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with specmill; do not edit by hand.
chemi_hazard_bulk <- function(
  query,
  idType = "AnyId",
  empty = NULL,
  options = NULL,
  request.filesInfo = NULL,
  request.options.analogsSearchType = NULL,
  request.options.cts = NULL,
  request.options.minSimilarity = NULL,
  request.options.noRecords = NULL,
  request.options.usePredictions = NULL,
  format = c("compact", "tidy", "raw")
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "empty" = empty,
    "options" = options,
    "request.filesInfo" = request.filesInfo,
    "request.options.analogsSearchType" = request.options.analogsSearchType,
    "request.options.cts" = request.options.cts,
    "request.options.minSimilarity" = request.options.minSimilarity,
    "request.options.noRecords" = request.options.noRecords,
    "request.options.usePredictions" = request.options.usePredictions,
    "format" = format
  )
  state <- run_hook("chemi_hazard_bulk", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "hazard",
    "options" = local({
      .body <- Filter(Negate(is.null), list("empty" = params[["empty"]], "options" = params[["options"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]],
    "request.filesInfo" = params[["request.filesInfo"]],
    "request.options.analogsSearchType" = params[["request.options.analogsSearchType"]],
    "request.options.cts" = params[["request.options.cts"]],
    "request.options.minSimilarity" = params[["request.options.minSimilarity"]],
    "request.options.noRecords" = params[["request.options.noRecords"]],
    "request.options.usePredictions" = params[["request.options.usePredictions"]]
  )
  result <- run_hook("chemi_hazard_bulk", "post_response", list(result = result, params = params))
  result
}
