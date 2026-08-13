#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param headers Request upstream descriptor headers (default: FALSE)
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest(smiles = "DTXSID7020182")
#' }
chemi_webtest <- function(smiles, headers = FALSE, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_webtest",
    "pre_request",
    list(params = list(`smiles` = smiles, `headers` = headers, `output` = output, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_request(
      endpoint = req_data$request$endpoint,
      method = req_data$request$method,
      batch_limit = 0,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      content_type = req_data$request$content_type,
      options = req_data$request$options
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_webtest", "post_response", post_data)

  return(result)
}

#' Webtest
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Chemical structures or resolvable identifiers
#' @param format Response format: JSON, CSV, or TSV. Options: JSON, CSV, TSV (default: JSON)
#' @param chemIdType Input identifier type
#' @param headers Request descriptor headers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_bulk(query = "DTXSID1024122")
#' }
chemi_webtest_bulk <- function(
  query,
  chemIdType = "AnyId",
  headers = FALSE,
  format = "JSON",
  output = c("wide", "raw")
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_webtest_bulk",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `chemIdType` = chemIdType,
        `headers` = headers,
        `format` = format,
        `output` = output,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    result <- req_data$result
  } else {
    result <- generic_chemi_request(
      endpoint = req_data$request$endpoint,
      server = req_data$request$server,
      auth = FALSE,
      tidy = FALSE,
      body = req_data$request$body,
      content_type = req_data$request$content_type
    )
  }

  post_data <- req_data
  post_data$result <- result
  result <- run_hook("chemi_webtest_bulk", "post_response", post_data)

  return(result)
}
