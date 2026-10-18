#' Retrieves links for supplemental sources (e.g., Wikipedia, ChemExpo) for a given DTXSID, if any are available.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Decoded JSON, text, or raw workbook bytes according to the response content type; NULL for an empty response.
#' @apiStage public
#' @export
# Generated with specmill; do not edit by hand.
chemi_amos_additional_sources_for_substance <- function(dtxsid) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid),
    list(
      dtxsid = list(
        description = "The DTXSID for the substance of interest.",
        "in" = "path",
        name = "dtxsid",
        type = "string"
      )
    ),
    .api_validation$body_value,
    c(dtxsid = "path")
  )
  params <- base::list("dtxsid" = dtxsid)
  result <- .ct_request(
    method = "GET",
    path = "/api/amos/additional_sources_for_substance/{dtxsid}",
    path_params = base::list("dtxsid" = params[["dtxsid"]]),
    query = base::list(),
    body = NULL,
    request_controls = list(preserve_errors = TRUE),
    server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
