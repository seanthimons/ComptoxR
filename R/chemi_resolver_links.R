#' Resolver Links
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_links(query = "DTXSID7020182")
#' }
chemi_resolver_links <- function(query, idType = "AnyId", fuzzy = "Not") {
  generic_request(
    endpoint = "resolver/links",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    query = query,
    idType = idType,
    fuzzy = fuzzy
  )
}


