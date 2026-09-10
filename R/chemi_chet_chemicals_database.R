#' Search chemicals
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param page Optional parameter
#' @param size Optional parameter
#' @param query Optional parameter
#' @param exact_search Optional parameter
#' @param lib_name Optional parameter
#' @param only_in_reactions Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database(page = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_database <- function(
  page = 0,
  size = NULL,
  query = NULL,
  exact_search = NULL,
  lib_name = NULL,
  only_in_reactions = NULL,
  all_pages = TRUE,
  max_pages = 100
) {
  params <- list(
    "page" = page,
    "size" = size,
    "query" = query,
    "exact_search" = exact_search,
    "lib_name" = lib_name,
    "only_in_reactions" = only_in_reactions,
    "all_pages" = all_pages,
    "max_pages" = max_pages
  )
  result <- generic_request(
    "endpoint" = "chemicals/database",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "page" = params[["page"]],
          "size" = params[["size"]],
          "query" = params[["query"]],
          "exact_search" = params[["exact_search"]],
          "lib_name" = params[["lib_name"]],
          "only_in_reactions" = params[["only_in_reactions"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "paginate" = params[["all_pages"]],
    "max_pages" = params[["max_pages"]],
    "pagination_strategy" = "page_size"
  )
  result
}
