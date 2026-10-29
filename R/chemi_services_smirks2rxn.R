#' Services Smirks2rxn
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smirks smirks
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_services_smirks2rxn(smirks = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_services_smirks2rxn <- function(smirks) {
  if (base::is.null(smirks)) {
    base::stop("Required input: smirks")
  }
  .api_validation$parameter_values(
    base::list("smirks" = smirks),
    list(smirks = list(type = "string")),
    .api_validation$body_value,
    c(smirks = "query")
  )
  params <- base::list("smirks" = smirks)
  if (base::is.character(params[["smirks"]]) && base::any(!base::nzchar(params[["smirks"]]))) {
    base::stop("Empty query parameter: smirks")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/services/smirks2rxn",
    path_params = base::list(),
    query = base::list("smirks" = params[["smirks"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    auth = list()
  )
  result
}
