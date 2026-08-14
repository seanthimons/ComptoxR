#' Generate PFAS Atlas categories for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES string of the molecule
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas(smiles = "O=C(O)C(F)(F)C(F)(F)C(F)(F)C(F)(F)F")
#' }
chemi_pfas_atlas <- function(smiles) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_pfas_atlas", "pre_request", list(params = list(`smiles` = smiles, `server` = server)))
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
    endpoint = "pfas_atlas",
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

#' Generate PFAS Atlas categories for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Atlas POST format.
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(chemicals = "DTXSID1024122")
#' }
chemi_pfas_atlas_bulk <- function(chemicals = NULL, smiles = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_pfas_atlas_bulk",
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
    endpoint = "pfas_atlas",
    options = options,
    tidy = FALSE,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
