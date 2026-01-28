#' Retrieves a list of methods that contain the MS-Ready forms of a given substance but not the substance itself.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param inchikey InChIKey to search by.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_ms_ready_methods(inchikey = "DTXSID7020182")
#' }
chemi_amos_get_ms_ready_methods <- function(inchikey) {
  result <- generic_request(
    query = inchikey,
    endpoint = "amos/get_ms_ready_methods/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


