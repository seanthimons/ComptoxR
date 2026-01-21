#' Returns a list of methods and fact sheets, each of which contain at least one substance of sufficient similarity to the searched substance.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_similar_structures()
#' }
chemi_amos_get_similar_structures <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/get_similar_structures/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


