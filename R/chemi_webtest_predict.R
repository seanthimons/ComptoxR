#' Predict one chemical with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' WebTEST currently returns every endpoint and method even when a subset is
#' requested. Wide output filters the response to the requested endpoint and
#' method.
#'
#' @param smiles One SMILES string or resolvable chemical identifier.
#' @param endpoint Required WebTEST endpoint identifier, such as `LC50`.
#' @param method Prediction method: `consensus`, `hc`, `sm`, `gc`, or `nn`.
#' @param format Report format: `JSON`, `HTML`, or `PDF`.
#' @param output `wide` for normalized JSON predictions or `raw` for an
#'   unformatted response with provenance attributes.
#' @return A normalized prediction tibble or raw response.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict("DTXSID7020182", endpoint = "LC50")
#' }
chemi_webtest_predict <- function(
  smiles,
  endpoint,
  method = "consensus",
  format = "JSON",
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_webtest_predict",
    "transform",
    list(
      params = list(
        smiles = smiles,
        endpoint = endpoint,
        method = method,
        format = format,
        output = output
      )
    )
  )
  result
}

#' Predict multiple chemicals with WebTEST
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param structures Chemical structures or resolvable identifiers.
#' @param endpoints Required WebTEST endpoint identifiers.
#' @param methods Prediction methods: `consensus`, `hc`, `sm`, `gc`, or `nn`.
#' @param format Report format: `JSON`, `HTML`, or `PDF`.
#' @param output `wide` for normalized JSON predictions or `raw` for an
#'   unformatted response with provenance attributes.
#' @return A normalized prediction tibble or raw response.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_webtest_predict_bulk(
#'   structures = c("DTXSID7020182", "CCO"),
#'   endpoints = "LC50"
#' )
#' }
chemi_webtest_predict_bulk <- function(
  structures,
  endpoints,
  methods = NULL,
  format = "JSON",
  output = c("wide", "raw")
) {
  result <- run_hook(
    "chemi_webtest_predict_bulk",
    "transform",
    list(
      params = list(
        structures = structures,
        endpoints = endpoints,
        methods = methods,
        format = format,
        output = output
      )
    )
  )
  result
}
