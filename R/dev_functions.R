#' Compound Production Volumes
#'
#' Function to scrape the Comptox Chemistry Dashboard. Not guaranteed to work or remain in the package.
#'
#' @param query A list of DTXSIDs to search by
#'
#' @return A tibble with associated data, where available
#' @export

ct_production_vol <- function(query){

  urls <- paste0('https://comptox.epa.gov/dashboard-api/ccdapp2/production-volume/search/by-dtxsid?id=', query)

  df <- map2_dfr(urls,query, ~{

    response <- VERB("GET", url = .x, progress())
    cli_alert('\n{.y}\n')
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>%
      keep(names(.) == 'dtxsid' | names(.) == 'data')
  })
  df <- df %>% unpack(cols = 'data')
  return(df)
}

#' Compound Functional Usage
#'
#' Function to scrape the Comptox Chemistry Dashboard. Not guaranteed to work or remain in the package.
#'
#' @param query A list of DTXSIDs to search by
#'
#' @return A tibble with associated data, where available
#' @export


ct_functional_use <- function(query){
  urls <- paste0('https://comptox.epa.gov/dashboard-api/ccdapp2/exposure-chemical-func-use/search/by-dtxsid?id=', query)

  df <- map2(urls,query, ~{

    response <- VERB("GET", url = .x, progress())
    cli_alert('\n{.y}\n')
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  })

  df <- df %>%
    map(., ~keep(., names(.x) %in% c('dtxsid', 'reportedFunctionalUse', 'predictedFunctionalUse')))

  data <- list(
    reported = NULL,
    predicted = NULL
    )

  data$reported <- df %>%
    map(., ~pluck(., 2, .default = NULL))

  names(data$reported) <- df %>%
    map(., ~pluck(., 'dtxsid'))

  data$reported <- data$reported %>%
    map_dfr(., as_tibble, .id = 'dtxsid') %>%
    distinct(., dtxsid, harmonizedFunctionalUse)

  data$predicted <- df %>%
    map(., ~pluck(., 3, .default = NULL))

  names(data$predicted) <- df %>%
    map(., ~pluck(., 'dtxsid'))

  data$predicted <- data$predicted %>%
    map_dfr(., as_tibble, .id = 'dtxsid')

  return(data)
}




