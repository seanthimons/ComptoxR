#' ECOSAR polymer assessment
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Polymer type. Type: string. Options: anionic, amphoteric, polycationic
#' @param amineNitrogens Percent amine nitrogen for amphoteric and polycationic polymers
#' @param solubilityType Solubility classification for anionic and amphoteric polymers. Options: INSOLUBLE, DISPERSIBLE, SOLUBLE
#' @param polymerType Polymer backbone type. Options: Carbon, Silicon, Natural
#' @param cationAnionRatio Cation to anion ratio (CAR) for amphoteric polymers
#' @param averageMolecularWeight Average molecular weight in daltons
#' @param mw500Percentage Percentage of polymer with MW < 500 daltons
#' @param mw1000Percentage Percentage of polymer with MW < 1000 daltons
#' @param cas CAS registry number
#' @param chemicalName Chemical name
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_polymer(type = "50-00-0")
#' }
epi_ecosar_polymer <- function(
  type,
  amineNitrogens = NULL,
  solubilityType = NULL,
  polymerType = NULL,
  cationAnionRatio = NULL,
  averageMolecularWeight = NULL,
  mw500Percentage = NULL,
  mw1000Percentage = NULL,
  cas = NULL,
  chemicalName = NULL
) {
  result <- generic_request(
    query = type,
    endpoint = "ecosar/polymer",
    method = "GET",
    batch_limit = 1,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `amineNitrogens` = amineNitrogens,
    `solubilityType` = solubilityType,
    `polymerType` = polymerType,
    `cationAnionRatio` = cationAnionRatio,
    `averageMolecularWeight` = averageMolecularWeight,
    `mw500Percentage` = mw500Percentage,
    `mw1000Percentage` = mw1000Percentage,
    `cas` = cas,
    `chemicalName` = chemicalName
  )

  result <- run_hook(
    "epi_ecosar_polymer",
    "post_response",
    list(
      result = result,
      params = list(
        `type` = type,
        `amineNitrogens` = amineNitrogens,
        `solubilityType` = solubilityType,
        `polymerType` = polymerType,
        `cationAnionRatio` = cationAnionRatio,
        `averageMolecularWeight` = averageMolecularWeight,
        `mw500Percentage` = mw500Percentage,
        `mw1000Percentage` = mw1000Percentage,
        `cas` = cas,
        `chemicalName` = chemicalName
      )
    )
  )
  # Additional post-processing can be added here

  return(result)
}
