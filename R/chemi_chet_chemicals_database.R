#' Search chemicals
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
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
#'
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_database(page = "DTXSID7020182")
#' }
chemi_chet_chemicals_database <- function(page = 0, size = NULL, query = NULL, exact_search = NULL, lib_name = NULL, only_in_reactions = NULL, all_pages = TRUE, max_pages = 100) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_chemicals_database", "pre_request", list(params = list(`page` = page, `size` = size, `query` = query, `exact_search` = exact_search, `lib_name` = lib_name, `only_in_reactions` = only_in_reactions, `all_pages` = all_pages, `max_pages` = max_pages, `server` = server)))
  if (isTRUE(req_data$skip_request)) {
    return(req_data$result)
  }
  if ("page" %in% names(req_data$params)) {
    page <- req_data$params[["page"]]
  }
  if ("size" %in% names(req_data$params)) {
    size <- req_data$params[["size"]]
  }
  if ("query" %in% names(req_data$params)) {
    query <- req_data$params[["query"]]
  }
  if ("exact_search" %in% names(req_data$params)) {
    exact_search <- req_data$params[["exact_search"]]
  }
  if ("lib_name" %in% names(req_data$params)) {
    lib_name <- req_data$params[["lib_name"]]
  }
  if ("only_in_reactions" %in% names(req_data$params)) {
    only_in_reactions <- req_data$params[["only_in_reactions"]]
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
  # Collect optional parameters
  options <- list()
  if (!is.null(page)) options[['page']] <- page
  if (!is.null(size)) options[['size']] <- size
  if (!is.null(query)) options[['query']] <- query
  if (!is.null(exact_search)) options[['exact_search']] <- exact_search
  if (!is.null(lib_name)) options[['lib_name']] <- lib_name
  if (!is.null(only_in_reactions)) options[['only_in_reactions']] <- only_in_reactions
    result <- generic_request(
    endpoint = "chemicals/database",
    method = "GET",
    batch_limit = 0,
    server = server,
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
