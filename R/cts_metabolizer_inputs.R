#' Get the CTS metabolizer input template
#'
#' @noMd
#' @param body A named list of JSON fields. Use an empty list to fetch the template.
#' @return A list containing CTS metadata and the input template.
#' @export
#' @examples
#' \dontrun{
#' cts_metabolizer_inputs(body = structure(list(), names = character(0)))
#' }
# Generated with specmill; do not edit by hand.
cts_metabolizer_inputs <- function(body) {
  if (base::missing(body)) {
    base::stop("Required body")
  }
  if (!base::missing(body)) {
    body <- base::tryCatch(
      .api_validation$body_value(
        body,
        list(type = "object", properties = list(chemical = list(type = "string", default = "CCCC")))
      ),
      error = function(e) base::stop("Invalid body: ", base::conditionMessage(e), call. = FALSE)
    )
    if (base::is.null(body)) body <- jsonlite::unbox(NA)
  }
  params <- base::list("body" = body)
  result <- .ct_request(
    method = "POST",
    path = "/metabolizer/inputs",
    path_params = base::list(),
    query = base::list(),
    body = params[["body"]],
    server = list(url = "https://qed.epa.gov/cts/rest"),
    auth = list()
  )
  result
}
