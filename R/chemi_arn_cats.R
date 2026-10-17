#' Generate an ARN category for one molecule
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param smiles smiles
#' @param model model
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_arn_cats(smiles = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_arn_cats <- function(smiles, model = "RF") {
  if (base::is.null(smiles)) {
    base::stop("Required input: smiles")
  }
  .api_validation$parameter_values(
    base::list("smiles" = smiles, "model" = model),
    list(smiles = list(type = "string"), model = list(default = "RF", enum = list("RF", "NN"), type = "string")),
    .api_validation$body_value,
    c(smiles = "query", model = "query")
  )
  params <- base::list("smiles" = smiles, "model" = model)
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  if (base::is.character(params[["model"]]) && base::any(!base::nzchar(params[["model"]]))) {
    base::stop("Empty query parameter: model")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/arn_cats",
    path_params = base::list(),
    query = base::list("smiles" = params[["smiles"]], "model" = params[["model"]]),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "chemi_burl", relative = ""),
    auth = list()
  )
  result
}

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
