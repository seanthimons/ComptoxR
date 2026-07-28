#' Resolver orderBySimilarity
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using `chemi_resolver_lookup_bulk`,
#' then sends the resolved Chemical objects to the API endpoint.
#'
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param get_chemicals Optional parameter
#' @param main Optional parameter
#' @param fingerprintName Optional parameter
#' @param scoreName Optional parameter
#' @param tverskyI Optional parameter
#' @param rdkitType Optional parameter
#' @param rdkitRadius Optional parameter
#' @param rdkitBits Optional parameter
#' @param padelCompute2D Optional parameter
#' @param padelCompute3D Optional parameter
#' @param padelComputeFingerprints Optional parameter
#' @param toxprintsProfile Optional parameter
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_orderBySimilarity(query = c("50-00-0", "DTXSID7020182"))
#' }
chemi_resolver_orderBySimilarity <- function(
  query,
  idType = "AnyId",
  get_chemicals = NULL,
  main = NULL,
  fingerprintName = NULL,
  scoreName = NULL,
  tverskyI = NULL,
  rdkitType = NULL,
  rdkitRadius = NULL,
  rdkitBits = NULL,
  padelCompute2D = NULL,
  padelCompute3D = NULL,
  padelComputeFingerprints = NULL,
  toxprintsProfile = NULL
) {
  chemicals <- NULL
  req_data <- run_hook(
    "chemi_resolver_orderBySimilarity",
    "pre_request",
    list(
      params = list(
        query = query,
        idType = idType,
        get_chemicals = get_chemicals,
        main = main,
        fingerprintName = fingerprintName,
        scoreName = scoreName,
        tverskyI = tverskyI,
        rdkitType = rdkitType,
        rdkitRadius = rdkitRadius,
        rdkitBits = rdkitBits,
        padelCompute2D = padelCompute2D,
        padelCompute3D = padelCompute3D,
        padelComputeFingerprints = padelComputeFingerprints,
        toxprintsProfile = toxprintsProfile,
        chemicals = chemicals
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
  if ("get_chemicals" %in% names(req_data$params)) {
    get_chemicals <- req_data$params[["get_chemicals"]]
  }
  if ("main" %in% names(req_data$params)) {
    main <- req_data$params[["main"]]
  }
  if ("fingerprintName" %in% names(req_data$params)) {
    fingerprintName <- req_data$params[["fingerprintName"]]
  }
  if ("scoreName" %in% names(req_data$params)) {
    scoreName <- req_data$params[["scoreName"]]
  }
  if ("tverskyI" %in% names(req_data$params)) {
    tverskyI <- req_data$params[["tverskyI"]]
  }
  if ("rdkitType" %in% names(req_data$params)) {
    rdkitType <- req_data$params[["rdkitType"]]
  }
  if ("rdkitRadius" %in% names(req_data$params)) {
    rdkitRadius <- req_data$params[["rdkitRadius"]]
  }
  if ("rdkitBits" %in% names(req_data$params)) {
    rdkitBits <- req_data$params[["rdkitBits"]]
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
  if ("toxprintsProfile" %in% names(req_data$params)) {
    toxprintsProfile <- req_data$params[["toxprintsProfile"]]
  }
  if ("chemicals" %in% names(req_data$params)) {
    chemicals <- req_data$params[["chemicals"]]
  }

  # Build options from additional parameters
  extra_options <- list()
  if (!is.null(get_chemicals)) {
    extra_options$get_chemicals <- get_chemicals
  }
  if (!is.null(main)) {
    extra_options$main <- main
  }
  if (!is.null(fingerprintName)) {
    extra_options$fingerprintName <- fingerprintName
  }
  if (!is.null(scoreName)) {
    extra_options$scoreName <- scoreName
  }
  if (!is.null(tverskyI)) {
    extra_options$tverskyI <- tverskyI
  }
  if (!is.null(rdkitType)) {
    extra_options$rdkitType <- rdkitType
  }
  if (!is.null(rdkitRadius)) {
    extra_options$rdkitRadius <- rdkitRadius
  }
  if (!is.null(rdkitBits)) {
    extra_options$rdkitBits <- rdkitBits
  }
  if (!is.null(padelCompute2D)) {
    extra_options$padelCompute2D <- padelCompute2D
  }
  if (!is.null(padelCompute3D)) {
    extra_options$padelCompute3D <- padelCompute3D
  }
  if (!is.null(padelComputeFingerprints)) {
    extra_options$padelComputeFingerprints <- padelComputeFingerprints
  }
  if (!is.null(toxprintsProfile)) {
    extra_options$toxprintsProfile <- toxprintsProfile
  }

  result <- generic_chemi_request(
    query = query,
    endpoint = "resolver/orderBySimilarity",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
