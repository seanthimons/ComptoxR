#' Resolver Pubchem Section
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param section Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_pubchem_section(query = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_pubchem_section <- function(query, idType = "AnyId", section = NULL) {
  params <- list("query" = query, "idType" = idType, "section" = section)
  result <- generic_request(
    "endpoint" = "resolver/pubchem-section",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("query" = params[["query"]], "idType" = params[["idType"]], "section" = params[["section"]])
      )
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Resolver Pubchem Section
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
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_pubchem_section_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_pubchem_section_bulk <- function(query, idType = "AnyId", section = NULL) {
  params <- list("query" = query, "idType" = idType, "section" = section)
  state <- run_hook("chemi_resolver_pubchem_section_bulk", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "resolver/pubchem-section",
    "options" = local({
      .body <- Filter(Negate(is.null), list("section" = params[["section"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]]
  )
  result
}
