#' Generates an Excel workbook containing information on all Analytical QC records that contain a given list of DTXSIDs.
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' @param base_url URL for the AMOS frontend.  Used to construct the internal links in the output file.
#' @param dtxsids List of DTXSIDs to search for.
#' @param include_classyfire Flag for whether to include the top four levels of a ClassyFire classification for each of the searched substances, if it exists.
#' @param include_functional_uses Flag for whether to include functional use classifications based on the ChemFuncT ontology.  Only exists for around 21,000 substances in the database.
#' @param include_source_counts Flag for whether to include counts of a substance's appearances in patents, PubMed articles, and other external sources.
#' @param methodologies Filters the returned results by analytical methodologies.  This argument should be a dictionary with four keys with boolean values -- "all", "GC/MS", "LC/MS", and "NMR".  There are some methodologies with small numbers of records (e.g., IR spectra) which will only appear in the data if "all" is set to true.
#' @return Returns a tibble with results
#' @export
#'
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_batch(base_url = "DTXSID7020182")
#' }
chemi_amos_analytical_qc_batch <- function(base_url = NULL, dtxsids = NULL, include_classyfire = NULL, include_functional_uses = NULL, include_source_counts = NULL, methodologies = NULL) {
  # Build options list for additional parameters
  options <- list()
  if (!is.null(dtxsids)) options$dtxsids <- dtxsids
  if (!is.null(include_classyfire)) options$include_classyfire <- include_classyfire
  if (!is.null(include_functional_uses)) options$include_functional_uses <- include_functional_uses
  if (!is.null(include_source_counts)) options$include_source_counts <- include_source_counts
  if (!is.null(methodologies)) options$methodologies <- methodologies
  result <- generic_chemi_request(
    query = base_url,
    endpoint = "amos/analytical_qc_batch_search",
    options = options,
    tidy = FALSE
  )

  # Additional post-processing can be added here

  return(result)
}


