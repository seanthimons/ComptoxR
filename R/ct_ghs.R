#GHS----
#' Retrieve data from PubChem content pages by DTXSID
#'
#' Retrieve data from PubChem content pages by CID after searching for the curated DTXSID-PubChem CID. After retrieving the 'Safety and Hazard' section from PubChem, the function cuts down the list to only show GHS data that uses the 'H'Hazard code. All others are discarded.
#'
#' @param query A DTXSID (in quotes) or a list of DTXSIDs to be queried.
#'
#' @return A tibble of results
#' @export

ct_ghs <- function(query) {
  ct_df <- ct_details(query)
  ct_df <- ct_df %>%
    select(dtxsid, pubchemCid) %>%
    filter(!is.na(pubchemCid)) %>%
    rename(cid = pubchemCid)

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

  ct_df2 <- map_df_progress(ct_df$cid, ~ pc_sect(., 'Safety and Hazards'))
  ct_df2$CID <- as.integer(ct_df2$CID)
  ct_df2 <- filter(ct_df2, str_starts(ct_df2$Result, 'H')) %>%
    rename(cid = CID)
  ct_df2 <- left_join(ct_df, ct_df2, by = c('cid' = 'cid'))
  ct_df2 <- rename(ct_df2, compound = dtxsid) %>% as_tibble()
  return(ct_df2)
}
