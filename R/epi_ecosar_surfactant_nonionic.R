#' Estimate a nonionic surfactant
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param mainCarbons mainCarbons
#' @param branchedCarbons branchedCarbons
#' @param branches branches
#' @param propoxyGroups propoxyGroups
#' @param ethoxylate ethoxylate
#' @param waterSolubility waterSolubility
#' @param logKow logKow
#' @param molecularWeight molecularWeight
#' @param cas cas
#' @param chemicalName chemicalName
#' @param smiles smiles
#' @param useSmiles useSmiles
#' @return Returns a named list of result modules
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_nonionic(mainCarbons = 12L, waterSolubility = 100, logKow = 3, molecularWeight = 250)
#' }
# Generated with specmill; do not edit by hand.
epi_ecosar_surfactant_nonionic <- function(
  mainCarbons,
  branchedCarbons = 0L,
  branches = 0L,
  propoxyGroups = 0,
  ethoxylate = 0L,
  waterSolubility = NULL,
  logKow = NULL,
  molecularWeight = NULL,
  cas = NULL,
  chemicalName = NULL,
  smiles = NULL,
  useSmiles = FALSE
) {
  if (base::is.null(mainCarbons)) {
    base::stop("Required input: mainCarbons")
  }
  .api_validation$parameter_values(
    base::list(
      "mainCarbons" = mainCarbons,
      "branchedCarbons" = branchedCarbons,
      "branches" = branches,
      "propoxyGroups" = propoxyGroups,
      "ethoxylate" = ethoxylate,
      "waterSolubility" = waterSolubility,
      "logKow" = logKow,
      "molecularWeight" = molecularWeight,
      "cas" = cas,
      "chemicalName" = chemicalName,
      "smiles" = smiles,
      "useSmiles" = useSmiles
    ),
    list(
      mainCarbons = list(minimum = 1L, type = "integer"),
      branchedCarbons = list(default = 0L, minimum = 0L, type = "integer"),
      branches = list(default = 0L, minimum = 0L, type = "integer"),
      propoxyGroups = list(default = 0L, minimum = 0L, type = "number"),
      ethoxylate = list(default = 0L, minimum = 0L, type = "integer"),
      waterSolubility = list(exclusiveMinimum = TRUE, minimum = 0L, type = "number"),
      logKow = list(type = "number"),
      molecularWeight = list(exclusiveMinimum = TRUE, minimum = 0L, type = "number"),
      cas = list(type = "string"),
      chemicalName = list(type = "string"),
      smiles = list(type = "string"),
      useSmiles = list(default = FALSE, type = "boolean")
    ),
    .api_validation$body_value,
    c(
      mainCarbons = "query",
      branchedCarbons = "query",
      branches = "query",
      propoxyGroups = "query",
      ethoxylate = "query",
      waterSolubility = "query",
      logKow = "query",
      molecularWeight = "query",
      cas = "query",
      chemicalName = "query",
      smiles = "query",
      useSmiles = "query"
    )
  )
  params <- base::list(
    "mainCarbons" = mainCarbons,
    "branchedCarbons" = branchedCarbons,
    "branches" = branches,
    "propoxyGroups" = propoxyGroups,
    "ethoxylate" = ethoxylate,
    "waterSolubility" = waterSolubility,
    "logKow" = logKow,
    "molecularWeight" = molecularWeight,
    "cas" = cas,
    "chemicalName" = chemicalName,
    "smiles" = smiles,
    "useSmiles" = useSmiles
  )
  if (base::is.character(params[["mainCarbons"]]) && base::any(!base::nzchar(params[["mainCarbons"]]))) {
    base::stop("Empty query parameter: mainCarbons")
  }
  if (base::is.character(params[["branchedCarbons"]]) && base::any(!base::nzchar(params[["branchedCarbons"]]))) {
    base::stop("Empty query parameter: branchedCarbons")
  }
  if (base::is.character(params[["branches"]]) && base::any(!base::nzchar(params[["branches"]]))) {
    base::stop("Empty query parameter: branches")
  }
  if (base::is.character(params[["propoxyGroups"]]) && base::any(!base::nzchar(params[["propoxyGroups"]]))) {
    base::stop("Empty query parameter: propoxyGroups")
  }
  if (base::is.character(params[["ethoxylate"]]) && base::any(!base::nzchar(params[["ethoxylate"]]))) {
    base::stop("Empty query parameter: ethoxylate")
  }
  if (base::is.character(params[["waterSolubility"]]) && base::any(!base::nzchar(params[["waterSolubility"]]))) {
    base::stop("Empty query parameter: waterSolubility")
  }
  if (base::is.character(params[["logKow"]]) && base::any(!base::nzchar(params[["logKow"]]))) {
    base::stop("Empty query parameter: logKow")
  }
  if (base::is.character(params[["molecularWeight"]]) && base::any(!base::nzchar(params[["molecularWeight"]]))) {
    base::stop("Empty query parameter: molecularWeight")
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
  if (base::is.character(params[["useSmiles"]]) && base::any(!base::nzchar(params[["useSmiles"]]))) {
    base::stop("Empty query parameter: useSmiles")
  }
  result <- .ct_request(
    method = "GET",
    path = "/api/ecosar/surfactant/nonionic",
    path_params = base::list(),
    query = base::list(
      "mainCarbons" = params[["mainCarbons"]],
      "branchedCarbons" = params[["branchedCarbons"]],
      "branches" = params[["branches"]],
      "propoxyGroups" = params[["propoxyGroups"]],
      "ethoxylate" = params[["ethoxylate"]],
      "waterSolubility" = params[["waterSolubility"]],
      "logKow" = params[["logKow"]],
      "molecularWeight" = params[["molecularWeight"]],
      "cas" = params[["cas"]],
      "chemicalName" = params[["chemicalName"]],
      "smiles" = params[["smiles"]],
      "useSmiles" = params[["useSmiles"]]
    ),
    body = NULL,
    response_policy = ".ct_static_list",
    server = list(diagnostic = "Relative server URL requires a recorded origin or explicit base URL override"),
    server_resolver = list(name = ".ct_server_url", key = "epi_burl", relative = "/"),
    auth = list()
  )
  result <- run_hook("epi_ecosar_surfactant_nonionic", "post_response", base::list(result = result, params = params))
  result
}
