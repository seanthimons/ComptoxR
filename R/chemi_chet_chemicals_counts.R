#' Chemical counts by library
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param page Optional parameter
#' @param size Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a tibble with results (array of objects)
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_counts(page = "DTXSID7020182")
#' }
# Generated with apipak; do not edit by hand.
chemi_chet_chemicals_counts <- function(page = 0, size = NULL, all_pages = TRUE, max_pages = 100) {
  params <- list("page" = page, "size" = size, "all_pages" = all_pages, "max_pages" = max_pages)
  result <- generic_request(
    "endpoint" = "chemicals/counts",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(Negate(is.null), list("page" = params[["page"]], "size" = params[["size"]]))
      if (length(.body)) .body else list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "page_size"
  )
  result
}
