#' Stdizer Records
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param full Optional parameter
#' @param options Optional parameter
#' @param records Optional parameter
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_stdizer_records(full = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_stdizer_records <- function(full = NULL, options = NULL, records = NULL) {
  params <- base::list("full" = full, "options" = options, "records" = records)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/stdizer/records",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      options <- base::Filter(
        base::Negate(base::is.null),
        base::list(options = params[["options"]], records = params[["records"]])
      )
      ids <- unique(as.vector(params[["full"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      if (!length(options)) {
        options <- stats::setNames(list(), character())
      }
      chemicals <- purrr::map(ids, function(id) stats::setNames(list(id), "sid"))
      if (TRUE) {
        list(chemicals = chemicals, options = options)
      } else {
        chemicals
      }
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://hcd.rtpnc.epa.gov"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      if (context$status >= 400L) {
        decode()
      }
      context$endpoint <- "stdizer/records"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
