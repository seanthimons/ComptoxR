#' Amnb Nate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate predictions for
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amnb_nate(smiles = "DTXSID7020182")
#' }
chemi_amnb_nate <- function(smiles) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_amnb_nate", "pre_request", list(params = list(`smiles` = smiles, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  result <- generic_request(
    endpoint = "amnb_nate",
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

#' Generate predictions for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Optional parameter
#' @param smiles Optional parameter
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amnb_nate_bulk(chemicals = "DTXSID1024122")
#' }
chemi_amnb_nate_bulk <- function(chemicals = NULL, smiles = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amnb_nate_bulk",
    "pre_request",
    list(params = list(`chemicals` = chemicals, `smiles` = smiles, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    query = chemicals,
    endpoint = "amnb_nate",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
