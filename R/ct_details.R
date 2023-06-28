#' Retrieve compound details by DTXSID
#'
#'
#' @param dtxsid A single DTXSID (in quotes) or a list to be queried
#' @param projection Subsets the returned dataframe based on desired provided results. Defaults to `chemicaldetailstandard`.
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#' @return Returns a tibble with results
#' @export

ct_details <- function(query, projection = c('chemicaldetailall','chemicaldetailstandard','chemicalidentifier', 'chemicalstructure','ntatoolkit'), server = 1, ccte_api_key = NULL){

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

  cat("Searching for compound details....\n")
  surl <- "chemical/detail/search/by-dtxsid/"

  if(identical(projection, c('chemicaldetailall','chemicaldetailstandard','chemicalidentifier', 'chemicalstructure','ntatoolkit'))){proj <- 'chemicaldetailstandard'}else{proj <- projection}

  urls <- paste0(burl, surl, query,'?projection=',proj)

  df <- map_dfr(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  }) %>% as_tibble()


  cat(green('\nSearch complete!\n'))
  return(df)
}


ct_batch_details <- function(query){
  query <- split(query, ceiling(seq_along(query)/200))

  return(df)
}
