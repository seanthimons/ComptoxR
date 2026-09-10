#' Toxprints Calculate
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles Required parameter
#' @param labels Optional parameter (default: FALSE)
#' @param profile Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_calculate <- function(smiles, labels = FALSE, profile = NULL) {
  params <- list("smiles" = smiles, "labels" = labels, "profile" = profile)
  result <- generic_request(
    "endpoint" = "toxprints/calculate",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list("smiles" = params[["smiles"]], "labels" = params[["labels"]], "profile" = params[["profile"]])
      )
      if (length(.body)) .body else list()
    })
  )
  result
}

#' Toxprints Calculate
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' This function first resolves chemical identifiers using \code{chemi_resolver_lookup_bulk},
#' then sends the resolved Chemical objects to the API endpoint.
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param labels Optional parameter
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.labels Optional parameter
#' @param request.options.OR Optional parameter
#' @param request.options.PV1 Optional parameter
#' @param request.options.TP Optional parameter
#' @param request.options.or Optional parameter
#' @param request.options.profile Optional parameter
#' @param request.options.pv1 Optional parameter
#' @param request.options.tp Optional parameter
#' @param request.resolve Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_calculate_bulk(query = c("50-00-0", "DTXSID7020182"))
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_calculate_bulk <- function(
  query,
  idType = "AnyId",
  labels = NULL,
  options = NULL,
  request.filesInfo = NULL,
  request.labels = NULL,
  request.options.OR = NULL,
  request.options.PV1 = NULL,
  request.options.TP = NULL,
  request.options.or = NULL,
  request.options.profile = NULL,
  request.options.pv1 = NULL,
  request.options.tp = NULL,
  request.resolve = NULL
) {
  params <- list(
    "query" = query,
    "idType" = idType,
    "labels" = labels,
    "options" = options,
    "request.filesInfo" = request.filesInfo,
    "request.labels" = request.labels,
    "request.options.OR" = request.options.OR,
    "request.options.PV1" = request.options.PV1,
    "request.options.TP" = request.options.TP,
    "request.options.or" = request.options.or,
    "request.options.profile" = request.options.profile,
    "request.options.pv1" = request.options.pv1,
    "request.options.tp" = request.options.tp,
    "request.resolve" = request.resolve
  )
  state <- run_hook("chemi_toxprints_calculate_bulk", "pre_request", list(params = params))
  if (isTRUE(state$skip_request)) {
    return(state$result)
  }
  changed <- intersect(names(params), names(state$params))
  params[changed] <- state$params[changed]
  result <- generic_chemi_request(
    "query" = params[["query"]],
    "endpoint" = "toxprints/calculate",
    "options" = local({
      .body <- Filter(Negate(is.null), list("labels" = params[["labels"]], "options" = params[["options"]]))
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE,
    "chemicals" = state[["params"]][["chemicals"]],
    "request.filesInfo" = params[["request.filesInfo"]],
    "request.labels" = params[["request.labels"]],
    "request.options.OR" = params[["request.options.OR"]],
    "request.options.PV1" = params[["request.options.PV1"]],
    "request.options.TP" = params[["request.options.TP"]],
    "request.options.or" = params[["request.options.or"]],
    "request.options.profile" = params[["request.options.profile"]],
    "request.options.pv1" = params[["request.options.pv1"]],
    "request.options.tp" = params[["request.options.tp"]],
    "request.resolve" = params[["request.resolve"]]
  )
  result
}
