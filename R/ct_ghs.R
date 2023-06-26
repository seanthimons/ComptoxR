pc_ghs <- function(query){

  df <-ct_details(query) %>%
    select(dtxsid, pubchemCid) %>%
    filter(!is.na(pubchemCid)) %>%
    rename(cid = pubchemCid)

  cat("\nSearching for chemical GHS details...\n")

  url1 <- paste0("https://pubchem.ncbi.nlm.nih.gov/rest/pug/data/compound/")
  url2 <- paste0('/JSON?heading=Safety%20and%20Hazards')

  url <- paste0(url1,df$cid,url2)

  df <- map(url, ~{
    response <- VERB("GET", url = .x)
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
  })

  return(df)
}

l1 <- split(dtx_list, ceiling(seq_along(dtx_list)/20))

t1 <- pc_ghs(dtx_list)
