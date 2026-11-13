#' Generate NCC categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Chemicals to classify, as a character vector of SMILES or of DTXSID, DTXCID or CASRN identifiers, which are resolved to SMILES first (names, if any, are sent as ids, otherwise the identifier or SMILES is; duplicates are dropped), a data frame with id and smiles columns and optional logp and ws columns, or a list of such records. Identifiers inside records are not resolved.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(chemicals = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_ncc_cats_bulk <- function(chemicals = NULL) {
  params <- base::list("chemicals" = chemicals)
  state <- run_hook("chemi_ncc_cats_bulk", "pre_request", base::list(params = params))
  if (base::isTRUE(state$skip_request)) {
    base::return(state$result)
  }
  changed <- base::intersect(base::names(params), base::names(state$params))
  params[changed] <- state$params[changed]
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/ncc_cats",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      body <- base::list(chemicals = params[["chemicals"]])
      for (name in base::intersect(c("chemicals", "smiles"), base::names(body))) {
        value <- body[[name]]
        if (base::is.atomic(value)) {
          value <- value[!base::is.na(value) & value != ""]
          ids <- base::names(value)
          if (base::is.null(ids)) {
            ids <- base::rep("", base::length(value))
          }
          value <- base::unname(value)
          blank <- base::is.na(ids) | ids == ""
          ids[blank] <- value[blank]
          keep <- !base::duplicated(base::cbind(ids, value))
          ids <- ids[keep]
          value <- value[keep]
          body[[name]] <- if (name == "chemicals") {
            base::lapply(base::seq_along(value), function(i) base::list(id = ids[[i]], smiles = value[[i]]))
          } else {
            base::as.list(base::unique(value))
          }
        }
      }
      body <- base::Filter(base::length, body)
      if (!base::length(base::intersect(c("chemicals", "smiles"), base::names(body)))) {
        cli::cli_abort("Supply chemicals or smiles.")
      }
      body
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    "auth" = NULL,
    "response_policy" = ".ct_prediction"
  )
  result
}
