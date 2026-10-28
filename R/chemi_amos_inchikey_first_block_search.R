#' Returns a list of substances found by InChIKey
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param first_block First block of an InChIKey. Accepts a vector: one request is sent per element and the results are combined.
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_inchikey_first_block_search(first_block = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_inchikey_first_block_search <- function(first_block) {
  first_block <- base::get(
    ".ct_legacy_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(first_block)
  if (base::is.null(first_block)) {
    base::stop("Required input: first_block")
  }
  .api_validation$parameter_values(
    base::list("first_block" = first_block),
    list(
      first_block = list(
        type = "array",
        items = list(description = "First block of an InChIKey.", "in" = "path", name = "first_block", type = "string")
      )
    ),
    .api_validation$body_value,
    c(first_block = "path")
  )
  params <- base::list("first_block" = first_block)
  send <- function(params) {
    result <- .ct_request(
      method = "GET",
      path = "/api/amos/inchikey_first_block_search/{first_block}",
      path_params = base::list("first_block" = params[["first_block"]]),
      query = base::list(),
      body = NULL,
      response_policy = ".ct_list",
      server = list(diagnostic = "Swagger host/scheme requires a recorded origin or explicit base URL override"),
      server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
      auth = list()
    )
    result
  }
  .ct_request_each(
    function(chunk) {
      params["first_block"] <- base::list(chunk)
      send(params)
    },
    params[["first_block"]],
    1L,
    on_error = "drop"
  )
}
