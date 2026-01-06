#' Get structure image by GSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param gsid Generic Substance Id
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_image_by_gsid(gsid = "20182")
#' }
ct_chemical_file_image_by_gsid <- function(gsid) {
  generic_request(
    query = gsid,
    endpoint = "chemical/file/image/search/by-gsid/",
    method = "GET",
    batch_limit = 1
  )
}

