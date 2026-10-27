#' Generate NCC categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Array of input chemicals with optional id, smiles, logp, and ws. Missing smiles are returned as item-level errors.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_ncc_cats_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_ncc_cats_bulk <- function(chemicals = NULL) {
  params <- base::list("chemicals" = chemicals)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/ncc_cats",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      ids <- unique(as.vector(params[["chemicals"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      chemicals <- lapply(ids, function(id) base::list(sid = id))
      options <- Filter(Negate(is.null), base::list())
      if (!length(options)) {
        options <- structure(list(), names = character())
      }
      if (FALSE) {
        base::list(chemicals = chemicals, options = options)
      } else {
        chemicals
      }
    }),
    "headers" = list(Accept = "application/json"),
    "server" = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    "server_resolver" = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    "auth" = NULL,
    "response_policy" = ".ct_prediction"
  )
  result
}
