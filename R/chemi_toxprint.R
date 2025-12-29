#' ToxPrint Chemotyper
#'
#' @param query A list of DTXSIDs
#' @param odds_ratio numeric
#' @param p_val numeric
#' @param true_pos numeric
#'
#' @return A dataframe
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_toxprint(query = "DTXSID7020182")
#' }
chemi_toxprint <- function(query, odds_ratio = 3L, p_val = 0.05, true_pos = 3) {
  generic_chemi_request(
    query = query,
    endpoint = "toxprints/calculate",
    options = list(
      OR = odds_ratio,
      PV1 = p_val,
      TP = true_pos
    )
  )
}
