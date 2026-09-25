#' Get predictions by DTXSID and model
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param dtxsid dtxsid
#' @param model model
#' @return Returns a tibble with results (array of objects)
#' @export
#' @examples
#' \dontrun{
#' ct_bioactivity_models_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_bioactivity_models_search <- function(dtxsid, model) {
  params <- base::list("dtxsid" = dtxsid, "model" = model)
  result <- generic_request(
    "endpoint" = "bioactivity/models/search/",
    "method" = "GET",
    "batch_limit" = 0,
    "dtxsid" = params[["dtxsid"]],
    "model" = params[["model"]]
  )
  result
}
