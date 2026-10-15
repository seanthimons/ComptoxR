#' Get data by SMILES
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param smiles smiles
#' @return Returns a tibble with results
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_detail_search_by_smiles(smiles = "CC(C)(C1=CC=C(O)C=C1)C1=CC=C(O)C=C1")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_detail_search_by_smiles <- function(smiles) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles),
    list(smiles = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query")
  )
  params <- base::list("smiles" = smiles)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  result <- .ct_request(
    method = "GET",
    path = "/chemical/detail/search/by-smiles/",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]]),
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
