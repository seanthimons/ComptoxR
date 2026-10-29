#' Generate a standalone OPERA calculation report
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid dtxsid
#' @param modelId modelId
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_opera_report(dtxsid = "DTXSID7020182", modelId = 1L)
#' }
# Generated with specmill; do not edit by hand.
chemi_opera_report <- function(dtxsid, modelId) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(modelId)) {
    base::stop("Required input: modelId")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "modelId" = modelId),
    list(dtxsid = list(type = "string"), modelId = list(type = "integer")),
    .api_validation$body_value,
    c(dtxsid = "query", modelId = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "modelId" = modelId)
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  if (base::is.character(params[["modelId"]]) && base::any(!base::nzchar(params[["modelId"]]))) {
    base::stop("Empty query parameter: modelId")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/opera/report",
    path_params = base::list(),
    query = base::list("dtxsid" = params[["dtxsid"]], "modelId" = params[["modelId"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}
