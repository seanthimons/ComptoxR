#' Returns a list of DTXSIDs associated with the specified internal ID, along with additional substance information.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the record of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_find_dtxsids(internal_id = "DTXSID7020182")
#' }
chemi_amos_find_dtxsids <- function(internal_id) {
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/find_dtxsids/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


