#' Compound Production Volumes
#'
#' @description
#' Function to scrape the Comptox Chemistry Dashboard. Not guaranteed to work or remain in the package.
#' The Production Volume data is sourced from the Chemical Data Reporting (2020) (CDR) data submitted to US-EPA. The Chemical Data Reporting (CDR) Rule, issued under the Toxic Substances Control Act (TSCA), requires manufacturers (including importers) to give EPA information on the chemicals they produce domestically or import into the United States. EPA uses the data to help assess the potential human health and environmental effects of these chemicals and makes the non-confidential business information it receives available to the public.
#' Data is reported in pounds.
#' When the data is cleaned, the `amount` will return an average volume for ranged values, and the upper limit for single volumes.
#'
#' @param query A list of DTXSIDs to search by
#' @param clean Boolean to clean data or to return native data
#'
#' @return A tibble with associated data, where available
#' @export

ct_production_vol <- function(query, clean = TRUE) {
  urls <- paste0(
    'https://comptox.epa.gov/dashboard-api/ccdapp2/production-volume/search/by-dtxsid?id=',
    query
  )

  df <- map2_dfr(
    urls,
    query,
    ~ {
      response <- VERB("GET", url = .x, progress())
      cli_alert('\n{.y}\n')
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>%
        keep(names(.) %in% c('dtxsid', 'data'))
    }
  ) %>%
    compact() %>%
    unpack(cols = 'data') %>%
    select(dtxsid, name, amount)

  if (clean == TRUE) {
    ranged_vol <- df %>%
      filter(str_detect(amount, '-')) %>%
      separate_wider_delim(amount, delim = '-', names = c('low', 'high')) %>%
      mutate(
        high = str_remove_all(high, '<| |,') %>% as.numeric,
        low = str_remove_all(low, '<| |,') %>% as.numeric,
        amount = rowMeans(across(low:high))
      )

    singled_vol <- df %>%
      filter(!str_detect(amount, '-')) %>%
      mutate(amount = str_remove_all(amount, '<| |,') %>% as.numeric)

    df <- bind_rows(ranged_vol, singled_vol)
  } else {
    df
  }

  return(df)
}
