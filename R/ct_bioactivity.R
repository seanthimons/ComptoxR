#' Bioactivity assay data
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Retrieves bioactivity data by DTXSID, AEID, SPID, or M4ID. Dispatches to
#' the appropriate generated endpoint function based on `search_type`.
#'
#' @param query Character vector of identifiers to query.
#' @param search_type One of `"dtxsid"` (default), `"aeid"`, `"spid"`, or
#'   `"m4id"`.
#' @param annotate Logical; if `TRUE`, performs a secondary request to join
#'   assay annotation details via [ct_bioactivity_assay()]. Default `FALSE`.
#'
#' @return A tibble of bioactivity results. If `annotate = TRUE`, includes
#'   assay annotation columns joined by `aeid`.
#' @export
#'
#' @examples
#' \dontrun{
#' ct_bioactivity(query = "DTXSID7020182")
#' ct_bioactivity(query = c("DTXSID7020182", "DTXSID2021028"))
#' ct_bioactivity(query = "3032", search_type = "aeid")
#' ct_bioactivity(query = "DTXSID7020182", annotate = TRUE)
#' }
ct_bioactivity <- function(
  query,
  search_type = c("dtxsid", "aeid", "spid", "m4id"),
  annotate = FALSE
) {
  search_type <- match.arg(search_type)

  df <- switch(
    search_type,
    "dtxsid" = ct_bioactivity_data_search_bulk(query = query),
    "aeid"   = ct_bioactivity_data_search_by_aeid_bulk(query = query),
    "spid"   = ct_bioactivity_data_search_by_spid_bulk(query = query),
    "m4id"   = ct_bioactivity_data_search_by_m4id_bulk(query = query)
  )

  if (annotate) {
    bioassay_all <- ct_bioactivity_assay()
    df <- dplyr::left_join(df, bioassay_all, by = "aeid")
  }

  return(df)
}
