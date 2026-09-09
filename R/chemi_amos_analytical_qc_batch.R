#' Generates an Excel workbook containing information on all Analytical QC records that contain a given list of DTXSIDs
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param base_url URL for the AMOS frontend.  Used to construct the internal links in the output file.
#' @param ids List of DTXSIDs or other identifiers to search for.
#' @param include_classyfire Flag for whether to include the top four levels of a ClassyFire classification for each of the searched substances, if it exists.
#' @param include_functional_uses Flag for whether to include functional use classifications based on the ChemFuncT ontology.  Only exists for around 21,000 substances in the database.
#' @param include_source_counts Flag for whether to include counts of a substance's appearances in patents, PubMed articles, and other external sources.
#' @param methodologies Filters the returned results by analytical methodologies.  This argument should be a dictionary with four keys with boolean values -- "all", "GC/MS", "LC/MS", and "NMR".  There are some methodologies with small numbers of records (e.g., IR spectra) which will only appear in the data if "all" is set to true.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_analytical_qc_batch(base_url = "DTXSID1024122")
#' }
# Generated with apipak; do not edit by hand.
chemi_amos_analytical_qc_batch <- function(
  base_url = NULL,
  ids = NULL,
  include_classyfire = NULL,
  include_functional_uses = NULL,
  include_source_counts = NULL,
  methodologies = NULL
) {
  params <- list(
    "base_url" = base_url,
    "ids" = ids,
    "include_classyfire" = include_classyfire,
    "include_functional_uses" = include_functional_uses,
    "include_source_counts" = include_source_counts,
    "methodologies" = methodologies
  )
  result <- generic_chemi_request(
    "query" = params[["base_url"]],
    "endpoint" = "amos/analytical_qc_batch_search",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "ids" = params[["ids"]],
          "include_classyfire" = params[["include_classyfire"]],
          "include_functional_uses" = params[["include_functional_uses"]],
          "include_source_counts" = params[["include_source_counts"]],
          "methodologies" = params[["methodologies"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
