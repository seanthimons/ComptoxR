#' Fetch a single chemical
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
#' chemi_chet_chemicals_singlechemical(dtxsid = "DTXSID7020182")
#' }
chemi_chet_chemicals_singlechemical <- function(dtxsid = NULL) {
  # Collect optional parameters
  options <- list()
  if (!is.null(dtxsid)) options[['dtxsid']] <- dtxsid
    result <- generic_request(
    endpoint = "chemicals/singlechemical",
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


