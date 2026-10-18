#' Returns substance information and record counts for a list of DTXSIDs.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param dtxsids Array of DTXSIDs as strings.
#' @return Returns the decoded JSON result
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_dtxsids(dtxsids = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_dtxsids <- function(dtxsids = NULL) {
  params <- base::list("dtxsids" = dtxsids)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/amos/dtxsids/",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      ids <- unique(as.vector(params[["dtxsids"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Supply at least one DTXSID.")
      }
      base::list(dtxsids = base::I(ids))
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$endpoint <- "amos/dtxsids/"
      .ct_amos_read_json(response, context, decode)
    }
  )
  result
}
