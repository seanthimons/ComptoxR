#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param headers Request upstream descriptor headers
#' @param inchi Include InChI identifiers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_mordred(smiles = "DTXSID7020182")
#' }
chemi_mordred <- function(smiles, headers = NULL, inchi = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_mordred", "pre_request", list(params = list(`smiles` = smiles, `headers` = headers, `inchi` = inchi, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_mordred", "post_response", post_data)

  return(result)
}

#' Generate descriptors for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Chemical structures or resolvable identifiers
#' @param options Named list of additional dedicated Mordred options
#' @param headers Request descriptor headers
#' @param inchi Include InChI identifiers
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_mordred_bulk(chemicals = "DTXSID1024122")
#' }
chemi_mordred_bulk <- function(chemicals, options = NULL, headers = NULL, inchi = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_mordred_bulk", "pre_request", list(params = list(`chemicals` = chemicals, `options` = options, `headers` = headers, `inchi` = inchi, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_mordred_bulk", "post_response", post_data)

  return(result)
}
