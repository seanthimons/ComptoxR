#' Generate NCC categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate NCC categories for
#' @param logp Octanol-water partition coefficient
#' @param ws Water solubility (mg/L)
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats(smiles = "DTXSID7020182")
#' }
chemi_ncc_cats <- function(smiles, logp = NULL, ws = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_ncc_cats",
    "pre_request",
    list(params = list(`smiles` = smiles, `logp` = logp, `ws` = ws, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("logp" %in% names(req_data$params)) {
    logp <- req_data$params[["logp"]]
  }
  if ("ws" %in% names(req_data$params)) {
    ws <- req_data$params[["ws"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(logp)) {
    options[['logp']] <- logp
  }
  if (!is.null(ws)) {
    options[['ws']] <- ws
  }
  result <- generic_request(
    endpoint = "ncc_cats",
    method = "GET",
    batch_limit = 0,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    options = options
  )

  # Additional post-processing can be added here

  return(result)
}

#' Generate NCC categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Array of input chemicals with optional id, smiles, logp, and ws. Missing smiles are returned as item-level errors.
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(chemicals = "DTXSID1024122")
#' }
chemi_ncc_cats_bulk <- function(chemicals = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_ncc_cats_bulk",
    "pre_request",
    list(params = list(`chemicals` = chemicals, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "ncc_cats",
    wrap = FALSE,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
