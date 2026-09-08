#' Returns lists of documents, each of which contain at least one substance of sufficient similarity to the searched
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param identifier_type Primary query parameter
#' @param identifier Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_similar_structures(identifier_type = "DTXSID7020182")
#' }
chemi_amos_get_similar_structures <- function(
  identifier_type,
  identifier = NULL
) {
  result <- generic_request(
    query = identifier_type,
    endpoint = "amos/get_similar_structures/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(identifier = identifier)
  )

  # Additional post-processing can be added here

  return(result)
}
