#' Get assay summary by gene symbol
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param geneSymbol geneSymbol Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_assay_search_by_gene(geneSymbol = "TUBA1A")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_assay_search_by_gene <- function(geneSymbol) {
  geneSymbol <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(geneSymbol)
  if (base::is.null(geneSymbol)) {
    base::stop("Required input: geneSymbol")
  }
  .api_validation$parameter_values(
    base::list("geneSymbol" = geneSymbol),
    list(geneSymbol = list(type = "array", items = list(type = "string"))),
    .api_validation$body_value,
    c(geneSymbol = "path")
  )
  params <- base::list("geneSymbol" = geneSymbol)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/assay/search/by-gene/{geneSymbol}",
      path_params = base::list("geneSymbol" = params[["geneSymbol"]]),
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
      params["geneSymbol"] <- base::list(chunk)
      send(params)
    },
    params[["geneSymbol"]],
    1L,
    on_error = "drop"
  )
}
