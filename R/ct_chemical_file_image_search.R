#' Get structure image by DTXSID
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @return Returns image data (raw bytes or magick image object)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_file_image_search(dtxsid = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_file_image_search <- function(dtxsid) {
  params <- list("dtxsid" = dtxsid)
  result <- generic_request(
    "query" = params[["dtxsid"]],
    "endpoint" = "chemical/file/image/search/by-dtxsid/",
    "method" = "GET",
    "batch_limit" = 1,
    "content_type" = "image/png"
  )
  result
}
