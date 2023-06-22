#' Searches for listed synonyms by DTXSID
#'
#' @param query A single string (in quotes) or a list of strings to be queried.
#' @param server Defaults to public API, private requires USEPA VPN
#' @param ccte_api_key Checks for API key in Sys env
#'
#' @return Returns a tibble with results
#' @export
ct_synonym <- function(query, server = 1, ccte_api_key = NULL){

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

  cat("Searching for compound synonym....\n")
  surl <- "chemical/synonym/search/by-dtxsid/"

  urls <- paste0(burl, surl, query)

  df <- map(urls, ~{

    #debug
    cat(.x,'\n')

    response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  })

  names(df) <- x

  {
    t1 <- df %>% map(1) %>% compact() %>% map_dfr(as.data.frame, .id = 'dtxsid') %>% mutate(search = 'valid', rank = 1) #valid
    t3 <- df %>% map(3) %>% compact() %>% map_dfr(as.data.frame, .id = 'dtxsid') %>% mutate(search = 'good', rank = 2) #good
    t4 <- df %>% map(4) %>% compact() %>% map_dfr(as.data.frame, .id = 'dtxsid') %>% mutate(search = 'del_casrn', rank = 3) #deleted casrn
    t5 <- df %>% map(5) %>% compact() %>% map_dfr(as.data.frame, .id = 'dtxsid') %>% mutate(search = 'other', rank = 4) #other
    df <- bind_rows(t1, t3, t4, t5) %>% rename(value = '.x[[i]]')
    rm(t1, t3, t4, t5)
  }

  cat(green('\nSearch complete!\n'))
  return(df)
}
