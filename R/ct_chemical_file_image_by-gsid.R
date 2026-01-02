#' Get structure image by GSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query A single DTXSID (in quotes) or a list to be queried

#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_image_by_gsid(query = "DTXSID7020182")
#' }
ct_chemical_file_image_by_gsid <- function(query) {
  generic_request(
    query = query,
    endpoint = "chemical/file/image/search/by-gsid/",
    method = "GET",
		batch_limit = 1
  )
}

