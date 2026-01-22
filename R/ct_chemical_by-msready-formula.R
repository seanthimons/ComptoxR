#' Get chemicals for a batch of  MS-ready formulas
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_by_msready_formula(query = "DTXSID7020182")
#' }
ct_chemical_by_msready_formula <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/search/by-msready-formula/",
    method = "POST",
    batch_limit = NULL
  )
}

