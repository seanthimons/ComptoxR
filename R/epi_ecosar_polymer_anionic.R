#' Estimate an anionic polymer
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param solubilityType solubilityType
#' @param averageMolecularWeight averageMolecularWeight
#' @param mw500Percentage mw500Percentage
#' @param mw1000Percentage mw1000Percentage
#' @param cas cas
#' @param chemicalName chemicalName
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_polymer_anionic(solubilityType = "INSOLUBLE")
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_polymer_anionic <- function(
  solubilityType,
  averageMolecularWeight = NULL,
  mw500Percentage = NULL,
  mw1000Percentage = NULL,
  cas = NULL,
  chemicalName = NULL
) {
  if (base::is.null(solubilityType)) {
    base::stop("Required input: solubilityType")
  }
  .api_validation$parameter_values(
    base::list(
      "solubilityType" = solubilityType,
      "averageMolecularWeight" = averageMolecularWeight,
      "mw500Percentage" = mw500Percentage,
      "mw1000Percentage" = mw1000Percentage,
      "cas" = cas,
      "chemicalName" = chemicalName
    ),
    list(
      solubilityType = list(enum = list("INSOLUBLE", "DISPERSIBLE", "SOLUBLE"), type = "string"),
      averageMolecularWeight = list(minimum = 0L, type = "number"),
      mw500Percentage = list(maximum = 100L, minimum = 0L, type = "number"),
      mw1000Percentage = list(maximum = 100L, minimum = 0L, type = "number"),
      cas = list(type = "string"),
      chemicalName = list(type = "string")
    ),
    .api_validation$body_value,
    c(
      solubilityType = "query",
      averageMolecularWeight = "query",
      mw500Percentage = "query",
      mw1000Percentage = "query",
      cas = "query",
      chemicalName = "query"
    )
  )
  params <- base::list(
    "solubilityType" = solubilityType,
    "averageMolecularWeight" = averageMolecularWeight,
    "mw500Percentage" = mw500Percentage,
    "mw1000Percentage" = mw1000Percentage,
    "cas" = cas,
    "chemicalName" = chemicalName
  )
  if (base::is.character(params[["solubilityType"]]) && base::any(!base::nzchar(params[["solubilityType"]]))) {
    base::stop("Empty query parameter: solubilityType")
  }
  if (
    base::is.character(params[["averageMolecularWeight"]]) &&
      base::any(!base::nzchar(params[["averageMolecularWeight"]]))
  ) {
    base::stop("Empty query parameter: averageMolecularWeight")
  }
  if (base::is.character(params[["mw500Percentage"]]) && base::any(!base::nzchar(params[["mw500Percentage"]]))) {
    base::stop("Empty query parameter: mw500Percentage")
  }
  if (base::is.character(params[["mw1000Percentage"]]) && base::any(!base::nzchar(params[["mw1000Percentage"]]))) {
    base::stop("Empty query parameter: mw1000Percentage")
  }
  if (base::is.character(params[["cas"]]) && base::any(!base::nzchar(params[["cas"]]))) {
    base::stop("Empty query parameter: cas")
  }
  if (base::is.character(params[["chemicalName"]]) && base::any(!base::nzchar(params[["chemicalName"]]))) {
    base::stop("Empty query parameter: chemicalName")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/ecosar/polymer/anionic",
    path_params = base::list(),
    query = base::list(
      "solubilityType" = params[["solubilityType"]],
      "averageMolecularWeight" = params[["averageMolecularWeight"]],
      "mw500Percentage" = params[["mw500Percentage"]],
      "mw1000Percentage" = params[["mw1000Percentage"]],
      "cas" = params[["cas"]],
      "chemicalName" = params[["chemicalName"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    auth = list()
  )
  result
}
