#' chemi alerts
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param options Optional parameter
#' @param request.filesInfo Optional parameter
#' @param request.options.alerts Optional parameter
#' @param request.options.resolve Optional parameter
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_alerts <- function(
  query,
  idType = "AnyId",
  options = NULL,
  request.filesInfo = NULL,
  request.options.alerts = NULL,
  request.options.resolve = NULL
) {
  params <- base::c(
    base::list(
      "query" = query,
      "idType" = idType,
      "options" = options,
      "request.filesInfo" = request.filesInfo,
      "request.options.alerts" = request.options.alerts,
      "request.options.resolve" = request.options.resolve
    ),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_alerts", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/alerts",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(
      "request.filesInfo" = params[["request.filesInfo"]],
      "request.options.alerts" = params[["request.options.alerts"]],
      "request.options.resolve" = params[["request.options.resolve"]]
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
                      alerts = list(items = list(type = "string"), type = "array"),
                      resolve = list(type = "boolean")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/AlertOptions"
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
      context$endpoint <- "alerts"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
