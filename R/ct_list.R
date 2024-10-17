#' Returns all compounds on a given list
#'
#' Can be used to return all compounds from a single list (e.g.:'PRODWATER') or a list of aggregated lists.
#'
#' @param list_name Search parameter
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_list <- function(list_name,  ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  df <- map(list_name, possibly(~{

    cli::cli_text()
    cli::cli_alert_info('\nSearching for compounds on {(.x)} list...\n')

    burl <- Sys.getenv('burl')
    surl <- "chemical/list/search/by-name/"

    urls <- paste0(burl, surl, stringr::str_to_upper(.x),'?projection=chemicallistwithdtxsids')

    response <- GET(url = urls, add_headers("x-api-key" = ct_api_key()), progress())

    if(response$status != 200){

      cli::cli_alert_warning('Request failed on {(.x)}')
      cli::cli_end()
      return(NULL)

    }else{

      .x <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

      cli_alert_success('\n{(.x$chemicalCount)} compounds found!\n')
      cli::cli_end()

      .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ',') %>% pluck(1)

      return(.x)
    }
  }, NULL)) %>% set_names(., list_name) %>% compact()
}


#' Returns all public lists that contain a queried compound
#'
#' @param query A DTXSID to search by.
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_compound_in_list <- function(query, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  df <- map(query, possibly(~{

    cli::cli_alert_info('Searching for lists that contain {(.x)}')
    cli::cli_end()

    burl <- Sys.getenv('burl')
    surl <- "chemical/list/search/by-dtxsid/"
    urls <- paste0(burl, surl, .x, '?projection=chemicallistname')

    response <- GET(url = urls, add_headers("x-api-key" = ct_api_key()), progress())

    if(response$status != 200){

      cli::cli_alert_warning('Request failed on {(.x)}')
      cli::cli_end()
      return(NULL)

    }else{

      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

      df <- as.list(df) %>% pluck(1)

      cli::cli_alert_success('{length(df)} lists found!')
      cli::cli_end()
      return(df)

    }
  }, NULL)) %>% set_names(., query) %>% compact()


}

#' Grabs all public lists
#'
#' This function has no parameters to search by.
#'
#' @param ccte_api_key Checks for API key in Sys env
#' @param return_dtxsid Boolean; Return all DTXSIDs contained within each list
#' @param coerce Boolean; Coerce each list of DTXSIDs into a vector rather than the native string.
#'
#' @return Returns a tibble of results
#' @export

ct_lists_all <- function(return_dtxsid = FALSE,
                         coerce = FALSE,
                         ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  cli::cli_alert_info('Grabbing all public lists...')

  if(return_dtxsid == FALSE){
    urls <- "https://api-ccte.epa.gov/chemical/list/?projection=chemicallistall"
  }else{
    urls <- "https://api-ccte.epa.gov/chemical/list/?projection=chemicallistwithdtxsids"
  }

  df <-
    response <- GET(url = urls, add_headers("x-api-key" = token), progress())

  if(response$status != 200){

    cli::cli_abort('Request failed!')
    cli::cli_alert_danger('Reason: {response$status}')

    }else{

    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

    cli::cli_alert_success('{nrow(df)} lists found!')
    }

  if(return_dtxsid == TRUE & coerce == TRUE){

  cli::cli_alert_warning('Coerceing DTXSID strings per list to list-column!')

  df <- df %>%
    split(.$listName) %>%
    map(., as.list) %>%
    map(., ~{
      .x$dtxsids <- stringr::str_split(.x$dtxsids, pattern = ',') %>% pluck(1)
      .x
    })

  }else{
    if(return_dtxsid == FALSE & coerce == TRUE){
    cli::cli_alert_warning('You need to request DTXSIDs...')
    cli::cli_end()

    df

    }else(
     df
    )
  }
}
