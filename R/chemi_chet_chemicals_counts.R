#' Chemical counts by library
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param page page
#' @param size size
#' @param all_pages TRUE (the default) requests page after page, starting at page, until a page comes back empty or the client says it was the last or max_pages is reached, and returns the pages combined. FALSE requests only the page given in page.
#' @param max_pages Maximum number of pages requested when all_pages is TRUE. Reaching it stops paging with a warning.
#' @return A list of records.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_chet_chemicals_counts(page = 1L, all_pages = FALSE, max_pages = 2L)
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_chemicals_counts <- function(page = 1L, size = NULL, all_pages = TRUE, max_pages = 100L) {
  .api_validation$parameter_values(
    base::list("page" = page, "size" = size),
    list(page = list(type = "integer"), size = list(type = "integer")),
    .api_validation$body_value,
    c(page = "query", size = "query")
  )
  params <- base::list("page" = page, "size" = size)
  if (!base::is.logical(all_pages) || base::length(all_pages) != 1L || base::is.na(all_pages)) {
    base::stop("all_pages must be TRUE or FALSE", call. = FALSE)
  }
  if (base::is.character(params[["page"]]) && base::any(!base::nzchar(params[["page"]]))) {
    base::stop("Empty query parameter: page")
  }
  if (base::is.character(params[["size"]]) && base::any(!base::nzchar(params[["size"]]))) {
    base::stop("Empty query parameter: size")
  }
  send <- function(params) {
    result <- .ct_request(
      "method" = "GET",
      "path" = "/chemicals/counts",
      "path_params" = list(),
      "query" = base::list("page" = params[["page"]], "size" = params[["size"]]),
      "body" = NULL,
      "response_policy" = function(response, context, decode) {
        context$endpoint <- "chet/chemicals/counts"
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
  result <- run_hook("chemi_chet_chemicals_counts", "post_combine", base::list(result = result, params = params))
  if (!base::is.null(kept) && !base::is.null(result) && base::is.null(base::attr(result, "pagination", exact = TRUE))) {
    base::attr(result, "pagination") <- kept
  }
  result
}
