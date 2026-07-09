#' Get all lists
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' @param projection Projection options for chemical List APIs . Options: chemicallistall, chemicallistwithdtxsids, chemicallistname, ccdchemicaldetaillists (default: chemicallistall)
#' @param return_dtxsid Return all DTXSIDs contained within each list
#' @param coerce Coerce DTXSID strings per list to list-column (requires return_dtxsid = TRUE)
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_list_all(projection = "chemicallistall")
#' }
ct_chemical_list_all <- function(projection = "chemicallistall", return_dtxsid = FALSE, coerce = FALSE) {
  req_data <- run_hook(
    "ct_chemical_list_all",
    "pre_request",
    list(params = list(projection = projection, return_dtxsid = return_dtxsid, coerce = coerce))
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("projection" %in% names(req_data$params)) {
    projection <- req_data$params[["projection"]]
  }
  if ("return_dtxsid" %in% names(req_data$params)) {
    return_dtxsid <- req_data$params[["return_dtxsid"]]
  }
  if ("coerce" %in% names(req_data$params)) {
    coerce <- req_data$params[["coerce"]]
  }

  result <- generic_request(
    endpoint = "chemical/list/all",
    method = "GET",
    batch_limit = 0,
    `projection` = projection
  )

  result <- run_hook(
    "ct_chemical_list_all",
    "post_response",
    list(result = result, params = list(projection = projection, return_dtxsid = return_dtxsid, coerce = coerce))
  )

  # Additional post-processing can be added here

  return(result)
}
