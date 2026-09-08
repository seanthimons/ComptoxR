#' Retrieves metadata from the database about a single safety data sheet.  This is not necessarily just the metadata
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param internal_id Unique ID of the safety data sheet.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_get_safety_data_sheet_editor_info(internal_id = "DTXSID7020182")
#' }
chemi_amos_get_safety_data_sheet_editor_info <- function(internal_id) {
  result <- generic_request(
    query = internal_id,
    endpoint = "amos/get_safety_data_sheet_editor_info/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}
