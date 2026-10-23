#' Get summary data by Study ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyId studyId Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_search_by_study_id(studyId = 63L)
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_search_by_study_id <- function(studyId) {
  studyId <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(studyId)
  if (base::is.null(studyId)) {
    base::stop("Required input: studyId")
  }
  .api_validation$parameter_values(
    base::list("studyId" = studyId),
    list(studyId = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(studyId = "path")
  )
  params <- base::list("studyId" = studyId)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxref/summary/search/by-study-id/{studyId}",
      path_params = base::list("studyId" = params[["studyId"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_tidy",
      server = list(url = "https://comptox.epa.gov/ctx-api"),
      server_resolver = list(name = ".ct_server_url", key = "ctx_burl"),
      auth = list(list(list(
        scheme = "ctx",
        type = "apiKey",
        location = "header",
        name = "x-api-key",
        envvar = "ctx_api_key"
      )))
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["studyId"] <- base::list(chunk)
      send(params)
    },
    params[["studyId"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
