#' Export
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param uri Required parameter
#' @param returnAsAttachment Optional parameter
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' cc_export(uri = "123-91-1")
#' }
cc_export <- function(uri, returnAsAttachment = NULL) {
  result <- generic_request(
    endpoint = "export",
    method = "GET",
    batch_limit = 0,
    `uri` = uri,
    `returnAsAttachment` = returnAsAttachment
  )

  # Additional post-processing can be added here

  return(result)
}


