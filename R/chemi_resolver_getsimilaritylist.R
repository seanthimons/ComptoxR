#' Compare a reference chemical with supplied candidate chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Resolves one reference and a candidate set, then calculates similarities within that set. Does not search a chemical database for new candidates. The reference is excluded from returned candidates.
#' @param query Character vector of 1 to 1000 candidate chemical identifiers. Unresolved candidates are omitted.
#' @param main One reference chemical identifier, resolved separately from query.
#' @param idType Identifier type for both reference and candidates; defaults to AnyId.
#' @param fingerprintName Fingerprint engine. Default indigo is verified; other engines require compatible scoring settings.
#' @param scoreName Similarity score. Default tanimoto is verified with indigo.
#' @param padelCompute2D padelCompute2D
#' @param padelCompute3D padelCompute3D
#' @param padelComputeFingerprints padelComputeFingerprints
#' @param rdkitBits rdkitBits
#' @param rdkitRadius rdkitRadius
#' @param rdkitType rdkitType
#' @param toxprintsProfile toxprintsProfile
#' @param tverskyI tverskyI
#' @return A list of API Row objects containing chemical, max and similarity fields. Returns NULL with a warning when no candidates resolve.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_getsimilaritylist(query = "DTXSID9020112", main = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_getsimilaritylist <- function(
  query,
  main,
  idType = "AnyId",
  fingerprintName = "indigo",
  scoreName = "tanimoto",
  padelCompute2D = NULL,
  padelCompute3D = NULL,
  padelComputeFingerprints = NULL,
  rdkitBits = NULL,
  rdkitRadius = NULL,
  rdkitType = NULL,
  toxprintsProfile = NULL,
  tverskyI = NULL
) {
  params <- base::c(
    base::list(
      "query" = query,
      "main" = main,
      "idType" = idType,
      "fingerprintName" = fingerprintName,
      "scoreName" = scoreName,
      "padelCompute2D" = padelCompute2D,
      "padelCompute3D" = padelCompute3D,
      "padelComputeFingerprints" = padelComputeFingerprints,
      "rdkitBits" = rdkitBits,
      "rdkitRadius" = rdkitRadius,
      "rdkitType" = rdkitType,
      "toxprintsProfile" = toxprintsProfile,
      "tverskyI" = tverskyI
    ),
    list(reference_chemical = NULL, candidate_chemicals = NULL)
  )
  state <- run_hook("chemi_resolver_getsimilaritylist", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/getsimilaritylist",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = c(
      list(main = params[["reference_chemical"]], `_chemicals` = params[["candidate_chemicals"]]),
      Filter(
        Negate(is.null),
        base::list(
          fingerprintName = params[["fingerprintName"]],
          padelCompute2D = params[["padelCompute2D"]],
          padelCompute3D = params[["padelCompute3D"]],
          padelComputeFingerprints = params[["padelComputeFingerprints"]],
          rdkitBits = params[["rdkitBits"]],
          rdkitRadius = params[["rdkitRadius"]],
          rdkitType = params[["rdkitType"]],
          scoreName = params[["scoreName"]],
          toxprintsProfile = params[["toxprintsProfile"]],
          tverskyI = params[["tverskyI"]]
        )
      )
    ),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = ".ct_list"
  )
  result
}
