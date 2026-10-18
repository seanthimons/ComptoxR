#' chemi toxprints calculate bulk
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
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
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
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
  params <- base::c(
    base::list(
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
    ),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_toxprints_calculate_bulk", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/toxprints/calculate",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(
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
    ),
    "body" = base::local({
      chemicals <- params[["chemicals"]]
      if (!is.list(chemicals) || !length(chemicals)) {
        chemicals <- lapply(.ct_toxprint_query(params[["query"]]), function(id) list(sid = id))
      }
      c(
        list(
          chemicals = lapply(chemicals, function(record) {
            if (is.list(record) && !is.null(record$chemical)) record$chemical else record
          })
        ),
        Filter(
          Negate(is.null),
          base::list(
            labels = params[["labels"]],
            options = base::local({
              options <- params[["options"]]
              if (is.null(options)) {
                options <- structure(list(), names = character())
              }
              .api_validation$body_value(
                options,
                structure(
                  list(
                    properties = list(
                      OR = list(format = "double", type = "number"),
                      PV1 = list(format = "double", type = "number"),
                      TP = list(format = "int32", type = "integer"),
                      or = list(format = "double", type = "number"),
                      profile = list(type = "string"),
                      pv1 = list(format = "double", type = "number"),
                      tp = list(format = "int32", type = "integer")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/ToxprintsOptions"
                )
              )
            })
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
      context$endpoint <- "toxprints/calculate"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
