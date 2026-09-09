#' Resolver Getsimilaritylist
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
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
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritylist(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with apipak; do not edit by hand.
chemi_resolver_getsimilaritylist <- function(
  query,
  idType = "AnyId",
  fingerprintName = NULL,
  get_chemicals = NULL,
  main = NULL,
  padelCompute2D = NULL,
  padelCompute3D = NULL,
  padelComputeFingerprints = NULL,
  rdkitBits = NULL,
  rdkitRadius = NULL,
  rdkitType = NULL,
  scoreName = NULL,
  toxprintsProfile = NULL,
  tverskyI = NULL
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "fingerprintName" = fingerprintName,
    "get_chemicals" = get_chemicals,
    "main" = main,
    "padelCompute2D" = padelCompute2D,
    "padelCompute3D" = padelCompute3D,
    "padelComputeFingerprints" = padelComputeFingerprints,
    "rdkitBits" = rdkitBits,
    "rdkitRadius" = rdkitRadius,
    "rdkitType" = rdkitType,
    "scoreName" = scoreName,
    "toxprintsProfile" = toxprintsProfile,
    "tverskyI" = tverskyI
  )
  state <- run_hook("chemi_resolver_getsimilaritylist", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "resolver/getsimilaritylist",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "fingerprintName" = params[["fingerprintName"]],
          "get_chemicals" = params[["get_chemicals"]],
          "main" = params[["main"]],
          "padelCompute2D" = params[["padelCompute2D"]],
          "padelCompute3D" = params[["padelCompute3D"]],
          "padelComputeFingerprints" = params[["padelComputeFingerprints"]],
          "rdkitBits" = params[["rdkitBits"]],
          "rdkitRadius" = params[["rdkitRadius"]],
          "rdkitType" = params[["rdkitType"]],
          "scoreName" = params[["scoreName"]],
          "toxprintsProfile" = params[["toxprintsProfile"]],
          "tverskyI" = params[["tverskyI"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]]
  )
  result
}
