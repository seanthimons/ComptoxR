#' Resolver Getsimilaritymap
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param section Optional parameter
#' @param sort Logical value controlling API result ordering (default: FALSE)
#' @param hclust_method Hierarchical clustering method passed to stats::hclust()
#' @param format Output format: cluster result, long-form similarities, or raw API response
#' @return A cluster list containing a named similarity matrix and hclust object, long-form similarity tibble, or raw API response, selected by \code{format}
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritymap(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_getsimilaritymap <- function(
  query,
  idType = "AnyId",
  section = NULL,
  sort = FALSE,
  hclust_method = "complete",
  format = c("cluster", "long", "raw")
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "section" = section,
    "sort" = sort,
    "hclust_method" = hclust_method,
    "format" = format
  )
  state <- run_hook("chemi_resolver_getsimilaritymap", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "resolver/getsimilaritymap",
    "options" = local({
      .body <- Filter(Negate(is.null), list("section" = params[["section"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]],
    "sort" = if (!is.null(params$sort)) tolower(as.character(params$sort)) else NULL
  )
  result <- run_hook("chemi_resolver_getsimilaritymap", "post_response", list(result = result, params = params))
  result
}
