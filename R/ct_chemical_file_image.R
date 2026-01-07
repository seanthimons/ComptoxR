#' Get structure image by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier
#' @return Returns image data (raw bytes or magick image object)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_image(dtxsid = "DTXSID7020182")
#' }
ct_chemical_file_image <- function(dtxsid) {
  generic_request(
    query = dtxsid,
    endpoint = "chemical/file/image/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    content_type = "image/png"
  )
}

