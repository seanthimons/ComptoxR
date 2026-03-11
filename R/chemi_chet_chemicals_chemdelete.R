#' Delete a chemical (GET)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a character string
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemdelete()
#' }
chemi_chet_chemicals_chemdelete <- function() {
  result <- generic_request(
    endpoint = "chemicals/chemdelete",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    content_type = "text/plain"
  )

  # Additional post-processing can be added here

  return(result)
}


