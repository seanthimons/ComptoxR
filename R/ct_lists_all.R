#' Grabs all public lists
#'
#' This function has no parameters to search by.
#'
#' @param return_dtxsid Boolean; Return all DTXSIDs contained within each list
#' @param coerce Boolean; Coerce each list of DTXSIDs into a vector rather than the native string.
#'
#' @return Returns a tibble of results (or nested list if coerce=TRUE)
#' @export

ct_lists_all <- function(
  return_dtxsid = FALSE,
  coerce = FALSE
) {

  #cli::cli_alert_info('Grabbing all public lists...')

  # Determine projection
  projection <- if (!return_dtxsid) {
    "chemicallistall"
  } else {
    "chemicallistwithdtxsids"
  }

  # Use generic_request with batch_limit=0 for static endpoint
  df <- generic_request(
    query = NULL,  # No query needed for static endpoint
    endpoint = "chemical/list/all",
    method = "GET",
    batch_limit = 0,  # Static endpoint flag
    tidy = TRUE,
    projection = projection
  )

  cli::cli_alert_success('{nrow(df)} lists found!')

  if (return_dtxsid & coerce) {
    cli::cli_alert_warning('Coercing DTXSID strings per list to list-column!')

    df <- df %>%
      split(.$listName) %>%
      purrr::map(., as.list) %>%
      purrr::map(
        .,
        ~ {
          .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ',') %>%
            purrr::pluck(1)
          .x
        }
      )
  } else {
    if (!return_dtxsid & coerce) {
      cli::cli_alert_warning('You need to request DTXSIDs...')
      cli::cli_end()
    }
  }

  return(df)
}
