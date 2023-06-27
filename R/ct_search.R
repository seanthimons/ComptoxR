#' Search for compounds by mass range
#'
#' Search for any MS-ready compounds that are between the queried mass range. Also removes multicomponent compounds.
#'
#' @param start Starting mass range
#' @param end Ending mass range
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#' @return Returns a tibble with results
#' @export


ct_search_mass <- function(start, end, server = 1, ccte_api_key = NULL){

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

  surl <- "chemical/msready/search/by-mass/"
  start_mass <- start
  end_mass <- end
  urls <- paste0(burl, surl, start_mass, '/', end_mass)

  df <- map_dfr(urls, ~{

    #debug ####
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
  })

  df <- ct_details(df$value) %>%
    filter(multicomponent != 1) %>%
    filter(monoisotopicMass >= start_mass & monoisotopicMass <= end_mass)

  cat(green('\nSearch complete!\n'))

  return(df)
}


#' Search for compounds by formula
#'
#' Search for any MS-ready compounds by a generic chemical formula. Will not return any compound that is classified as multicomponent.
#'
#' @param query A string of a generic formula to search for
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#' @return Returns a tibble with results
#' @export

ct_search_formula <- function(query, server = 1, ccte_api_key = NULL){

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

  surl <- "chemical/msready/search/by-formula/"

  urls <- paste0(burl, surl, query)

  df <- map_dfr(urls, ~{

    #debug ####
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
  })

  df <- ct_details(df$value) %>% filter(multicomponent != 1)

  cat(green('\nSearch complete!\n'))

  return(df)
}

