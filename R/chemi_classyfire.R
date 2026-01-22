#' Get Classyfire classificaton for DTXSID
#'
#' This function retrieves Classyfire classificatons for a given DTXSID using the EPA's cheminformatics API.
#'
#' @param query A character vector of DTXSIDs to query.
#'
#' @return A list of Classyfire classificatons corresponding to the input DTXSIDs.
#'  Returns NA if the request fails for a given DTXSID.
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_classyfire(query = "DTXSID7020182")
#' }
chemi_classyfire <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "amos/get_classification_for_dtxsid/",
    method = "GET",
    batch_limit = 1,
    server = 'chemi_burl',
    auth = FALSE
  )

  if (nrow(result) > 0) {
    result <- result %>%
      dplyr::select(
        dtxsid = dplyr::any_of(c("query", "value", "sid")),
        kingdom = dplyr::any_of("kingdom"),
        superclass = dplyr::any_of("superklass"),
        class = dplyr::any_of("klass"),
        subclass = dplyr::any_of("subklass")
      )
  }

  return(result)
}
