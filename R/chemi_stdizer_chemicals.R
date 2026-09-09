#' Stdizer Chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param full Optional parameter
#' @param options Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_chemicals(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with apipak; do not edit by hand.
chemi_stdizer_chemicals <- function(query, idType = "AnyId", full = NULL, options = NULL) {
  params <- list("query" = query, "idType" = idType, "full" = full, "options" = options)
  state <- run_hook("chemi_stdizer_chemicals", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "stdizer/chemicals",
    "options" = local({
      .body <- Filter(Negate(is.null), list("full" = params[["full"]], "options" = params[["options"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]]
  )
  result
}
