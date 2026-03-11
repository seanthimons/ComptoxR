#' List all chemicals (legacy)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database_old()
#' }
chemi_chet_chemicals_database_old <- function() {
  result <- generic_request(
    endpoint = "chemicals/database-old",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


