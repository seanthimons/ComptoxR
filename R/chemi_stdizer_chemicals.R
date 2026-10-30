#' chemi stdizer chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of chemical identifiers (DTXSIDs, CAS, SMILES, InChI, etc.)
#' @param idType Type of identifier. Options: DTXSID, DTXCID, SMILES, MOL, CAS, Name, InChI, InChIKey, InChIKey_1, AnyId (default)
#' @param full Optional parameter
#' @param options Standardizer options. Select a workflow explicitly, for example list(workflow = "ms-ready"). The service rejects a missing workflow.
#' @return Decoded response records, with the configured client formatting.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_stdizer_chemicals <- function(query, idType = "AnyId", full = NULL, options = NULL) {
  params <- base::c(
    base::list("query" = query, "idType" = idType, "full" = full, "options" = options),
    list(chemicals = NULL)
  )
  state <- run_hook("chemi_stdizer_chemicals", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/stdizer/chemicals",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list(),
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
            full = params[["full"]],
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
                      recordId = list(type = "string"),
                      run = list(type = "string"),
                      workflow = list(type = "string")
                    ),
                    type = "object"
                  ),
                  specmill_id = "#/components/schemas/StdizerOptions"
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
      context$endpoint <- "stdizer/chemicals"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
