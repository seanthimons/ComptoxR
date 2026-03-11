#' All public chemical lists
#'
#' @description
#' `r lifecycle::badge("stable")`
#'
#' Retrieves all public chemical lists from the CompTox Dashboard.
#'
#' @param return_dtxsid Logical; return all DTXSIDs contained within each list.
#'   Default `FALSE`.
#' @param coerce Logical; coerce each list of DTXSIDs into a vector rather than
#'   the native comma-separated string. Requires `return_dtxsid = TRUE`.
#'   Default `FALSE`.
#'
#' @return A tibble of chemical lists, or a named list of lists if
#'   `coerce = TRUE`.
#' @export
#'
#' @examples
#' \dontrun{
#' ct_lists_all()
#' ct_lists_all(return_dtxsid = TRUE, coerce = TRUE)
#' }
ct_lists_all <- function(
  return_dtxsid = FALSE,
  coerce = FALSE
) {
  projection <- if (!return_dtxsid) {
    "chemicallistall"
  } else {
    "chemicallistwithdtxsids"
  }

  df <- ct_chemical_list_all(projection = projection)

  cli::cli_alert_success("{nrow(df)} lists found!")

  if (return_dtxsid & coerce) {
    cli::cli_alert_warning("Coercing DTXSID strings per list to list-column!")

    df <- df %>%
      split(.$listName) %>%
      purrr::map(., as.list) %>%
      purrr::map(., ~ {
        .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ",") %>%
          purrr::pluck(1)
        .x
      })
  } else if (!return_dtxsid & coerce) {
    cli::cli_alert_warning("You need to request DTXSIDs to coerce!")
  }

  return(df)
}
