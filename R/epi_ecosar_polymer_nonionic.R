#' ECOSAR nonionic polymer assessment
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param solubilityType Solubility classification of the polymer. Options: INSOLUBLE, DISPERSIBLE, SOLUBLE
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
#' epi_ecosar_polymer_nonionic(solubilityType = "50-00-0")
#' }
epi_ecosar_polymer_nonionic <- function(
  solubilityType = NULL,
  averageMolecularWeight = NULL,
  mw500Percentage = NULL,
  mw1000Percentage = NULL,
  cas = NULL,
  chemicalName = NULL
) {
  result <- generic_request(
    endpoint = "ecosar/polymer/nonionic",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `solubilityType` = solubilityType,
    `averageMolecularWeight` = averageMolecularWeight,
    `mw500Percentage` = mw500Percentage,
    `mw1000Percentage` = mw1000Percentage,
    `cas` = cas,
    `chemicalName` = chemicalName
  )

  result <- run_hook(
    "epi_ecosar_polymer_nonionic",
    "post_response",
    list(
      result = result,
      params = list(
        `solubilityType` = solubilityType,
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
