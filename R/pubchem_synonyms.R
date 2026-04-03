#' Fetch synonyms from PubChem
#'
#' Retrieve the synonym list for one or more PubChem Compound IDs (CIDs) via
#' the PUG REST API. Synonyms include IUPAC names, common names, CAS numbers,
#' DTXSIDs, trade names, and other identifiers.
#'
#' @param cid Integer or character vector of PubChem CIDs.
#' @param tidy Logical. If `TRUE` (default), returns a long-format tibble with
#'   `cid` and `synonym` columns. If `FALSE`, returns a list of lists with
#'   `CID` and `Synonym` elements.
#'
#' @return When `tidy = TRUE`: a tibble with columns `cid` (integer) and
#'   `synonym` (character). When `tidy = FALSE`: a list where each element
#'   contains `CID` and `Synonym` fields. Returns an empty tibble/list for
#'   invalid CIDs.
#'
#' @details
#' For multiple CIDs, requests are batched at 100 CIDs per POST request.
#' This is significantly faster than per-CID GET requests (e.g., 500 CIDs
#' requires 5 POST requests instead of 500 GET requests).
#'
#' @seealso [pubchem_search()] to find CIDs,
#'   [util_pubchem_resolve_dtxsid()] to extract DTXSIDs from synonym lists,
#'   [ct_chemical_synonym_search()] for CompTox Dashboard synonyms.
#'
#' @examples
#' \dontrun{
#' # Single CID
#' pubchem_synonyms(2244)
#'
#' # Multiple CIDs (uses bulk POST)
#' pubchem_synonyms(c(2244, 6623))
#'
#' # Raw list format
#' pubchem_synonyms(2244, tidy = FALSE)
#' }
#'
#' @export
pubchem_synonyms <- function(cid, tidy = TRUE) {
  cid <- as.integer(cid)
  cid <- cid[!is.na(cid)]
  if (length(cid) == 0) {
    cli::cli_abort("{.arg cid} must contain at least one valid integer CID.")
  }

  if (length(cid) > 1) {
    # Bulk POST — collapses N requests into ceil(N/100) requests
    cid_batches <- split(cid, ceiling(seq_along(cid) / 100))
    results <- purrr::map(cid_batches, function(batch) {
      generic_pubchem_request(
        namespace = "cid",
        operation = "synonyms",
        method = "POST",
        body = list(cid = paste(batch, collapse = ",")),
        pluck_path = c("InformationList", "Information"),
        tidy = FALSE
      )
    })
    all_info <- purrr::list_flatten(results)
  } else {
    all_info <- generic_pubchem_request(
      query = cid,
      namespace = "cid",
      operation = "synonyms",
      pluck_path = c("InformationList", "Information"),
      tidy = FALSE
    )
  }

  if (length(all_info) == 0) {
    if (tidy) return(tibble::tibble(cid = integer(0), synonym = character(0)))
    return(list())
  }

  if (!tidy) return(all_info)

  # Convert to long-format tibble
  purrr::map_dfr(all_info, function(info) {
    synonyms <- info$Synonym %||% character(0)
    if (length(synonyms) == 0) return(tibble::tibble(cid = integer(0), synonym = character(0)))
    tibble::tibble(
      cid = as.integer(info$CID),
      synonym = as.character(synonyms)
    )
  })
}
