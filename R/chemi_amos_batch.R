#' Generates an Excel workbook which lists all records in the database that contain a given set of DTXSIDs.
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param additional_record_info Optional parameter
#' @param always_download_file If false, a search that does not find any matching records in the database will just return a message instead of a file.
#' @param base_url URL for the AMOS frontend.  Used to construct the internal links in the output file.
#' @param ids List of DTXSIDs or other identifiers to search for.
#' @param include_classyfire Flag for whether to include the top four levels of a ClassyFire classification for each of the searched substances, if it exists.
#' @param include_external_links Flag for whether to include database records that are purely external links (e.g., spectra that we can link to but cannot store directly in the database).
#' @param include_functional_uses Flag for whether to include functional use classifications based on the ChemFuncT ontology.  Only exists for around 21,000 substances in the database.
#' @param include_source_counts Flag for whether to include counts of a substance's appearances in patents, PubMed articles, and other external sources.
#' @param methodologies Filters the returned results by analytical methodologies.  This argument should be a dictionary with four keys with boolean values -- "all", "GC/MS", "LC/MS", and "NMR".  There are some methodologies with small numbers of records (e.g., IR spectra) which will only appear in the data if "all" is set to true.
#' @param record_types Filters returned results by record type.  This argument should be a dictionary with three keys with boolean values -- "Fact Sheet", "Method", and "Spectrum".  Note that the "Spectrum" flag will return spectra of all types -- mass, NMR, etc.
#' @return Returns a tibble with results
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_amos_batch(additional_record_info = "DTXSID1024122")
#' }
# Generated with specmill; do not edit by hand.
chemi_amos_batch <- function(
  additional_record_info = NULL,
  always_download_file = NULL,
  base_url = NULL,
  ids = NULL,
  include_classyfire = NULL,
  include_external_links = NULL,
  include_functional_uses = NULL,
  include_source_counts = NULL,
  methodologies = NULL,
  record_types = NULL
) {
  params <- list(
    "additional_record_info" = additional_record_info,
    "always_download_file" = always_download_file,
    "base_url" = base_url,
    "ids" = ids,
    "include_classyfire" = include_classyfire,
    "include_external_links" = include_external_links,
    "include_functional_uses" = include_functional_uses,
    "include_source_counts" = include_source_counts,
    "methodologies" = methodologies,
    "record_types" = record_types
  )
  result <- generic_chemi_request(
    "query" = params[["additional_record_info"]],
    "endpoint" = "amos/batch_search",
    "options" = local({
      .body <- Filter(
        Negate(is.null),
        list(
          "always_download_file" = params[["always_download_file"]],
          "base_url" = params[["base_url"]],
          "ids" = params[["ids"]],
          "include_classyfire" = params[["include_classyfire"]],
          "include_external_links" = params[["include_external_links"]],
          "include_functional_uses" = params[["include_functional_uses"]],
          "include_source_counts" = params[["include_source_counts"]],
          "methodologies" = params[["methodologies"]],
          "record_types" = params[["record_types"]]
        )
      )
      if (length(.body)) .body else list()
    }),
    "tidy" = FALSE
  )
  result
}
