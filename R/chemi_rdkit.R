#' Generate descriptors for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles One SMILES string or resolvable chemical identifier
#' @param type Fingerprint type
#' @param radius ECFP radius
#' @param bits Number of fingerprint bits
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rdkit(smiles = "DTXSID7020182")
#' }
chemi_rdkit <- function(smiles, type = NULL, radius = NULL, bits = NULL, output = c("wide", "raw")) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_rdkit",
    "pre_request",
    list(
      params = list(
        `smiles` = smiles,
        `type` = type,
        `radius` = radius,
        `bits` = bits,
        `output` = output,
        `server` = server
      )
    )
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
  result <- run_hook("chemi_rdkit", "post_response", post_data)

  return(result)
}

#' Generate descriptors for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Chemical structures or resolvable identifiers
#' @param options Named list of additional dedicated RDKit options
#' @param type Fingerprint type
#' @param radius ECFP radius
#' @param bits Number of fingerprint bits
#' @param output Output contract: validated wide tibble or raw payload
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_rdkit_bulk(chemicals = "DTXSID1024122")
#' }
chemi_rdkit_bulk <- function(
  chemicals,
  options = NULL,
  type = NULL,
  radius = NULL,
  bits = NULL,
  output = c("wide", "raw")
) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_rdkit_bulk",
    "pre_request",
    list(
      params = list(
        `chemicals` = chemicals,
        `options` = options,
        `type` = type,
        `radius` = radius,
        `bits` = bits,
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
  result <- run_hook("chemi_rdkit_bulk", "post_response", post_data)

  return(result)
}
