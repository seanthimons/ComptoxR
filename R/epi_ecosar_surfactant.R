#' ECOSAR surfactant predictions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param type Surfactant type. Type: string. Options: anionic, cationic, amphoteric
#' @param carbonChainLength Carbon chain length of the surfactant (default: 0)
#' @param ethoxylate Ethoxylate groups for amphoteric surfactants (default: 0)
#' @param waterSolubility Water solubility in mg/L (default: 0)
#' @param cas CAS registry number
#' @param chemicalName Chemical name
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_surfactant(type = "50-00-0")
#' }
epi_ecosar_surfactant <- function(
  type,
  carbonChainLength = 0,
  ethoxylate = 0,
  waterSolubility = 0,
  cas = NULL,
  chemicalName = NULL
) {
  result <- generic_request(
    query = type,
    endpoint = "ecosar/surfactant",
    method = "GET",
    batch_limit = 1,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `carbonChainLength` = carbonChainLength,
    `ethoxylate` = ethoxylate,
    `waterSolubility` = waterSolubility,
    `cas` = cas,
    `chemicalName` = chemicalName
  )

  result <- run_hook(
    "epi_ecosar_surfactant",
    "post_response",
    list(
      result = result,
      params = list(
        `type` = type,
        `carbonChainLength` = carbonChainLength,
        `ethoxylate` = ethoxylate,
        `waterSolubility` = waterSolubility,
        `cas` = cas,
        `chemicalName` = chemicalName
      )
    )
  )
  # Additional post-processing can be added here

  return(result)
}
