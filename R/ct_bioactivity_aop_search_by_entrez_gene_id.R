#' Get AOP data by Entrez Gene ID
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param entrezGeneId entrezGeneId Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_aop_search_by_entrez_gene_id(entrezGeneId = 196L)
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_aop_search_by_entrez_gene_id <- function(entrezGeneId) {
  if (base::is.null(entrezGeneId)) {
    base::stop("Required input: entrezGeneId")
  }
  .api_validation$parameter_values(
    base::list("entrezGeneId" = entrezGeneId),
    list(entrezGeneId = list(type = "array", items = list(format = "int32", type = "integer"))),
    .api_validation$body_value,
    c(entrezGeneId = "path")
  )
  params <- base::list("entrezGeneId" = entrezGeneId)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/bioactivity/aop/search/by-entrez-gene-id/{entrezGeneId}",
      path_params = base::list("entrezGeneId" = params[["entrezGeneId"]]),
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
      params["entrezGeneId"] <- base::list(chunk)
      send(params)
    },
    params[["entrezGeneId"]],
    1L,
    on_error = "drop"
  )
}
