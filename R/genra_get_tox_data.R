#' Get Toxicity Activity Data from ToxValDB
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Retrieves toxicity data from ToxValDB and parses LOAEL/NOAEL records to
#' determine binary activity for read-across predictions.
#'
#' @param dtxsids Character vector of DTXSIDs to retrieve data for.
#' @param study_filter Optional character string to filter by study type
#'   (e.g., "acute", "chronic", "developmental", "reproduction"). Uses
#'   case-insensitive regex matching. Default is NULL (no filtering).
#'
#' @return A tibble with columns:
#' \describe{
#'   \item{dtxsid}{DSSTox Substance Identifier.}
#'   \item{activity}{Integer activity: 1 = adverse effect observed (has LOAEL),
#'     0 = tested but no adverse effect (only NOAEL), NA = no usable data.
#'   }
#'   \item{n_records}{Number of ToxValDB records used for this chemical.}
#' }
#'
#' @details
#' Activity determination logic:
#' \itemize{
#'   \item **LOAEL-type records** (LOAEL, LOAEC, LOEL, LOEC, LD50, LC50, ED50,
#'     EC50, BMD, BMDL, FEL): Indicate an adverse effect was observed at some dose.
#'   \item **NOAEL-type records** (NOAEL, NOAEC, NOEL, NOEC): Indicate the chemical
#'     was tested and no adverse effect was observed up to the tested dose.
#' }
#'
#' The activity classification per chemical is:
#' \enumerate{
#'   \item If any LOAEL-type record exists: activity = 1 (active/toxic)
#'   \item If only NOAEL-type records exist: activity = 0 (inactive/not toxic
#'     at tested doses)
#'   \item If no usable records: activity = NA
#' }
#'
#' @seealso [ct_hazard_toxval_search_bulk()], [genra_predict()]
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Get activity data for multiple chemicals
#' genra_get_tox_data(c("DTXSID7020182", "DTXSID3020630", "DTXSID2021028"))
#'
#' # Filter to developmental studies only
#' genra_get_tox_data("DTXSID7020182", study_filter = "developmental")
#' }
genra_get_tox_data <- function(dtxsids, study_filter = NULL) {
  # Input validation
  if (length(dtxsids) == 0) {
    return(tibble::tibble(
      dtxsid = character(),
      activity = integer(),
      n_records = integer()
    ))
  }

  # Fetch ToxValDB data
  toxval_df <- ct_hazard_toxval_search_bulk(dtxsids)

  # Parse into activity labels
  result <- .parse_toxval_activity(toxval_df, study_filter = study_filter)

  # Ensure all input DTXSIDs are represented (with NA if no data)
  all_dtxsids <- tibble::tibble(dtxsid = unique(dtxsids))
  result <- dplyr::left_join(all_dtxsids, result, by = "dtxsid")

  # Fill missing n_records with 0
  result$n_records[is.na(result$n_records)] <- 0L

  return(result)
}


#' Parse ToxValDB Records into Activity Labels
#'
#' @description
#' Internal function to classify ToxValDB records into binary activity values.
#'
#' @param toxval_df Data frame returned from ct_hazard_toxval_search_bulk().
#' @param study_filter Optional regex pattern to filter by studyType.
#'
#' @return Tibble with dtxsid, activity, n_records.
#'
#' @keywords internal
#' @noRd
.parse_toxval_activity <- function(toxval_df, study_filter = NULL) {
  if (is.null(toxval_df) || nrow(toxval_df) == 0) {
    return(tibble::tibble(
      dtxsid = character(),
      activity = integer(),
      n_records = integer()
    ))
  }

  # Standardize column names if needed
  if (!"dtxsid" %in% names(toxval_df) && "dtxsidName" %in% names(toxval_df)) {
    toxval_df <- dplyr::rename(toxval_df, dtxsid = dtxsidName)
  }

  # Ensure required columns exist
  required_cols <- c("dtxsid", "toxvalType")
  missing <- setdiff(required_cols, names(toxval_df))
  if (length(missing) > 0) {
    cli::cli_warn(
      "ToxValDB response missing expected columns: {.val {missing}}.
       Returning empty result."
    )
    return(tibble::tibble(
      dtxsid = character(),
      activity = integer(),
      n_records = integer()
    ))
  }

  # Optional: filter by study type
  if (!is.null(study_filter) && "studyType" %in% names(toxval_df)) {
    toxval_df <- toxval_df |>
      dplyr::filter(grepl(study_filter, .data$studyType, ignore.case = TRUE))
  }

  if (nrow(toxval_df) == 0) {
    return(tibble::tibble(
      dtxsid = character(),
      activity = integer(),
      n_records = integer()
    ))
  }

  # Define effect type categories
  adverse_types <- c(
    "LOAEL", "LOAEC", "LOEL", "LOEC",
    "LD50", "LC50", "ED50", "EC50",
    "BMD", "BMDL", "FEL"
  )
  no_adverse_types <- c("NOAEL", "NOAEC", "NOEL", "NOEC")

  # Classify and aggregate
  result <- toxval_df |>
    dplyr::mutate(
      toxvalType_upper = toupper(.data$toxvalType),
      has_adverse = .data$toxvalType_upper %in% adverse_types,
      has_no_adverse = .data$toxvalType_upper %in% no_adverse_types
    ) |>
    dplyr::group_by(.data$dtxsid) |>
    dplyr::summarize(
      has_any_adverse = any(.data$has_adverse, na.rm = TRUE),
      has_any_no_adverse = any(.data$has_no_adverse, na.rm = TRUE),
      n_records = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      activity = dplyr::case_when(
        .data$has_any_adverse ~ 1L,
        .data$has_any_no_adverse ~ 0L,
        TRUE ~ NA_integer_
      )
    ) |>
    dplyr::select("dtxsid", "activity", "n_records")

  return(result)
}
