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
  # Resolve identifiers to Chemical objects via bulk POST endpoint
  resolved <- tryCatch(
    chemi_resolver_lookup_bulk(ids = query, idsType = idType, tidy = FALSE),
    error = function(e) {
      tryCatch(
        chemi_resolver_lookup_bulk(ids = query, tidy = FALSE),
        error = function(e2) stop("chemi_resolver_lookup_bulk failed: ", e2$message)
      )
    }
  )

  # Keep only successfully resolved entries
  resolved <- purrr::keep(resolved, function(item) identical(item$result, "FOUND"))

  if (length(resolved) == 0) {
    cli::cli_warn("No chemicals could be resolved from the provided identifiers")
    return(NULL)
  }

  # Transform resolved list to ChemicalRecord format expected by endpoint
  chemicals <- purrr::map(resolved, function(item) {
    chem <- item$chemical
    list(
      chemical = list(
        sid = chem$chemId %||% chem$sid,
        smiles = chem$canonicalSmiles %||% chem$smiles,
        casrn = chem$casrn,
        inchi = chem$inchi,
        inchiKey = chem$inchiKey,
        name = chem$name
      )
    )
  })

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
    query = NULL,
    endpoint = "resolver/orderBySimilarity",
    options = extra_options,
    chemicals = chemicals,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
