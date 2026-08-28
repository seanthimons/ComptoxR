#' Search reactions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param page Optional parameter
#' @param size Optional parameter
#' @param query Optional parameter
#' @param lib_name Optional parameter
#' @param reaction_process Optional parameter
#' @param reaction_type Optional parameter
#' @param reaction_scheme Optional parameter
#' @param reaction_phase Optional parameter
#' @param craccm_id Optional parameter
#' @param all_pages Logical; if TRUE (default), automatically fetches all pages. If FALSE, returns a single page using manual pagination parameters.
#' @param max_pages Maximum number of pages to fetch when all_pages is TRUE.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database(page = "DTXSID7020182")
#' }
chemi_chet_reaction_database <- function(page = 0, size = NULL, query = NULL, lib_name = NULL, reaction_process = NULL, reaction_type = NULL, reaction_scheme = NULL, reaction_phase = NULL, craccm_id = NULL, all_pages = TRUE, max_pages = 100) {
  server <- "chemi_burl"
  req_data <- run_hook("chemi_chet_reaction_database", "pre_request", list(params = list(`page` = page, `size` = size, `query` = query, `lib_name` = lib_name, `reaction_process` = reaction_process, `reaction_type` = reaction_type, `reaction_scheme` = reaction_scheme, `reaction_phase` = reaction_phase, `craccm_id` = craccm_id, `all_pages` = all_pages, `max_pages` = max_pages, `server` = server)))
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
  if ("lib_name" %in% names(req_data$params)) {
    lib_name <- req_data$params[["lib_name"]]
  }
  if ("reaction_process" %in% names(req_data$params)) {
    reaction_process <- req_data$params[["reaction_process"]]
  }
  if ("reaction_type" %in% names(req_data$params)) {
    reaction_type <- req_data$params[["reaction_type"]]
  }
  if ("reaction_scheme" %in% names(req_data$params)) {
    reaction_scheme <- req_data$params[["reaction_scheme"]]
  }
  if ("reaction_phase" %in% names(req_data$params)) {
    reaction_phase <- req_data$params[["reaction_phase"]]
  }
  if ("craccm_id" %in% names(req_data$params)) {
    craccm_id <- req_data$params[["craccm_id"]]
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
  if (!is.null(lib_name)) options[['lib_name']] <- lib_name
  if (!is.null(reaction_process)) options[['reaction_process']] <- reaction_process
  if (!is.null(reaction_type)) options[['reaction_type']] <- reaction_type
  if (!is.null(reaction_scheme)) options[['reaction_scheme']] <- reaction_scheme
  if (!is.null(reaction_phase)) options[['reaction_phase']] <- reaction_phase
  if (!is.null(craccm_id)) options[['craccm_id']] <- craccm_id
    result <- generic_request(
    endpoint = "reaction/database",
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
