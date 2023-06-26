#' Retrieves cancer-related hazard and risk values for a give DTXSID
#'
#'Values returned include source and URL, level of known or predicted risk, and exposure route (if known).
#'Cancer slope values and THQ values can also be found from running the `ct_hazard()` or `ct_ghs` functions.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_cancer <- function(x, server = 1, ccte_api_key = NULL){

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

  cat('\nSearching for cancer data...\n')
  surl <- "hazard/cancer-summary/search/by-dtxsid/"

  urls <- paste0(burl, surl, x)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n'))
  return(df)
}

#' Retrieves data on known or predicted genotoxic effects by DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_genotox <- function(query, server = 1, ccte_api_key = NULL){

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

  cat('\nSearching for genetox data...\n')
  surl <- "hazard/genetox/details/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()

  cat(green('\nSearch complete!\n'))
  return(df)
}

#' Retrieves known hazard and risk characterizations by DTXSID for skin and eye endpoints.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_skin_eye <- function(query, server = 1, ccte_api_key = NULL){

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

  cat('\nSearching for skin and eye resources...\n')
  surl <- "hazard/skin-eye/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug ####
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  })

  cat(green('\nSearch complete!\n'))
  return(df)
}
