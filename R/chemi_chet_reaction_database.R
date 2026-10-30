#' Search reactions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param page page
#' @param size size
#' @param query query
#' @param lib_name lib_name
#' @param reaction_process reaction_process
#' @param reaction_type reaction_type
#' @param reaction_scheme reaction_scheme
#' @param reaction_phase reaction_phase
#' @param craccm_id craccm_id
#' @param all_pages TRUE (the default) requests page after page, starting at page, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in page.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning.
#' @return A list of records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database(page = 1L, all_pages = FALSE, max_pages = 2L)
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database <- function(
  page = 1L,
  size = NULL,
  query = NULL,
  lib_name = NULL,
  reaction_process = NULL,
  reaction_type = NULL,
  reaction_scheme = NULL,
  reaction_phase = NULL,
  craccm_id = NULL,
  all_pages = TRUE,
  max_pages = 100L
) {
  .api_validation$parameter_values(
    base::list(
      "page" = page,
      "size" = size,
      "query" = query,
      "lib_name" = lib_name,
      "reaction_process" = reaction_process,
      "reaction_type" = reaction_type,
      "reaction_scheme" = reaction_scheme,
      "reaction_phase" = reaction_phase,
      "craccm_id" = craccm_id
    ),
    list(
      page = list(type = "integer"),
      size = list(type = "integer"),
      query = list(type = "string"),
      lib_name = list(type = "string"),
      reaction_process = list(type = "string"),
      reaction_type = list(type = "string"),
      reaction_scheme = list(type = "string"),
      reaction_phase = list(type = "string"),
      craccm_id = list(type = "string")
    ),
    .api_validation$body_value,
    c(
      page = "query",
      size = "query",
      query = "query",
      lib_name = "query",
      reaction_process = "query",
      reaction_type = "query",
      reaction_scheme = "query",
      reaction_phase = "query",
      craccm_id = "query"
    )
  )
  params <- base::list(
    "page" = page,
    "size" = size,
    "query" = query,
    "lib_name" = lib_name,
    "reaction_process" = reaction_process,
    "reaction_type" = reaction_type,
    "reaction_scheme" = reaction_scheme,
    "reaction_phase" = reaction_phase,
    "craccm_id" = craccm_id
  )
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  if (base::is.character(params[["page"]]) && base::any(!base::nzchar(params[["page"]]))) {
    base::stop("Empty query parameter: page")
  }
  if (base::is.character(params[["size"]]) && base::any(!base::nzchar(params[["size"]]))) {
    base::stop("Empty query parameter: size")
  }
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  if (base::is.character(params[["lib_name"]]) && base::any(!base::nzchar(params[["lib_name"]]))) {
    base::stop("Empty query parameter: lib_name")
  }
  if (base::is.character(params[["reaction_process"]]) && base::any(!base::nzchar(params[["reaction_process"]]))) {
    base::stop("Empty query parameter: reaction_process")
  }
  if (base::is.character(params[["reaction_type"]]) && base::any(!base::nzchar(params[["reaction_type"]]))) {
    base::stop("Empty query parameter: reaction_type")
  }
  if (base::is.character(params[["reaction_scheme"]]) && base::any(!base::nzchar(params[["reaction_scheme"]]))) {
    base::stop("Empty query parameter: reaction_scheme")
  }
  if (base::is.character(params[["reaction_phase"]]) && base::any(!base::nzchar(params[["reaction_phase"]]))) {
    base::stop("Empty query parameter: reaction_phase")
  }
  if (base::is.character(params[["craccm_id"]]) && base::any(!base::nzchar(params[["craccm_id"]]))) {
    base::stop("Empty query parameter: craccm_id")
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/reaction/database",
      "path_params" = list(),
      "query" = base::list(
        "page" = params[["page"]],
        "size" = params[["size"]],
        "query" = params[["query"]],
        "lib_name" = params[["lib_name"]],
        "reaction_process" = params[["reaction_process"]],
        "reaction_type" = params[["reaction_type"]],
        "reaction_scheme" = params[["reaction_scheme"]],
        "reaction_phase" = params[["reaction_phase"]],
        "craccm_id" = params[["craccm_id"]]
      ),
      "body" = NULL,
      "response_policy" = function(response, context, decode) {
        context$endpoint <- "chet/reaction/database"
        if (all_pages) {
          return(.ct_chemi_page(response, context, decode))
        }
        context$query <- "_static_"
        .ct_keyset_manual(response, context, decode)
      },
      "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
      "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/api/chet"),
      "auth" = list(),
      "headers" = list(Accept = "application/json")
    )
    result
  }
  if (!base::isTRUE(all_pages)) {
    base::return(send(params))
  }
  if (base::is.null(params[["page"]])) {
    base::stop("Supply page to start paging, or set all_pages = FALSE", call. = FALSE)
  }
  result <- .ct_request_pages(
    function(page) {
      params[base::names(page)] <- page
      send(params)
    },
    "page",
    params[["page"]],
    max_pages,
    completed = base::get(
      ".ct_chemi_done",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    ),
    mode = "page",
    next_cursor = NULL,
    items = NULL,
    error_policy = "partial",
    warn_limits = TRUE,
    warn_errors = FALSE,
    stop_on_empty = FALSE,
    on_limit = base::get(
      ".ct_keyset_limit_warning",
      envir = base::environment(.ct_request_pages),
      mode = "function",
      inherits = FALSE
    )
  )
  if (!base::inherits(result, "httr2_request") && !base::is.null(result)) {
    base::attr(result, "pagination") <- NULL
  }
  result
  if (base::inherits(result, "httr2_request")) {
    base::return(result)
  }
  kept <- base::attr(result, "pagination", exact = TRUE)
  result <- run_hook("chemi_chet_reaction_database", "post_combine", base::list(result = result, params = params))
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "pagination", exact = TRUE))) {
    base::attr(result, "pagination") <- kept
  }
  result
}
