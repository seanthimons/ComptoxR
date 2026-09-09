#' Suggest CheT chemicals for look-ahead search
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query User-entered chemical name, DTXSID, CASRN, or resolver-supported identifier.
#' @param limit Optional parameter (default: 8)
#' @param only_in_reactions If true, only suggest chemicals that participate in at least one reaction. (default: true)
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_suggest(query = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_chemicals_suggest <- function(query, limit = 8, only_in_reactions = "true") {
  params <- list("query" = query, "limit" = limit, "only_in_reactions" = only_in_reactions)
  result <- generic_request(
    "endpoint" = "chemicals/suggest",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "query" = params[["query"]],
          "limit" = params[["limit"]],
          "only_in_reactions" = params[["only_in_reactions"]]
        )
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
