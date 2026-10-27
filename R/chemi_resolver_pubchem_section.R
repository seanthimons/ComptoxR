#' Resolver Pubchem Section
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param section Optional parameter
#' @return A list of decoded response records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_pubchem_section(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_pubchem_section <- function(query, idType = "AnyId", section = NULL) {
  params <- base::list("query" = query, "idType" = idType, "section" = section)
  result <- .ct_request(
    "method" = "GET",
    "path" = "/api/resolver/pubchem-section",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("query" = params[["query"]], "idType" = params[["idType"]], "section" = params[["section"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      .ct_static_json_result(response, context, decode, "resolver/pubchem-section")
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
