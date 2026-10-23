#' Get predictions by DTXSID and model
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid
#' @param model model
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_models_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_models_search <- function(dtxsid, model) {
  if (base::is.null(dtxsid)) {
    base::stop("Required input: dtxsid")
  }
  if (base::is.null(model)) {
    base::stop("Required input: model")
  }
  .api_validation$parameter_values(
    base::list("dtxsid" = dtxsid, "model" = model),
    list(dtxsid = list(type = "string"), model = list(type = "string")),
    .api_validation$body_value,
    c(dtxsid = "query", model = "query")
  )
  params <- base::list("dtxsid" = dtxsid, "model" = model)
  if (base::is.character(params[["dtxsid"]]) && base::any(!base::nzchar(params[["dtxsid"]]))) {
    base::stop("Empty query parameter: dtxsid")
  }
  if (base::is.character(params[["model"]]) && base::any(!base::nzchar(params[["model"]]))) {
    base::stop("Empty query parameter: model")
  }
  result <- .ct_request(
    method = "GET",
    path = "/bioactivity/models/search/",
    path_params = base::list(),
    query = base::list("dtxsid" = params[["dtxsid"]], "model" = params[["model"]]),
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
