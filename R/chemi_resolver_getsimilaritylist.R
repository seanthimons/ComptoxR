#' Resolver Getsimilaritylist
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param fingerprintName Optional parameter
#' @param get_chemicals Optional parameter
#' @param main Optional parameter
#' @param padelCompute2D Optional parameter
#' @param padelCompute3D Optional parameter
#' @param padelComputeFingerprints Optional parameter
#' @param rdkitBits Optional parameter
#' @param rdkitRadius Optional parameter
#' @param rdkitType Optional parameter
#' @param scoreName Optional parameter
#' @param toxprintsProfile Optional parameter
#' @param tverskyI Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritylist(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_getsimilaritylist <- function(query, idType = "AnyId", fingerprintName = NULL, get_chemicals = NULL, main = NULL, padelCompute2D = NULL, padelCompute3D = NULL, padelComputeFingerprints = NULL, rdkitBits = NULL, rdkitRadius = NULL, rdkitType = NULL, scoreName = NULL, toxprintsProfile = NULL, tverskyI = NULL) {
  chemicals <- NULL
  server <- "chemi_burl"
  req_data <- run_hook("chemi_resolver_getsimilaritylist", "pre_request", list(params = list(`query` = query, `idType` = idType, `fingerprintName` = fingerprintName, `get_chemicals` = get_chemicals, `main` = main, `padelCompute2D` = padelCompute2D, `padelCompute3D` = padelCompute3D, `padelComputeFingerprints` = padelComputeFingerprints, `rdkitBits` = rdkitBits, `rdkitRadius` = rdkitRadius, `rdkitType` = rdkitType, `scoreName` = scoreName, `toxprintsProfile` = toxprintsProfile, `tverskyI` = tverskyI, `chemicals` = chemicals, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("idType" %in% names(req_data$params)) {
    idType <- req_data$params[["idType"]]
  }
  if ("fingerprintName" %in% names(req_data$params)) {
    fingerprintName <- req_data$params[["fingerprintName"]]
  }
  if ("get_chemicals" %in% names(req_data$params)) {
    get_chemicals <- req_data$params[["get_chemicals"]]
  }
  if ("main" %in% names(req_data$params)) {
    main <- req_data$params[["main"]]
  }
  if ("padelCompute2D" %in% names(req_data$params)) {
    padelCompute2D <- req_data$params[["padelCompute2D"]]
  }
  if ("padelCompute3D" %in% names(req_data$params)) {
    padelCompute3D <- req_data$params[["padelCompute3D"]]
  }
  if ("padelComputeFingerprints" %in% names(req_data$params)) {
    padelComputeFingerprints <- req_data$params[["padelComputeFingerprints"]]
  }
  if ("rdkitBits" %in% names(req_data$params)) {
    rdkitBits <- req_data$params[["rdkitBits"]]
  }
  if ("rdkitRadius" %in% names(req_data$params)) {
    rdkitRadius <- req_data$params[["rdkitRadius"]]
  }
  if ("rdkitType" %in% names(req_data$params)) {
    rdkitType <- req_data$params[["rdkitType"]]
  }
  if ("scoreName" %in% names(req_data$params)) {
    scoreName <- req_data$params[["scoreName"]]
  }
  if ("toxprintsProfile" %in% names(req_data$params)) {
    toxprintsProfile <- req_data$params[["toxprintsProfile"]]
  }
  if ("tverskyI" %in% names(req_data$params)) {
    tverskyI <- req_data$params[["tverskyI"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(fingerprintName)) extra_options$fingerprintName <- fingerprintName
  if (!is.null(get_chemicals)) extra_options$get_chemicals <- get_chemicals
  if (!is.null(main)) extra_options$main <- main
  if (!is.null(padelCompute2D)) extra_options$padelCompute2D <- padelCompute2D
  if (!is.null(padelCompute3D)) extra_options$padelCompute3D <- padelCompute3D
  if (!is.null(padelComputeFingerprints)) extra_options$padelComputeFingerprints <- padelComputeFingerprints
  if (!is.null(rdkitBits)) extra_options$rdkitBits <- rdkitBits
  if (!is.null(rdkitRadius)) extra_options$rdkitRadius <- rdkitRadius
  if (!is.null(rdkitType)) extra_options$rdkitType <- rdkitType
  if (!is.null(scoreName)) extra_options$scoreName <- scoreName
  if (!is.null(toxprintsProfile)) extra_options$toxprintsProfile <- toxprintsProfile
  if (!is.null(tverskyI)) extra_options$tverskyI <- tverskyI

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/getsimilaritylist",
    options = extra_options,
    tidy = FALSE,
    chemicals = chemicals,
    server = server
  )

  # Additional post-processing can be added here

  return(result)
}
