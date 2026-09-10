#' Resolver Mesh
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @param idType Optional parameter. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param fuzzy Optional parameter. Options: Not, Anywhere, Start, Word, CloseSyntactic, CloseSemantic (default: Not)
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_mesh(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_mesh <- function(query, idType = "AnyId", fuzzy = "Not") {
  params <- list("query" = query, "idType" = idType, "fuzzy" = fuzzy)
  result <- generic_request(
    "endpoint" = "resolver/mesh",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("query" = params[["query"]], "idType" = params[["idType"]], "fuzzy" = params[["fuzzy"]])
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
