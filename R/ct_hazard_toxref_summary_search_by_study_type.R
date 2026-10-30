#' Get summary data by Study Type
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param studyType studyType Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_hazard_toxref_summary_search_by_study_type(studyType = "DEV")
#' }
# Generated with specmill; do not edit by hand.
ct_hazard_toxref_summary_search_by_study_type <- function(studyType) {
  studyType <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(studyType)
  if (base::is.null(studyType)) {
    base::stop("Required input: studyType")
  }
  .api_validation$parameter_values(
    base::list("studyType" = studyType),
    list(studyType = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(studyType = "path")
  )
  params <- base::list("studyType" = studyType)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/hazard/toxref/summary/search/by-study-type/{studyType}",
      path_params = base::list("studyType" = params[["studyType"]]),
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
      params["studyType"] <- base::list(chunk)
      send(params)
    },
    params[["studyType"]],
    1L,
    on_error = "drop",
    empty = .ct_empty_table
  )
}
