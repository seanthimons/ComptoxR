#' Get structure image by GSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param gsid Generic Substance Id. Type: string
#' @return Returns image data (raw bytes or magick image object)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_image_search_by_gsid(gsid = "20182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_file_image_search_by_gsid <- function(gsid) {
  params <- list("gsid" = gsid)
  result <- generic_request(
    "query" = params[["gsid"]],
    "endpoint" = "chemical/file/image/search/by-gsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "content_type" = "image/png"
  )
  result
}
