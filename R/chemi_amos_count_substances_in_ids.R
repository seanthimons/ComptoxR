#' Counts the number of unique substances seen in a set of records.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param internal_id_list Array of record IDs.
#' @return The decoded JSON result from the AMOS read operation.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_count_substances_in_ids(internal_id_list = "NO_SUCH_INTERNAL_ID")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_count_substances_in_ids <- function(internal_id_list = NULL) {
  internal_id_list <- base::get(
    ".ct_amos_identifier_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(internal_id_list)
  params <- base::list("internal_id_list" = internal_id_list)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/count_substances_in_ids/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = .api_validation$body_value(
      stats::setNames(base::list(params[["internal_id_list"]]), "internal_id_list"),
      structure(
        list(
          properties = list(
            internal_id_list = list(
              description = "Array of record IDs.",
              example = list("GJ-004", "FS-26369", "1CGr7ZTsFv4"),
              items = list(type = "string"),
              type = "array"
            )
          ),
          type = "object"
        ),
        specmill_id = "#/definitions/count_substances_in_ids_request"
      )
    ),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/count_substances_in_ids/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
