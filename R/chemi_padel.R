#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param x2d Optional parameter (default: TRUE)
#' @param x3d Optional parameter (default: FALSE)
#' @param fp Optional parameter (default: FALSE)
#' @param headers Optional parameter (default: FALSE)
#' @param timeout Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
chemi_padel <- function(smiles, x2d = TRUE, x3d = FALSE, fp = FALSE, headers = FALSE, timeout = NULL) {
  req_data <- run_hook(
    "chemi_padel",
    "pre_request",
    list(params = list(smiles = smiles, x2d = x2d, x3d = x3d, fp = fp, headers = headers, timeout = timeout))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("x2d" %in% names(req_data$params)) {
    x2d <- req_data$params[["x2d"]]
  }
  if ("x3d" %in% names(req_data$params)) {
    x3d <- req_data$params[["x3d"]]
  }
  if ("fp" %in% names(req_data$params)) {
    fp <- req_data$params[["fp"]]
  }
  if ("headers" %in% names(req_data$params)) {
    headers <- req_data$params[["headers"]]
  }
  if ("timeout" %in% names(req_data$params)) {
    timeout <- req_data$params[["timeout"]]
  }

  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(x2d)) {
    options[['2d']] <- x2d
  }
  if (!is.null(x3d)) {
    options[['3d']] <- x3d
  }
  if (!is.null(fp)) {
    options[['fp']] <- fp
  }
  if (!is.null(headers)) {
    options[['headers']] <- headers
  }
  if (!is.null(timeout)) {
    options[['timeout']] <- timeout
  }
  result <- generic_request(
    endpoint = "padel",
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


#' Padel
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
#' chemi_padel_bulk(query = c("DTXSID1024122", "DTXSID4020533", "DTXSID00205033"))
#' }
chemi_padel_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "padel",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}
