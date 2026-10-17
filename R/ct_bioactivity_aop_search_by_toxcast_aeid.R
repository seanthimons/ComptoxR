#' Get AOP data by ToxCast AEID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param toxcastAeid toxcastAeid Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_toxcast_aeid(toxcastAeid = 63L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_toxcast_aeid <- function(toxcastAeid) {
  toxcastAeid <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(toxcastAeid)
  if (base::is.null(toxcastAeid)) {
    base::stop("Required input: toxcastAeid")
  }
  .api_validation$parameter_values(
    base::list("toxcastAeid" = toxcastAeid),
    list(toxcastAeid = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(toxcastAeid = "path")
  )
  params <- base::list("toxcastAeid" = toxcastAeid)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/aop/search/by-toxcast-aeid/{toxcastAeid}",
      path_params = base::list("toxcastAeid" = params[["toxcastAeid"]]),
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
      params["toxcastAeid"] <- base::list(chunk)
      send(params)
    },
    params[["toxcastAeid"]],
    1L,
    on_error = "drop"
  )
}
