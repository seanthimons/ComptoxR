#' Get List Presence Tags
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_exposure_list_presence_tags()
#' }
ct_exposure_list_presence_tags <- function() {
  result <- generic_request(
    endpoint = "exposure/list-presence/tags",
    method = "GET",
    batch_limit = 0
  )

  # Additional post-processing can be added here

  return(result)
}


