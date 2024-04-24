#' Search for compounds by mass range
#'
#' Search for any MS-ready compounds that are between the queried mass range. Also removes multicomponent compounds.
#'
#' @param start Starting mass range
#' @param end Ending mass range
#' @param ccte_api_key Checks for API key in Sys env
#' @param debug Flag to show API calls
#' @return Returns a tibble with results

ct_search_mass <- function(start, end, ccte_api_key = NULL, debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')
  surl <- "chemical/msready/search/by-mass/"
  start_mass <- start
  end_mass <- end
  urls <- paste0(burl, surl, start_mass, '/', end_mass)

  df <- map_dfr(urls, ~{

    if (debug == TRUE) {
      cat(.x, "\n")
    }


    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
  })

  df <- ct_details(df$value) %>%
    filter(multicomponent != 1) %>%
    filter(monoisotopicMass >= start_mass & monoisotopicMass <= end_mass)

  return(df)
}


#' Search for compounds by formula
#'
#' Search for any MS-ready compounds by a generic chemical formula. Will not return any compound that is classified as multicomponent.
#'
#' @param query A string of a generic formula to search for
#' @param ccte_api_key Checks for API key in Sys env
#' @param debug Flag to show API calls
#' @return Returns a tibble with results


ct_search_formula <- function(query, ccte_api_key = NULL, debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  burl <- Sys.getenv('burl')
  surl <- "chemical/msready/search/by-formula/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    if (debug == TRUE) {
      cat(.x, "\n")
    }

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
  })

  df <- ct_details(df$value) %>% filter(multicomponent != 1)

  return(df)
}

#' Searches for compound  by string
#'
#' @param query A single query (in quotes) or a list to be queried. Currently accepts DTXSIDs, CASRNs, URL encoded chemical names, and matches of InChIKey
#' @param param A list of options to search by, default option is to use all options which will result in a long search query.
#' @param ccte_api_key Checks for API key in Sys env
#' @param debug Flag to show API calls

#'
#' @return Returns a tibble with results
#' @export
ct_name <- function(query,
                    param = c('start-with',
                              'equal',
                              'contain'),

                    ccte_api_key = NULL,
                    debug = F){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }
  burl <- Sys.getenv('burl')

  if(identical(c('start-with',
                 'equal',
                 'contain'),param)){
    cli_alert_warning('Large request detected!')
    cli_alert_warning('Request may time out!')
    cli_alert_warning('Recommend to change search parameters or break up requests!\n')
  }else{cat('\nParameter(s) declared:',param)}

  cat("\nRequesting valid names by provided search parameters....\n\n")

  surl <- "chemical/search/"

  urls <- do.call(paste0, expand.grid(burl,surl,param,'/',query))

  df <- map(urls, possibly(~{

    if (debug == TRUE) {
      cat(.x, "\n")
    }

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

  }, otherwise = NULL)) %>%
    compact %>%
    map_dfr(as.data.frame)

  df <- if('rank' %in% colnames(df)){arrange(df,rank)} else{df}
  df <-df %>% as_tibble()
  return(df)
}


