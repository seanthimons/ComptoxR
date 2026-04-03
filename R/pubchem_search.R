#' Search PubChem for compound CIDs
#'
#' Search the PubChem PUG REST API by compound name, SMILES, InChI, InChIKey,
#' or molecular formula and return matching PubChem Compound IDs (CIDs).
#'
#' SMILES and InChI inputs are automatically sent via POST to avoid URL encoding
#' issues with special characters (`/`, `#`, `+`).
#'
#' @param query Character string. The search term (compound name, SMILES, InChI,
#'   InChIKey, or molecular formula).
#' @param type Character string. The type of identifier in `query`. One of
#'   `"name"` (default), `"smiles"`, `"inchi"`, `"inchikey"`, or `"formula"`.
#'
#' @return A tibble with a single column `cid` containing integer PubChem CIDs.
#'   Returns a zero-row tibble if no matches are found.
#'
#' @details
#' PubChem may return multiple CIDs for a single name query (e.g., different
#' stereoisomers). If more than 10 CIDs are returned, a message is displayed
#' with the count.
#'
#' For structure-based searches (SMILES, InChI), the query is sent as a POST
#' form body rather than in the URL path. This is required because
#' `httr2::req_url_path_append()` does not percent-encode path segments,
#' and characters like `/` and `#` in SMILES notation would corrupt the URL.
#'
#' @seealso [pubchem_properties()] to fetch properties for CIDs,
#'   [pubchem_synonyms()] to fetch synonym lists,
#'   [ct_chemical_detail_search()] for CompTox Dashboard chemical search.
#'
#' @examples
#' \dontrun{
#' # Search by name
#' pubchem_search("aspirin")
#'
#' # Search by SMILES (uses POST automatically)
#' pubchem_search("CC(=O)OC1=CC=CC=C1C(=O)O", type = "smiles")
#'
#' # Search by InChIKey
#' pubchem_search("BSYNRYMUTXBXSQ-UHFFFAOYSA-N", type = "inchikey")
#'
#' # Search by molecular formula
#' pubchem_search("C9H8O4", type = "formula")
#' }
#'
#' @export
pubchem_search <- function(query, type = c("name", "smiles", "inchi", "inchikey", "formula")) {
  type <- match.arg(type)

  if (!is.character(query) || length(query) != 1 || is.na(query) || !nzchar(query)) {
    cli::cli_abort("{.arg query} must be a single non-empty character string.")
  }

  # Structure inputs MUST use POST to avoid URL encoding issues
  if (type %in% c("smiles", "inchi")) {
    result <- generic_pubchem_request(
      namespace = type,
      operation = "cids",
      method = "POST",
      body = stats::setNames(list(query), type),
      pluck_path = c("IdentifierList", "CID"),
      tidy = FALSE
    )
  } else {
    result <- generic_pubchem_request(
      query = query,
      namespace = type,
      operation = "cids",
      pluck_path = c("IdentifierList", "CID"),
      tidy = FALSE
    )
  }

  # Handle empty results
  if (length(result) == 0) {
    cli::cli_warn("No PubChem CIDs found for {.val {query}} (type: {type})")
    return(tibble::tibble(cid = integer(0)))
  }

  cids <- as.integer(unlist(result))

  if (length(cids) > 10) {
    cli::cli_inform("{length(cids)} CIDs found for {.val {query}}")
  }

  tibble::tibble(cid = cids)
}
