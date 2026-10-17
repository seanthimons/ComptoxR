#' Estimate an amphoteric surfactant
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param carbonChainLength carbonChainLength
#' @param ethoxylate ethoxylate
#' @param waterSolubility waterSolubility
#' @param cas cas
#' @param chemicalName chemicalName
#' @param smiles smiles
#' @return Returns a list of results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_amphoteric(carbonChainLength = 8L)
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_surfactant_amphoteric <- function(
  carbonChainLength,
  ethoxylate = 0L,
  waterSolubility = NULL,
  cas = NULL,
  chemicalName = NULL,
  smiles = NULL
) {
  if (base::is.null(carbonChainLength)) {
    base::stop("Required input: carbonChainLength")
  }
  .api_validation$parameter_values(
    base::list(
      "carbonChainLength" = carbonChainLength,
      "ethoxylate" = ethoxylate,
      "waterSolubility" = waterSolubility,
      "cas" = cas,
      "chemicalName" = chemicalName,
      "smiles" = smiles
    ),
    list(
      carbonChainLength = list(maximum = 18L, minimum = 8L, type = "integer"),
      ethoxylate = list(default = 0L, minimum = 0L, type = "integer"),
      waterSolubility = list(exclusiveMinimum = TRUE, minimum = 0L, type = "number"),
      cas = list(type = "string"),
      chemicalName = list(type = "string"),
      smiles = list(type = "string")
    ),
    .api_validation$body_value,
    c(
      carbonChainLength = "query",
      ethoxylate = "query",
      waterSolubility = "query",
      cas = "query",
      chemicalName = "query",
      smiles = "query"
    )
  )
  params <- base::list(
    "carbonChainLength" = carbonChainLength,
    "ethoxylate" = ethoxylate,
    "waterSolubility" = waterSolubility,
    "cas" = cas,
    "chemicalName" = chemicalName,
    "smiles" = smiles
  )
  if (base::is.character(params[["carbonChainLength"]]) && base::any(!base::nzchar(params[["carbonChainLength"]]))) {
    base::stop("Empty query parameter: carbonChainLength")
  }
  if (base::is.character(params[["ethoxylate"]]) && base::any(!base::nzchar(params[["ethoxylate"]]))) {
    base::stop("Empty query parameter: ethoxylate")
  }
  if (base::is.character(params[["waterSolubility"]]) && base::any(!base::nzchar(params[["waterSolubility"]]))) {
    base::stop("Empty query parameter: waterSolubility")
  }
  if (base::is.character(params[["cas"]]) && base::any(!base::nzchar(params[["cas"]]))) {
    base::stop("Empty query parameter: cas")
  }
  if (base::is.character(params[["chemicalName"]]) && base::any(!base::nzchar(params[["chemicalName"]]))) {
    base::stop("Empty query parameter: chemicalName")
  }
  if (base::is.character(params[["smiles"]]) && base::any(!base::nzchar(params[["smiles"]]))) {
    base::stop("Empty query parameter: smiles")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/ecosar/surfactant/amphoteric",
    path_params = base::list(),
    query = base::list(
      "carbonChainLength" = params[["carbonChainLength"]],
      "ethoxylate" = params[["ethoxylate"]],
      "waterSolubility" = params[["waterSolubility"]],
      "cas" = params[["cas"]],
      "chemicalName" = params[["chemicalName"]],
      "smiles" = params[["smiles"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    auth = list()
  )
  result
}
