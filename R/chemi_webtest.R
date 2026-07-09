#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param headers Optional parameter (default: FALSE)
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
chemi_webtest <- function(smiles, headers = FALSE) {
  req_data <- run_hook("chemi_webtest", "pre_request", list(params = list(smiles = smiles, headers = headers)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("headers" %in% names(req_data$params)) {
    headers <- req_data$params[["headers"]]
  }

  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(headers)) {
    options[['headers']] <- headers
  }
  result <- generic_request(
    endpoint = "webtest",
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


#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_webtest_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "webtest",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}
