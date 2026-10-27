#' chemi resolver orderBySimilarity
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param fingerprintName Optional parameter
#' @param get_chemicals Optional parameter
#' @param main Reference Chemical object for similarity ordering; supply sid and smiles. The service requires this reference.
#' @param padelCompute2D Optional parameter
#' @param padelCompute3D Optional parameter
#' @param padelComputeFingerprints Optional parameter
#' @param rdkitBits Optional parameter
#' @param rdkitRadius Optional parameter
#' @param rdkitType Optional parameter
#' @param scoreName Optional parameter
#' @param toxprintsProfile Optional parameter
#' @param tverskyI Optional parameter
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_resolver_order_by_similarity <- function(
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
  params <- base::c(
    base::list(
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
    ),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_resolver_order_by_similarity", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/resolver/orderBySimilarity",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(),
    "body" = base::local({
      chemicals <- params[["chemicals"]]
      if (!is.list(chemicals) || !length(chemicals)) {
        chemicals <- lapply(.ct_toxprint_query(params[["query"]]), function(id) list(chemical = list(sid = id)))
      }
      c(
        list(chemicals = chemicals),
        Filter(
          Negate(is.null),
          base::list(
            fingerprintName = params[["fingerprintName"]],
            get_chemicals = params[["get_chemicals"]],
            main = params[["main"]],
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
      )
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "resolver/orderBySimilarity"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
