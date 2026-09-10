#' Get structure image by DTXCID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxcid DSSTox Compound Identifier. Type: string
#' @return Returns image data (raw bytes or magick image object)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_image_search_by_dtxcid(dtxcid = "DTXCID505")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_file_image_search_by_dtxcid <- function(dtxcid) {
  params <- list("dtxcid" = dtxcid)
  result <- generic_request(
    "query" = params[["dtxcid"]],
    "endpoint" = "chemical/file/image/search/by-dtxcid/",
    "method" = "GET",
    "batch_limit" = 1,
    "content_type" = "image/png"
  )
  result
}
