#' Get Single Sample data by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_mmdb_single_sample(dtxsid = "DTXSID7020182")
#' }
ct_exposure_mmdb_single_sample <- function(dtxsid) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "exposure/mmdb/single-sample/by-dtxsid/",
    method = "GET",
    batch_limit = 1
  )

  # Additional post-processing can be added here

  return(result)
}


