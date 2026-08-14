#' ECOSAR nonionic surfactant predictions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param mainCarbons Number of main chain carbons (default: 0)
#' @param branchedCarbons Number of branched carbons (default: 0)
#' @param branches Number of branches (default: 0)
#' @param propoxyGroups Number of propoxy groups (default: 0)
#' @param ethoxylate Number of ethoxylate groups (default: 0)
#' @param waterSolubility Water solubility in mg/L (default: 0)
#' @param logKow Log octanol-water partition coefficient (default: 0)
#' @param molecularWeight Molecular weight in g/mol (default: 0)
#' @param cas CAS registry number
#' @param chemicalName Chemical name
#' @param smiles SMILES notation
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant_nonionic(mainCarbons = "0")
#' }
epi_ecosar_surfactant_nonionic <- function(
  mainCarbons = 0,
  branchedCarbons = 0,
  branches = 0,
  propoxyGroups = 0,
  ethoxylate = 0,
  waterSolubility = 0,
  logKow = 0,
  molecularWeight = 0,
  cas = NULL,
  chemicalName = NULL,
  smiles = NULL
) {
  result <- generic_request(
    endpoint = "ecosar/surfactant/nonionic",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `mainCarbons` = mainCarbons,
    `branchedCarbons` = branchedCarbons,
    `branches` = branches,
    `propoxyGroups` = propoxyGroups,
    `ethoxylate` = ethoxylate,
    `waterSolubility` = waterSolubility,
    `logKow` = logKow,
    `molecularWeight` = molecularWeight,
    `cas` = cas,
    `chemicalName` = chemicalName,
    `smiles` = smiles
  )

  result <- run_hook(
    "epi_ecosar_surfactant_nonionic",
    "post_response",
    list(
      result = result,
      params = list(
        `mainCarbons` = mainCarbons,
        `branchedCarbons` = branchedCarbons,
        `branches` = branches,
        `propoxyGroups` = propoxyGroups,
        `ethoxylate` = ethoxylate,
        `waterSolubility` = waterSolubility,
        `logKow` = logKow,
        `molecularWeight` = molecularWeight,
        `cas` = cas,
        `chemicalName` = chemicalName,
        `smiles` = smiles
      )
    )
  )
  # Additional post-processing can be added here

  return(result)
}
