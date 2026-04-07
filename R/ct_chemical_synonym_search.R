#' Get synonyms for a batch of DTXSIDs
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param query Character vector of strings to send in request body
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_synonym_search_bulk(query = c("DTXSID7043792", "DTXSID2057574", "DTXSID90486733"))
#' }
ct_chemical_synonym_search_bulk <- function(query) {
  result <- generic_request(
    query = query,
    endpoint = "chemical/synonym/search/by-dtxsid/",
    method = "POST",
    batch_limit = as.numeric(Sys.getenv("batch_limit", "100"))
  )

  return(result)
}


#' Get synonyms by DTXSID
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param dtxsid DSSTox Substance Identifier. Type: string
#' @param projection Projections available include: ccd-synonyms and chemical-synonym-all. By default, chemical-synonym-all will be returned.
#' @return Returns a scalar value
#' @export
#'
#' @examples
#' \dontrun{
#' ct_chemical_synonym_search(dtxsid = "DTXSID7020182")
#' }
ct_chemical_synonym_search <- function(dtxsid, projection = NULL) {
  result <- generic_request(
    query = dtxsid,
    endpoint = "chemical/synonym/search/by-dtxsid/",
    method = "GET",
    batch_limit = 1,
    `projection` = projection
  )

  # Additional post-processing can be added here

  return(result)
}


