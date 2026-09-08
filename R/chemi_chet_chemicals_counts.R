#' Chemical counts by library
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param page Optional parameter
#' @param size Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_counts(page = "DTXSID7020182")
#' }
chemi_chet_chemicals_counts <- function(
  page = 0,
  size = NULL,
  all_pages = TRUE,
  max_pages = 100
) {
  # Collect optional parameters
  options <- list()
  if (!is.null(page)) {
    options[['page']] <- page
  }
  if (!is.null(size)) {
    options[['size']] <- size
  }
  result <- generic_request(
    endpoint = "chemicals/counts",
    method = "GET",
    batch_limit = 0,
    server = "chemi_burl",
    auth = FALSE,
    tidy = FALSE,
    options = options,
    paginate = all_pages,
    max_pages = max_pages,
    pagination_strategy = "page_size"
  )

  # Additional post-processing can be added here

  return(result)
}
