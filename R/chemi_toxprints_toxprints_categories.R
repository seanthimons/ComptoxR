#' Toxprints Toxprints Categories
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemical Optional parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_toxprints_categories(chemical = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_toxprints_categories <- function(chemical = NULL) {
  params <- base::list("chemical" = chemical)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/toxprints/toxprints_categories",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      options <- base::Filter(base::Negate(base::is.null), base::list())
      ids <- unique(as.vector(params[["chemical"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      if (!length(options)) {
        options <- stats::setNames(list(), character())
      }
      chemicals <- purrr::map(ids, function(id) stats::setNames(list(id), "sid"))
      if (FALSE) {
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
      context$endpoint <- "toxprints/toxprints_categories"
      .ct_chemi_result(response, context, decode, tidy = FALSE)
    },
    "request_controls" = list(preserve_errors = TRUE)
  )
  result
}
