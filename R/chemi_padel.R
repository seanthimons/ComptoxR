#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param x2d Calculate two-dimensional descriptors (default: TRUE)
#' @param x3d Calculate three-dimensional descriptors (default: FALSE)
#' @param fp Calculate fingerprints (default: FALSE)
#' @param headers Request upstream descriptor headers (default: FALSE)
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel(smiles = "DTXSID7020182")
#' }
chemi_padel <- function(smiles, x2d = TRUE, x3d = FALSE, fp = FALSE, headers = FALSE, timeout = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_padel", "pre_request", list(params = list(`smiles` = smiles, `x2d` = x2d, `x3d` = x3d, `fp` = fp, `headers` = headers, `timeout` = timeout, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_padel", "post_response", post_data)

  return(result)
}

#' Padel
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Chemical structures or resolvable identifiers
#' @param x2d Calculate two-dimensional descriptors
#' @param x3d Calculate three-dimensional descriptors
#' @param fp Calculate fingerprints
#' @param headers Request descriptor headers
#' @param timeout Optional upstream calculation timeout
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_padel_bulk(query = "DTXSID1024122")
#' }
chemi_padel_bulk <- function(query, x2d = TRUE, x3d = FALSE, fp = FALSE, headers = FALSE, timeout = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_padel_bulk", "pre_request", list(params = list(`query` = query, `x2d` = x2d, `x3d` = x3d, `fp` = fp, `headers` = headers, `timeout` = timeout, `output` = output, `server` = server)))
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
  result <- run_hook("chemi_padel_bulk", "post_response", post_data)

  return(result)
}
