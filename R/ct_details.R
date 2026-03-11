#' Chemical details by DTXSID
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Retrieves chemical detail data for chemicals by DTXSID with configurable
#' projection level. Projection values are passed directly to the API.
#'
#' @param query Character vector of DTXSIDs
#' @param projection API projection string. Common values: `"compact"` (default),
#'   `"chemicaldetailall"`, `"chemicaldetailstandard"`, `"chemicalidentifier"`,
#'   `"chemicalstructure"`, `"ntatoolkit"`, `"ccdchemicaldetails"`,
#'   `"ccdassaydetails"`.
#'
#' @return A tibble of chemical detail results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_details(query = "DTXSID7020182")
#' ct_details(query = "DTXSID7020182", projection = "chemicaldetailall")
#' }
ct_details <- function(query, projection = "compact") {
  generic_request(
    query = query,
    endpoint = "chemical/detail/search/by-dtxsid/",
    method = "POST",
    projection = projection
  )
}
