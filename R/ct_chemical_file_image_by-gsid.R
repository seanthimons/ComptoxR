#' Get structure image by GSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param gsid Generic Substance Id. Type: string
#' @return Returns image data (raw bytes or magick image object)
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_file_image_by_gsid(gsid = "20182")
#' }
ct_chemical_file_image_by_gsid <- function(gsid) {
  result <- generic_request(
    query = gsid,
    endpoint = "chemical/file/image/search/by-gsid/",
    method = "GET",
    batch_limit = 1,
    content_type = "image/png"
  )

  # Additional post-processing can be added here

  return(result)
}


