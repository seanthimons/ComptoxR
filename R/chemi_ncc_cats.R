#' Generate NCC categories for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param logp logp
#' @param ws ws
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_ncc_cats(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_ncc_cats <- function(smiles, logp = NULL, ws = NULL) {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "logp" = logp, "ws" = ws),
    list(smiles = list(type = "string"), logp = list(type = "string"), ws = list(type = "string")),
    .api_validation$body_value,
    c(smiles = "query", logp = "query", ws = "query")
  )
  params <- base::list("smiles" = smiles, "logp" = logp, "ws" = ws)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["logp"]]) && base::any(!base::nzchar(params[["logp"]]))) {
    base::stop("Empty query parameter: logp")
  }
  if (base::is.character(params[["ws"]]) && base::any(!base::nzchar(params[["ws"]]))) {
    base::stop("Empty query parameter: ws")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/ncc_cats",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "logp" = params[["logp"]], "ws" = params[["ws"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}
