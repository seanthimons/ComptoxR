#' ToxPrint Chemotyper
#'
#' @noMd
#' @param query A list of DTXSIDs
#' @param odds_ratio numeric
#' @param p_val numeric
#' @param true_pos numeric
#' @return A dataframe.
#' @export
#' @examples
#' \dontrun{
#' chemi_toxprint(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_toxprint <- function(query, odds_ratio = 3L, p_val = 0.05, true_pos = 3) {
  query <- base::get(
    ".ct_toxprint_query",
    envir = base::parent.env(base::environment()),
    mode = "function",
    inherits = TRUE
  )(query)
  params <- base::list("query" = query, "odds_ratio" = odds_ratio, "p_val" = p_val, "true_pos" = true_pos)
  .ct_request(
    "method" = "POST",
    "path" = "/api/toxprints/calculate",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::list(
      "chemicals" = lapply(params[["query"]], function(id) base::list(sid = id)),
      "options" = base::list("OR" = params[["odds_ratio"]], "PV1" = params[["p_val"]], "TP" = params[["true_pos"]])
    ),
    "headers" = list(Accept = "application/json"),
    "server" = list(),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = "/"),
    "auth" = list(),
    "response_policy" = function(response, context, decode) {
      context$query <- params[["query"]]
      .ct_chemi_tidy(response, context, decode)
    }
  )
}
