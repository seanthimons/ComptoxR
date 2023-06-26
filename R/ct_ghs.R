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


#GHS----
ct_ghs <- function(x){

  #takes DTX to find GHS data
  #requires ct_details to be ran before this
  #Requires webchem service to be available or webchem package installed

  ct_df <- ct_details(x)
  ct_df <- ct_df %>%
    select(dtxsid, pubchemCid) %>%
    filter(!is.na(pubchemCid)) %>%
    rename(cid = pubchemCid)
  library(webchem)
  cat("\nSearching for chemical GHS details...\n")

  map_df_progress <- function(.x, .f, ..., .id = NULL) {
    .f <- purrr::as_mapper(.f, ...)
    pb <- progress::progress_bar$new(total = length(.x), force = TRUE)

    f <- function(...) {
      pb$tick()
      .f(...)
    }
    purrr::map_df(.x, f, ..., .id = .id)
  }

  ct_df2 <- map_df_progress(ct_df$cid, ~pc_sect(.,'Safety and Hazards'))
  ct_df2$CID <- as.integer(ct_df2$CID)
  ct_df2 <- filter(ct_df2, str_starts(ct_df2$Result, 'H')) %>%
    rename(cid = CID)
  ct_df2 <- left_join(ct_df, ct_df2, by = c('cid' = 'cid'))
  ct_df2 <- rename(ct_df2, compound = dtxsid)
  detach("package:webchem", unload = TRUE)
  return(ct_df2)
}

ct_ghs_pcid <- function(x){

  #takes DTX to find GHS data
  #requires ct_details to be ran before this
  #Requires webchem service to be available or webchem package installed

  ct_df <- x %>%
    select(dtxsid, pubchemCid) %>%
    filter(!is.na(pubchemCid)) %>%
    rename(cid = pubchemCid)
  library(webchem)
  cat("\nSearching for chemical GHS details...\n")

  map_df_progress <- function(.x, .f, ..., .id = NULL) {
    .f <- purrr::as_mapper(.f, ...)
    pb <- progress::progress_bar$new(total = length(.x), force = TRUE)

    f <- function(...) {
      pb$tick()
      .f(...)
    }
    purrr::map_df(.x, f, ..., .id = .id)
  }

  ct_df2 <- map_df_progress(ct_df$cid, ~pc_sect(.,'Safety and Hazards'))
  ct_df2$CID <- as.integer(ct_df2$CID)
  ct_df2 <- filter(ct_df2, str_starts(ct_df2$Result, 'H')) %>%
    rename(cid = CID)
  ct_df2 <- left_join(ct_df, ct_df2, by = c('cid' = 'cid'))
  ct_df2 <- rename(ct_df2, compound = dtxsid)
  detach("package:webchem", unload = TRUE)
  return(ct_df2)
}

