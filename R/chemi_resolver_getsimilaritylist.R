#' Resolver Getsimilaritylist
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param chemicals Required parameter
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
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritylist(chemicals = "DTXSID7020182")
#' }
chemi_resolver_getsimilaritylist <- function(chemicals, fingerprintName = NULL, get_chemicals = NULL, main = NULL, padelCompute2D = NULL, padelCompute3D = NULL, padelComputeFingerprints = NULL, rdkitBits = NULL, rdkitRadius = NULL, rdkitType = NULL, scoreName = NULL, toxprintsProfile = NULL, tverskyI = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(fingerprintName)) options$fingerprintName <- fingerprintName
  if (!is.null(get_chemicals)) options$get_chemicals <- get_chemicals
  if (!is.null(main)) options$main <- main
  if (!is.null(padelCompute2D)) options$padelCompute2D <- padelCompute2D
  if (!is.null(padelCompute3D)) options$padelCompute3D <- padelCompute3D
  if (!is.null(padelComputeFingerprints)) options$padelComputeFingerprints <- padelComputeFingerprints
  if (!is.null(rdkitBits)) options$rdkitBits <- rdkitBits
  if (!is.null(rdkitRadius)) options$rdkitRadius <- rdkitRadius
  if (!is.null(rdkitType)) options$rdkitType <- rdkitType
  if (!is.null(scoreName)) options$scoreName <- scoreName
  if (!is.null(toxprintsProfile)) options$toxprintsProfile <- toxprintsProfile
  if (!is.null(tverskyI)) options$tverskyI <- tverskyI
  generic_chemi_request(
    query = chemicals,
    endpoint = "resolver/getsimilaritylist",
    options = options,
    tidy = FALSE
  )
}


