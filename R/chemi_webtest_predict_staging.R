#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param smiles Required parameter
#' @param endpoint Optional parameter
#' @param method Optional parameter (default: consensus)
#' @param format Optional parameter. Options: UNKNOWN, SDF, SMI, MOL, CSV, TSV, JSON, XLSX, PDF, HTML, XML, DOCX
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_staging(smiles = "DTXSID7020182")
#' }
chemi_webtest_predict_staging <- function(smiles, endpoint = NULL, method = "consensus", format = NULL) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_webtest_predict_staging",
    "pre_request",
    list(
      params = list(`smiles` = smiles, `endpoint` = endpoint, `method` = method, `format` = format, `server` = server)
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("smiles" %in% names(req_data$params)) {
    smiles <- req_data$params[["smiles"]]
  }
  if ("endpoint" %in% names(req_data$params)) {
    endpoint <- req_data$params[["endpoint"]]
  }
  if ("method" %in% names(req_data$params)) {
    method <- req_data$params[["method"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  # Collect optional parameters
  options <- list()
  if (!is.null(smiles)) {
    options[['smiles']] <- smiles
  }
  if (!is.null(endpoint)) {
    options[['endpoint']] <- endpoint
  }
  if (!is.null(method)) {
    options[['method']] <- method
  }
  if (!is.null(format)) {
    options[['format']] <- format
  }
  result <- generic_request(
    endpoint = "webtest/predict",
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

#' Webtest Predict
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param endpoints Optional parameter
#' @param format Optional parameter
#' @param methods Optional parameter
#' @param structures Optional parameter
#' @return Returns a tibble with results
#' @apiStage staging
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk_staging(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_webtest_predict_bulk_staging <- function(
  query,
  idType = "AnyId",
  endpoints = NULL,
  format = NULL,
  methods = NULL,
  structures = NULL
) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_webtest_predict_bulk_staging",
    "pre_request",
    list(
      params = list(
        `query` = query,
        `idType` = idType,
        `endpoints` = endpoints,
        `format` = format,
        `methods` = methods,
        `structures` = structures,
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
  if ("endpoints" %in% names(req_data$params)) {
    endpoints <- req_data$params[["endpoints"]]
  }
  if ("format" %in% names(req_data$params)) {
    format <- req_data$params[["format"]]
  }
  if ("methods" %in% names(req_data$params)) {
    methods <- req_data$params[["methods"]]
  }
  if ("structures" %in% names(req_data$params)) {
    structures <- req_data$params[["structures"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(endpoints)) {
    extra_options$endpoints <- endpoints
  }
  if (!is.null(format)) {
    extra_options$format <- format
  }
  if (!is.null(methods)) {
    extra_options$methods <- methods
  }
  if (!is.null(structures)) {
    extra_options$structures <- structures
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "webtest/predict",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
