#' Generate groups for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Array of objects with optional id and smiles, or an array of SMILES strings for backward compatibility.
#' @param model Optional parameter. Options: RF, NN (default: RF)
#' @param smiles Array of SMILES strings, same input style as amnb_nate.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_arn_cats_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_arn_cats_bulk <- function(chemicals = NULL, model = "RF", smiles = NULL) {
  params <- base::list("chemicals" = chemicals, "model" = model, "smiles" = smiles)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/arn_cats",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      ids <- unique(as.vector(params[["chemicals"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      chemicals <- lapply(ids, function(id) base::list(sid = id))
      options <- Filter(Negate(is.null), base::list(model = params[["model"]], smiles = params[["smiles"]]))
      if (!length(options)) {
        options <- structure(list(), names = character())
      }
      if (TRUE) {
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
