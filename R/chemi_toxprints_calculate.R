#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param labels Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate(smiles = "DTXSID7020182")
#' }
chemi_toxprints_calculate <- function(smiles, labels = FALSE, profile = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_calculate",
    "pre_request",
    list(params = list(`smiles` = smiles, `labels` = labels, `profile` = profile, `server` = server))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("labels" %in% names(req_data$params)) {
    labels <- req_data$params[["labels"]]
  }
  if ("profile" %in% names(req_data$params)) {
    profile <- req_data$params[["profile"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(labels)) {
    options[['labels']] <- labels
  }
  if (!is.null(profile)) {
    options[['profile']] <- profile
  }
  result <- generic_request(
    endpoint = "toxprints/calculate",
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

#' Toxprints Calculate
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param labels Optional parameter
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.labels Optional parameter
#' @param request.options.OR Optional parameter
#' @param request.options.profile Optional parameter
#' @param request.options.PV1 Optional parameter
#' @param request.options.TP Optional parameter
#' @param request.resolve Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_toxprints_calculate_bulk <- function(
  query,
  idType = "AnyId",
  labels = NULL,
  options = NULL,
  request.filesInfo = NULL,
  request.labels = NULL,
  request.options.OR = NULL,
  request.options.profile = NULL,
  request.options.PV1 = NULL,
  request.options.TP = NULL,
  request.resolve = NULL
) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_toxprints_calculate_bulk",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `idType` = idType,
        `labels` = labels,
        `options` = options,
        `request.filesInfo` = request.filesInfo,
        `request.labels` = request.labels,
        `request.options.OR` = request.options.OR,
        `request.options.profile` = request.options.profile,
        `request.options.PV1` = request.options.PV1,
        `request.options.TP` = request.options.TP,
        `request.resolve` = request.resolve,
        `chemicals` = chemicals,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("labels" %in% names(req_data$params)) {
    labels <- req_data$params[["labels"]]
  }
  if ("options" %in% names(req_data$params)) {
    options <- req_data$params[["options"]]
  }
  if ("request.filesInfo" %in% names(req_data$params)) {
    request.filesInfo <- req_data$params[["request.filesInfo"]]
  }
  if ("request.labels" %in% names(req_data$params)) {
    request.labels <- req_data$params[["request.labels"]]
  }
  if ("request.options.OR" %in% names(req_data$params)) {
    request.options.OR <- req_data$params[["request.options.OR"]]
  }
  if ("request.options.profile" %in% names(req_data$params)) {
    request.options.profile <- req_data$params[["request.options.profile"]]
  }
  if ("request.options.PV1" %in% names(req_data$params)) {
    request.options.PV1 <- req_data$params[["request.options.PV1"]]
  }
  if ("request.options.TP" %in% names(req_data$params)) {
    request.options.TP <- req_data$params[["request.options.TP"]]
  }
  if ("request.resolve" %in% names(req_data$params)) {
    request.resolve <- req_data$params[["request.resolve"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(labels)) {
    extra_options$labels <- labels
  }
  if (!is.null(options)) {
    extra_options$options <- options
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "toxprints/calculate",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    request.filesInfo = request.filesInfo,
    request.labels = request.labels,
    request.options.OR = request.options.OR,
    request.options.profile = request.options.profile,
    request.options.PV1 = request.options.PV1,
    request.options.TP = request.options.TP,
    request.resolve = request.resolve,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
