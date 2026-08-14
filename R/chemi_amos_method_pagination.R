#' Returns information on a batch of methods.  Intended to be used for pagination of the data instead of trying to transfer all the information in one transaction.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param limit Limit of records to return.
#' @param offset Offset of method records to return.
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_method_pagination(limit = "DTXSID7020182")
#' }
chemi_amos_method_pagination <- function(limit, offset = 0, all_pages = TRUE, max_pages = 100) {
  server <- "chemi_burl"
  req_data <- run_hook(
    "chemi_amos_method_pagination",
    "pre_request",
    list(
      params = list(
        `limit` = limit,
        `offset` = offset,
        `all_pages` = all_pages,
        `max_pages` = max_pages,
        `server` = server
      )
    )
  )
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("limit" %in% names(req_data$params)) {
    limit <- req_data$params[["limit"]]
  }
  if ("offset" %in% names(req_data$params)) {
    offset <- req_data$params[["offset"]]
  }
  if ("all_pages" %in% names(req_data$params)) {
    all_pages <- req_data$params[["all_pages"]]
  }
  if ("max_pages" %in% names(req_data$params)) {
    max_pages <- req_data$params[["max_pages"]]
  }
  if ("server" %in% names(req_data$params)) {
    server <- req_data$params[["server"]]
  }
  result <- generic_request(
    query = limit,
    endpoint = "amos/method_pagination/",
    method = "GET",
    batch_limit = 1,
    server = server,
    auth = FALSE,
    tidy = FALSE,
    path_params = c(offset = offset),
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "offset_limit"
  )

  # Additional post-processing can be added here

  return(result)
}
