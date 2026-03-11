#' Download chemical list (GET)
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns binary data
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemical_DL()
#' }
chemi_chet_chemicals_chemical_DL <- function() {
  result <- generic_request(
    endpoint = "chemicals/chemical_DL",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


