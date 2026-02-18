#' Returns information on a batch of safety data sheets.  Intended to be used for pagination of the data instead of trying to transfer all the information in one transaction.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param offset Offset of safety data sheets to return.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_safety_data_sheet_pagination(limit = 10, offset = 0)
#' }
chemi_amos_safety_data_sheet_pagination <- function(limit, offset = NULL) {
  result <- generic_request(
    query = limit,
    endpoint = "amos/safety_data_sheet_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset)
  )

  # Additional post-processing can be added here

  return(result)
}

