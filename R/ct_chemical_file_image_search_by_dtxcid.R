#' Get structure image by DTXCID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns image data (raw bytes or magick image object)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_image_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
ct_chemical_file_image_search_by_dtxcid <- function(dtxcid) {
  result <- generic_request(
    query = dtxcid,
    endpoint = "chemical/file/image/search/by-dtxcid/",
    method = "GET",
    batch_limit = 1,
    content_type = "image/png"
  )

  # Additional post-processing can be added here

  return(result)
}


