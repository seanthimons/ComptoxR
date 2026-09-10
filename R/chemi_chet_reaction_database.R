#' Search reactions
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
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
#' @examples
#' \dontrun{
#' chemi_chet_reaction_database(page = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_chet_reaction_database <- function(
  page = 0,
  size = NULL,
  query = NULL,
  lib_name = NULL,
  reaction_process = NULL,
  reaction_type = NULL,
  reaction_scheme = NULL,
  reaction_phase = NULL,
  craccm_id = NULL,
  all_pages = TRUE,
  max_pages = 100
) {
  params <- list(
    "page" = page,
    "size" = size,
    "query" = query,
    "lib_name" = lib_name,
    "reaction_process" = reaction_process,
    "reaction_type" = reaction_type,
    "reaction_scheme" = reaction_scheme,
    "reaction_phase" = reaction_phase,
    "craccm_id" = craccm_id,
    "all_pages" = all_pages,
    "max_pages" = max_pages
  )
  result <- generic_request(
    "endpoint" = "reaction/database",
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
          "lib_name" = params[["lib_name"]],
          "reaction_process" = params[["reaction_process"]],
          "reaction_type" = params[["reaction_type"]],
          "reaction_scheme" = params[["reaction_scheme"]],
          "reaction_phase" = params[["reaction_phase"]],
          "craccm_id" = params[["craccm_id"]]
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
