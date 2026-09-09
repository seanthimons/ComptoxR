#' Get chemicals for a batch of  MS-ready formulas
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Character vector of strings to send in request body
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula_bulk(query = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_search_by_msready_formula_bulk <- function(query) {
  params <- list("query" = query)
  result <- generic_request(
    "query" = params[["query"]],
    "endpoint" = "chemical/search/by-msready-formula/",
    "method" = "POST",
    "batch_limit" = as.numeric(Sys.getenv("batch_limit", "100"))
  )
  result
}

#' Get chemicals by MS-ready formula
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param formula Chemical formula. Type: string
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_search_by_msready_formula(formula = "C15H16O2")
#' }
# Generated with apipak; do not edit by hand.
ct_chemical_search_by_msready_formula <- function(formula) {
  params <- list("formula" = formula)
  result <- generic_request(
    "query" = params[["formula"]],
    "endpoint" = "chemical/search/by-msready-formula/",
    "method" = "GET",
    "batch_limit" = 1
  )
  result
}
