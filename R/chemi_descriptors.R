#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param type Descriptor engine: padel, rdkit, mordred, or webtest
#' @param headers Request upstream descriptor headers (default: FALSE)
#' @param format Response format: JSON, CSV, or TSV. Options: JSON, CSV, TSV (default: JSON)
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors(smiles = "DTXSID7020182")
#' }
chemi_descriptors <- function(smiles, type, headers = FALSE, format = "JSON", timeout = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_descriptors", "pre_request", list(params = list(`smiles` = smiles, `type` = type, `headers` = headers, `format` = format, `timeout` = timeout, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_descriptors", "post_response", post_data)

  return(result)
}

#' Descriptors
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Chemical identifiers or structures
#' @param type Descriptor engine: padel, rdkit, mordred, or webtest
#' @param chemIdType Input identifier type. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default: AnyId)
#' @param format Response format: JSON, CSV, or TSV. Options: JSON, CSV, TSV (default: JSON)
#' @param headers Request descriptor headers
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_descriptors_bulk(query = "DTXSID1024122")
#' }
chemi_descriptors_bulk <- function(query, type, chemIdType = "AnyId", headers = FALSE, format = "JSON", timeout = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_descriptors_bulk", "pre_request", list(params = list(`query` = query, `type` = type, `chemIdType` = chemIdType, `headers` = headers, `format` = format, `timeout` = timeout, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_descriptors_bulk", "post_response", post_data)

  return(result)
}
