#' chemi hazard bulk
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param empty Optional parameter
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.analogsSearchType Optional parameter. Options: EXACT, SUBSTRUCTURE, SIMILAR, TOXPRINTS, FORMULA, MASS, FEATURES, HAZARD, ADVANCED
#' @param request.options.cts Optional parameter
#' @param request.options.minSimilarity Optional parameter
#' @param request.options.noRecords Optional parameter
#' @param request.options.usePredictions Optional parameter
#' @param format Output format. One of 'compact', 'tidy', or 'raw'
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_hazard_bulk <- function(
  query,
  idType = "AnyId",
  empty = NULL,
  options = NULL,
  request.filesInfo = NULL,
  request.options.analogsSearchType = NULL,
  request.options.cts = NULL,
  request.options.minSimilarity = NULL,
  request.options.noRecords = NULL,
  request.options.usePredictions = NULL,
  format = c("compact", "tidy", "raw")
) {
  params <- base::c(
    base::list(
      "query" = query,
      "idType" = idType,
      "empty" = empty,
      "options" = options,
      "request.filesInfo" = request.filesInfo,
      "request.options.analogsSearchType" = request.options.analogsSearchType,
      "request.options.cts" = request.options.cts,
      "request.options.minSimilarity" = request.options.minSimilarity,
      "request.options.noRecords" = request.options.noRecords,
      "request.options.usePredictions" = request.options.usePredictions,
      "format" = format
    ),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_hazard_bulk", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/hazard",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(
      "request.filesInfo" = params[["request.filesInfo"]],
      "request.options.analogsSearchType" = params[["request.options.analogsSearchType"]],
      "request.options.cts" = params[["request.options.cts"]],
      "request.options.minSimilarity" = params[["request.options.minSimilarity"]],
      "request.options.noRecords" = params[["request.options.noRecords"]],
      "request.options.usePredictions" = params[["request.options.usePredictions"]]
    ),
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
            empty = params[["empty"]],
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
                      analogsSearchType = list(
                        enum = list(
                          "EXACT",
                          "SUBSTRUCTURE",
                          "SIMILAR",
                          "TOXPRINTS",
                          "FORMULA",
                          "MASS",
                          "FEATURES",
                          "HAZARD",
                          "ADVANCED"
                        ),
                        type = "string"
                      ),
                      cts = list(format = "int32", type = "integer"),
                      minSimilarity = list(format = "float", type = "number"),
                      noRecords = list(type = "boolean"),
                      usePredictions = list(type = "boolean")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/HazardOptions"
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
      context$endpoint <- "hazard"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result <- run_hook(
    "chemi_hazard_bulk",
    "post_response",
    base::list(
      result = result,
      params = params[c(
        "query",
        "idType",
        "empty",
        "options",
        "request.filesInfo",
        "request.options.analogsSearchType",
        "request.options.cts",
        "request.options.minSimilarity",
        "request.options.noRecords",
        "request.options.usePredictions",
        "format"
      )]
    )
  )
  result
}
