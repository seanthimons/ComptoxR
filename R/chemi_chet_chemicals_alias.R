#' Fetch aliases for a chemical
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_alias(dtxsid = "DTXSID7020182")
#' }
chemi_chet_chemicals_alias <- function(dtxsid = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(dtxsid)) options[['dtxsid']] <- dtxsid
    result <- generic_request(
    endpoint = "chemicals/alias",
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


