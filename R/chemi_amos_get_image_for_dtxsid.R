#' Retrieves a substance's image from the database.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid The DTXSID for the substance of interest.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_image_for_dtxsid(dtxsid = "DTXSID7020182")
#' }
chemi_amos_get_image_for_dtxsid <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "amos/get_image_for_dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )
}


