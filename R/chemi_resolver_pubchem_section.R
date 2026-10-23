#' chemi resolver pubchem section bulk
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param section Optional parameter
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_pubchem_section_bulk <- function(query, idType = "AnyId", section = NULL) {
  params <- base::c(base::list("query" = query, "idType" = idType, "section" = section), list(chemicals = NULL))
  state <- run_hook("chemi_resolver_pubchem_section_bulk", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/pubchem-section",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(),
    "body" = base::local({
      chemicals <- params[["chemicals"]]
      if (!is.list(chemicals) || !length(chemicals)) {
        chemicals <- lapply(.ct_toxprint_query(params[["query"]]), function(id) list(sid = id))
      }
      c(
        list(
          chemicals = lapply(chemicals, function(record) {
            if (is.list(record) && !is.null(record$chemical)) record$chemical else record
          })
        ),
        Filter(Negate(is.null), base::list(section = params[["section"]]))
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "resolver/pubchem-section"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
