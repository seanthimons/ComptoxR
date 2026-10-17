#' Toxprints Global Assays
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param category category
#' @param label label
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprints_global_assays()
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprints_global_assays <- function(category = NULL, label = NULL) {
  .api_validation$parameter_values(
    base::list("category" = category, "label" = label),
    list(category = list(type = "string"), label = list(type = "string")),
    .api_validation$body_value,
    c(category = "query", label = "query")
  )
  params <- base::list("category" = category, "label" = label)
  if (base::is.character(params[["category"]]) && base::any(!base::nzchar(params[["category"]]))) {
    base::stop("Empty query parameter: category")
  }
  if (base::is.character(params[["label"]]) && base::any(!base::nzchar(params[["label"]]))) {
    base::stop("Empty query parameter: label")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/toxprints/global_assays",
    path_params = base::list(),
    query = base::list("category" = params[["category"]], "label" = params[["label"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
