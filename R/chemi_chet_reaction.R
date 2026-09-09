#' Search reactions and chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Optional parameter
#' @param searchType Optional parameter
#' @param substringTF Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction(query = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_reaction <- function(query = NULL, searchType = NULL, substringTF = NULL) {
  params <- list("query" = query, "searchType" = searchType, "substringTF" = substringTF)
  result <- generic_request(
    "endpoint" = "reaction/search",
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
          "searchType" = params[["searchType"]],
          "substringTF" = params[["substringTF"]]
        )
      )
      if (length(.body)) .body else list()
    })
  )
  result
}
