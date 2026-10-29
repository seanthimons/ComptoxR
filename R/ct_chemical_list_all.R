#' Get all lists
#'
#' @md
#' @description
#' `r lifecycle::badge("stable")`
#' @param projection Projection options for chemical lists: chemicallistall, chemicallistwithdtxsids, chemicallistname, or ccdchemicaldetaillists.
#' @param return_dtxsid Return all DTXSIDs contained within each list.
#' @param coerce Split DTXSID strings into per-list vectors when return_dtxsid is TRUE.
#' @return A tibble of chemical lists, or a named list when both return_dtxsid and coerce are TRUE.
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' ct_chemical_list_all(projection = "chemicallistall")
#' }
# Generated with specmill; do not edit by hand.
ct_chemical_list_all <- function(projection = "chemicallistall", return_dtxsid = FALSE, coerce = FALSE) {
  params <- base::list("projection" = projection, "return_dtxsid" = return_dtxsid, "coerce" = coerce)
  state <- run_hook("ct_chemical_list_all", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "GET",
    "path" = "/chemical/list/all",
    "path_params" = structure(list(), names = character(0)),
    "query" = base::list("projection" = params[["projection"]]),
    "body" = NULL,
    "headers" = list(Accept = "application/json"),
    "server" = list(url = "https://comptox.epa.gov/ctx-api"),
    "server_resolver" = list(name = ".ct_server_url", key = "ctx_burl"),
    "auth" = list(list(list(
      scheme = "ctx",
      type = "apiKey",
      location = "header",
      name = "x-api-key",
      envvar = "ctx_api_key"
    ))),
    "response_policy" = ".ct_list_all"
  )
  result <- run_hook("ct_chemical_list_all", "post_response", base::list(result = result, params = params))
  result
}
