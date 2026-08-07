#' Generate an ARN category for one molecule
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles SMILES to generate groups for
#' @param model Model to use for group prediction. Options: RF, NN (default: RF)
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
chemi_arn_cats <- function(smiles, model = "RF") {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_arn_cats",
    "pre_request",
    list(params = list(`smiles` = smiles, `model` = model, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("model" %in% names(req_data$params)) {
    model <- req_data$params[["model"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(model)) {
    options[['model']] <- model
  }
  result <- generic_request(
    endpoint = "arn_cats",
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


#' Generate groups for multiple molecules
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Array of objects with optional id and smiles, or an array of SMILES strings for backward compatibility.
#' @param model Optional parameter. Options: RF, NN (default: RF)
#' @param smiles Array of SMILES strings, same input style as amnb_nate.
#' @return Returns a list with result object
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_arn_cats_bulk(chemicals = "DTXSID1024122")
#' }
chemi_arn_cats_bulk <- function(chemicals = NULL, model = "RF", smiles = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_arn_cats_bulk",
    "pre_request",
    list(params = list(`chemicals` = chemicals, `model` = model, `smiles` = smiles, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("model" %in% names(req_data$params)) {
    model <- req_data$params[["model"]]
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Build options list for additional parameters
  options <- list()
  if (!is.null(model)) {
    options$model <- model
  }
  if (!is.null(smiles)) {
    options$smiles <- smiles
  }
  result <- generic_chemi_request(
    server = server,
    query = chemicals,
    endpoint = "arn_cats",
    options = options,
    tidy = FALSE,
    chemicals = chemicals
  )

  # Additional post-processing can be added here

  return(result)
}
