#' Grabs all public lists
#'
#' This function has no parameters to search by.
#'
#' @param return_dtxsid Boolean; Return all DTXSIDs contained within each list
#' @param coerce Boolean; Coerce each list of DTXSIDs into a vector rather than the native string.
#'
#' @return Returns a tibble of results
#' @export

ct_lists_all <- function(
  return_dtxsid = FALSE,
  coerce = FALSE
) {

  cli::cli_alert_info('Grabbing all public lists...')

  if (!return_dtxsid) {
    urls <- "https://api-ccte.epa.gov/chemical/list/?projection=chemicallistall"
  } else {
    urls <- "https://api-ccte.epa.gov/chemical/list/?projection=chemicallistwithdtxsids"
  }

  df <-
    response <- GET(url = urls, add_headers("x-api-key" = ct_api_key(), progress()))

  if (response$status != 200) {
    cli::cli_abort('Request failed!')
    cli::cli_alert_danger('Reason: {response$status}')
  } else {
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

    cli::cli_alert_success('{nrow(df)} lists found!')
  }

  if (return_dtxsid & coerce) {
    cli::cli_alert_warning('Coerceing DTXSID strings per list to list-column!')

    df <- df %>%
      split(.$listName) %>%
      map(., as.list) %>%
      map(
        .,
        ~ {
          .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ',') %>%
            pluck(1)
          .x
        }
      )
  } else {
    if (!return_dtxsid & coerce) {
      cli::cli_alert_warning('You need to request DTXSIDs...')
      cli::cli_end()

      df
    } else {
      (df)
    }
  }
}
