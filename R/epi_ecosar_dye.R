#' ECOSAR cationic dye predictions
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param ethoxylate Number of ethoxylate groups (default: 0)
#' @param molecularWeight Molecular weight in g/mol (default: 0)
#' @param waterSolubility Water solubility in mg/L (default: 0)
#' @param cas CAS registry number
#' @param chemicalName Chemical name
#' @return Returns a list with result object
#' @apiStage public
#' @export
#'
#' @examples
#' \dontrun{
#' epi_ecosar_dye(ethoxylate = "0")
#' }
epi_ecosar_dye <- function(ethoxylate = 0, molecularWeight = 0, waterSolubility = 0, cas = NULL, chemicalName = NULL) {
  result <- generic_request(
    endpoint = "ecosar/dye",
    method = "GET",
    batch_limit = 0,
    server = "epi_burl",
    auth = FALSE,
    tidy = FALSE,
    `ethoxylate` = ethoxylate,
    `molecularWeight` = molecularWeight,
    `waterSolubility` = waterSolubility,
    `cas` = cas,
    `chemicalName` = chemicalName
  )

  result <- run_hook(
    "epi_ecosar_dye",
    "post_response",
    list(
      result = result,
      params = list(
        `ethoxylate` = ethoxylate,
        `molecularWeight` = molecularWeight,
        `waterSolubility` = waterSolubility,
        `cas` = cas,
        `chemicalName` = chemicalName
      )
    )
  )
  # Additional post-processing can be added here

  return(result)
}
