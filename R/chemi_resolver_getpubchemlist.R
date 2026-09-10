#' Resolver Getpubchemlist
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
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getpubchemlist(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getpubchemlist <- function(query, idType = "AnyId", section = NULL, all_pages = TRUE, max_pages = 100) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "section" = section,
    "all_pages" = all_pages,
    "max_pages" = max_pages
  )
  state <- run_hook("chemi_resolver_getpubchemlist", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "resolver/getpubchemlist",
    "options" = local({
      .body <- Filter(Negate(is.null), list("section" = params[["section"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]],
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "page_size"
  )
  result
}
