#' Returns information on a batch of methods.  Intended to be used for pagination of the data instead of trying to transfer all the information in one transaction.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param offset Offset of method records to return.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_pagination(limit = "DTXSID7020182")
#' }
chemi_amos_method_pagination <- function(limit, offset = NULL) {
  generic_request(
    query = limit,
    endpoint = "amos/method_pagination/",
    method = "GET",
    batch_limit = 1,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset)
  )
}


