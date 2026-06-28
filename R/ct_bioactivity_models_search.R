#' Get predictions by DTXSID and model
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid dtxsid
#' @param model model
#' @return Returns a tibble with results (array of objects)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity_models_search(dtxsid = "DTXSID7020182")
#' }
ct_bioactivity_models_search <- function(dtxsid, model) {
  result <- generic_request(
    endpoint = "bioactivity/models/search/",
    method = "GET",
    batch_limit = 0,
    `dtxsid` = dtxsid,
    `model` = model
  )

  # Additional post-processing can be added here

  return(result)
}
