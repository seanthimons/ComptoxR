#' Returns a list of substances found by InChIKey.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_inchikey_first_block()
#' }
chemi_amos_inchikey_first_block <- function() {
  result <- generic_request(
    query = NULL,
    endpoint = "amos/inchikey_first_block_search/",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


