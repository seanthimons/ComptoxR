#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param headers headers
#' @param profile profile
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints <- function(smiles, headers = FALSE, profile = NULL) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "headers" = headers, "profile" = profile),
    list(
      smiles = list(type = "string"),
      headers = list(default = FALSE, type = "boolean"),
      profile = list(type = "string")
    ),
    .api_validation$body_value,
    c(smiles = "query", headers = "query", profile = "query")
  )
  params <- base::list("smiles" = smiles, "headers" = headers, "profile" = profile)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["headers"]]) && base::any(!base::nzchar(params[["headers"]]))) {
    base::stop("Empty query parameter: headers")
  }
  if (base::is.character(params[["profile"]]) && base::any(!base::nzchar(params[["profile"]]))) {
    base::stop("Empty query parameter: profile")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/toxprints",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "headers" = params[["headers"]], "profile" = params[["profile"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list(),
    parameter_serialization = list(list(
      name = "headers",
      location = "query",
      schema = list(default = FALSE, type = "boolean"),
      style = "form",
      explode = TRUE,
      collection_format = NULL,
      required = FALSE
    ))
  )
  result
}

#' Toxprints
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_bulk(query = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_bulk <- function(query) {
  params <- base::list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "toxprints",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}
