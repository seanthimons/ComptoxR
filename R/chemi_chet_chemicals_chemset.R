#' List chemicals by library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param setid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_chemset(setid = "DTXSID7020182")
#' }
chemi_chet_chemicals_chemset <- function(setid = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(setid)) options[['setid']] <- setid
    result <- generic_request(
    endpoint = "chemicals/chemset",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}


