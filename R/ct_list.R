#' Returns all compounds on a given list
#'
#' Can be used to return all compounds from a single list (e.g.:'PRODWATER') or a list of aggregated lists.
#'
#' @param list_name Search parameter
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_list <- function(list_name, server = 1, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }
  #Takes single list name for searching


  {
    #Switch for server URLS

    if(server == 1){
      burl <- 'https://api-ccte.epa.gov/'
      cat(green('Public API selected!\n'))
    }else{
      burl <- 'https://api-ccte-stg.epa.gov/'
      cat(red('Staging API selected!\n'))
    }
  }


  cat('\nSearching for compounds on', list_name,'list ...\n')

  surl <- "chemical/list/chemicals/search/by-listname/"

  urls <- paste0(burl, surl, list_name)

  df <- map_dfr(urls, ~{

    #cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n',nrow(df),'compounds found!\n'))
  return(df)
}


#' Returns all public lists that contain a queried compound
#'
#' @param query A DTXSID to search by.
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export

ct_compound_in_list <- function(query, server = 1, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  {
    #Switch for server URLS

    if(server == 1){
      burl <- 'https://api-ccte.epa.gov/'
      cat(green('Public API selected!\n'))
    }else{
      burl <- 'https://api-ccte-stg.epa.gov/'
      cat(red('Staging API selected!\n'))
    }
  }

  cat('\nSearching for lists that contain', query,'...\n')

  surl <- "chemical/list/search/by-dtxsid/"
  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug ####
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n'))
  return(df)
}

#' Grabs all public lists
#'
#' This function has no parameters to search by.
#'
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble of results
#' @export

ct_lists_all <- function(server = 1, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  {
    #Switch for server URLS
    if(server == 1){
      burl <- 'https://api-ccte.epa.gov/'
      cat(green('Public API selected!\n'))
    }else{
      burl <- 'https://api-ccte-stg.epa.gov/'
      cat(red('Staging API selected!\n'))
    }
  }

  cat('\nGrabbing all public lists...\n')

  urls <- 'https://api-ccte.epa.gov/chemical/list/?projection=chemicallistall'

  df <- map_dfr(urls, ~{

    #debug ####
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()


  #TODO
  #
  #Remove duplicates from lists

  cat(green('\nSearch complete!\n'))
  return(df)

}
