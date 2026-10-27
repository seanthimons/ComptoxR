#' Generate PFAS Atlas categories for multiple molecules
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param chemicals Either an array of input chemicals with optional id and required smiles, or an array of SMILES strings for backward compatibility.
#' @param smiles Array of SMILES strings, kept for backward compatibility with the previous PFAS Atlas POST format.
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_pfas_atlas_bulk(chemicals = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_pfas_atlas_bulk <- function(chemicals = NULL, smiles = NULL) {
  params <- base::list("chemicals" = chemicals, "smiles" = smiles)
  result <- .ct_request(
    "method" = "POST",
    "path" = "/api/pfas_atlas",
    "path_params" = structure(list(), names = character(0)),
    "query" = structure(list(), names = character(0)),
    "body" = base::local({
      ids <- unique(as.vector(params[["chemicals"]]))
      ids <- ids[!is.na(ids) & ids != ""]
      if (!length(ids)) {
        cli::cli_abort("Either query or chemicals parameter must be provided.")
      }
      chemicals <- lapply(ids, function(id) base::list(sid = id))
      options <- Filter(Negate(is.null), base::list(smiles = params[["smiles"]]))
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
