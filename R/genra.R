#' GenRA engine
#'
#' @return Returns a tibble of the different options for the variables for GenRA
#' @export
genra_engine <- function(){
  tribble(
    ~summarise, ~sumrs_by,	~engine, ~output,
    'tox_txrf',	'tox_txrf_dosage',	'genrapy',	'toxicity value (continuous, dosage)',
    'tox_txrf',	'tox_fp',	'genrapy',	'effect (binary)',
    'tox_txrf',	'tox_fp',	'genrapred',	'effect (binary)',
    'bio_txct',	'bio_fp',	'genrapy',	'hit (binary)',
    'bio_txct',	'bio_fp',	'genrapred',	'hit (binary)',

  )
}

##Neighbor----
#' Search for nearest neighbors
#'
#' Search for nearest neighbors based on fingerprints and data sources.
#'
#' @param query A single DTXSID (in quotes) or a list to be queried.
#' @param fp A fingerprint to search by. Defaults to Morgan fingerprints.
#' @param sel_by Select compounds by data sources. Defaults to `ToxRef`database.
#' @param n Number of nearest neighbor to search for. Defaults to 12
#'
#' @return Returns a tibble with results. First row is the searched compound.
#' @export

genra_nn <- function(query,
                     fp = c("chm_mrgn",
                            "chm_httr", #
                            "chm_ct", #toxprint chemotypes
                            "bio_txct", #toxcast fp, toxcast + tox21
                            'tox_txrf' #toxref fp, from toxrefdb2.0
                     ),
                     sel_by = c("tox_txrf", #ToxRef in vivo data
                                "bio_txct", #ToxCast HTS data
                                "no_filter"),
                     n = 12 #number of neighbors
){

  if(identical(fp, c("chm_mrgn", "chm_httr", "chm_ct", "bio_txct", 'tox_txrf'))){fp <- 'chm_mrgn'}else{fp}

  if(identical(sel_by, c("tox_txrf", "bio_txct", "no_filter"))){sel_by <- 'tox_txrf'}else{sel_by}

  base <- "https://comptox.epa.gov/genra-api/api/genra/v4/chemNN/?chem_id="
  urls <- paste0(base,
                 query,
                 "&fp=",
                 fp,
                 "&sel_by=",
                 sel_by)
  # cat(url,'\n') #debug
  response <- VERB("GET", url = urls)
  status_code <- response$status_code
  if (response$status_code != 200) {
    cat("Check connection; status code:", status_code)
  } else {
    df <- jsonlite::fromJSON(content(response, as = "text", encoding = "UTF-8"))
    rm(response, status_code) # removes status code debug
    df <- slice_head(df, n = n) %>% as_tibble()  #where neighborhood cutdown occurs
    #Sys.sleep(3) #Sleep time in-between requests
    return(df)
  }
}

##Tox info----

#' Search for existing toxicological data for a given DTXSID
#'
#' @param query A single DTXSID (in quotes) or a list to be queried.
#' @param fp A fingerprint to search by. Defaults to Morgan fingerprints.
#' @param sel_by Select compounds by data sources. Defaults to `ToxRef`database.
#'
#' @return Returns a tibble with results.
#' @export
genra_tox <- function(query,
                      #n = 12, #suggested default
                      #s = 0.1, #suggested default to get results
                      fp = c("chm_mrgn",
                             "chm_httr",
                             "chm_ct",
                             "bio_txct", #toxcast fp, toxcast + tox21
                             'tox_txrf' #toxref fp, from toxrefdb2.0
                      ),
                      #select only those chemicals that have the corresponding data
                      sel_by = c("tox_txrf", #ToxRef in vivo data
                                 "bio_txct", #ToxCast HTS data
                                 "no_filter") #slow
)
{

  if(identical(fp, c("chm_mrgn", "chm_httr", "chm_ct", "bio_txct", 'tox_txrf'))){fp <- 'chm_mrgn'}else{fp}

  if(identical(sel_by, c("tox_txrf", "bio_txct", "no_filter"))){sel_by <- 'tox_txrf'}else{sel_by}

  base <- "https://comptox.epa.gov/genra-api/api/genra/v4/dataMatrix/?chem_id="

  url <-
    paste0(base,
           query,
           #"&k0=",n,

           #"&s0=",s,

           "&fp=",fp,

           "&sel_by=",sel_by)

  #cat(url,'\n')
  cat('\n','Parsing:',query,'\n')
  response <- VERB("GET", url = url)
  status_code <- response$status_code
  # return(status_code)
  if (response$status_code != 200) {
    cat("Check connection; status code:", status_code)
  } else {
    df <- jsonlite::fromJSON(content(response, as = "text", encoding = "UTF-8"))
    rm(response, status_code) # removes status code debug
    c_list <- df$coldef$dsstox_sid # names the outputs
    names(df$row) <- df$rowdef$row_id
    df2 <-
      map_dfr(df$row, ~ slice(select(., isPrediction:value), 1)) # condenses responses
    df <- bind_cols(df$rowdef, df2) # rebinds to parent data frame
    df <-
      rename(df, effect_desc = "description...3", stat_description = "description...6")
    Sys.sleep(3) #Sleep time in-between requests
    cat('\n','Request complete! \n')
    return(df)
  }
}

##RA function----

#' Searches for nearest neighbors and requests read across prediction by DTXSID
#'
#' Searches for nearest neighbors and requests read across prediction by DTXSID
#'
#' @param query A single DTXSID (in quotes).
#' @param n Number of nearest neighbors to search for. Defaults to 12.
#' @param s Minimum amount of Jaccard similarity to filter compounds by. Defaults to 0.1.
#' @param fp A fingerprint to search by. Defaults to Morgan fingerprints.
#' @param sel_by Select compounds by data sources. Defaults to `ToxRef`database.
#' @param summ Summarize results by data source. Defaults to `NULL` (no summarization).
#'
#' @return Returns a tibble with results.
#' @export
genra_ra <- function(query,
                     n = 12, #suggested default
                     s = 0.1, #suggested default to get results
                     fp = c("chm_mrgn",
                            "chm_httr",
                            "chm_ct",
                            "bio_txct", #toxcast fp, toxcast + tox21
                            'tox_txrf' #toxref fp, from toxrefdb2.0
                     ),
                     #select only those chemicals that have the corresponding data
                     sel_by = c("tox_txrf", #ToxRef in vivo data
                                "bio_txct", #ToxCast HTS data
                                "no_filter"), #slow
                     #The type of information to be summarised.
                     summ = c(NULL, #default option
                                   "tox_txrf", #ToxRef in vivo data
                                   "bio_txct",#Toxcast in vitro data)
                                   "tox_txrf_dosage"))

{

  if(identical(fp, c("chm_mrgn", "chm_httr", "chm_ct", "bio_txct", 'tox_txrf'))){fp <- 'chm_mrgn'}else{fp}

  if(identical(sel_by, c("tox_txrf", "bio_txct", "no_filter"))){sel_by <- 'tox_txrf'}else{sel_by}

  if(identical(summ, c(NULL, "tox_txrf",  "bio_txct",  "tox_txrf_dosage"))){summ <- ''}else{summ}

  base <- "https://comptox.epa.gov/genra-api/api/genra/v4/readAcross/?chem_id="

  #engine choices
  if(summ == "bio_txct"){
    var_summ <- paste0('&summarise=bio_txct')
    var_sb <- paste0('&sumrs_by=bio_fp')
    var_engine <- paste0("&engine=genrapred")
    var_obs <- ""}else{
      if(summ == "tox_txrf"){
        var_summ <- paste0('&summarise=tox_txrf')
        var_sb <- paste0('&sumrs_by=tox_fp')
        var_engine <- paste0("&engine=genrapred")
        var_obs <- ""}else{
          if(summ == 'tox_txrf_dosage'){
            var_summ <- paste0('&summarise=tox_txrf_dosage')
            var_sb <- paste0('&sumrs_by=tox_fp_dosage')
            var_engine <- paste0("&engine=genrapy")
            var_obs <- paste0("&minpos=1&minneg=-1") #for cont values
          }
          else{
            #default null options
            var_summ <- paste0('')
            var_sb <- paste0('')
            var_engine <- paste0("&engine=genrapred")
            var_obs <- ""
          }}}

  url <-
    paste0(base,
           query,
           "&k0=",n,

           "&s0=",s,

           "&fp=",fp,

           "&sel_by=",sel_by,

           var_summ,

           var_sb,

           var_obs,

           var_engine)

  #cat(url,'\n') #debug
  cat('\nSending request for: ', query)
  response <- VERB("GET", url = url)
  status_code <- response$status_code
  if (response$status_code != 200) {
    cat("\nCheck connection; status code:", status_code)
    rm(status_code)
    return(NA)
  }else {
    if(summ == 'tox_txrf_dosage'){
      cat('\nDetected continous response choice!\nPlease be patient!\n')
      df <- RJSONIO::fromJSON(content(response, as = "text", encoding = "UTF-8"),nullValue=NA_character_)
      df <- jsonlite::toJSON(df)
      df <- jsonlite::fromJSON(df)
      rm(response, status_code) # removes status code debug
      names(df$row) <- df$rowdef[,1]
      df2 <-map_dfr(df$row, ~ slice(select(., isPrediction:value), 1)) # condenses responses
      df <- bind_cols(df$rowdef, df2) # rebinds to parent data frame
      df <- rename(df, row_id = '...1', name = '...2', effect_desc = "...3", stat_description = "description")

      df1 <- df %>% select('stat_description')
      df1 <- str_split_fixed(df1$stat_description, ',', n = 4) %>% #n = how many cols you want, use Inf?
        as.data.frame()

      df2 <- df1 %>%
        transmute('pred log molar' = as.numeric(str_replace_all(V1, 'pred. log molar=',"")),
                  'pred toxicity value (mg/kg/day)' = as.numeric(str_replace_all(V2, 'pred. toxicity value=| mg/kg/day',"")),
                  'act log molar' = str_replace_all(V3, 'act. log molar=',""),
                  'act dosage (mg/kg/day)' = as.numeric(str_replace_all(V4, 'act. dosage=| mg/kg/day',"")))

      df <- df %>% select(-c('stat_description', 'isPrediction'))
      df <- bind_cols(df, df2) %>% relocate(c("pred log molar",
                                              "pred toxicity value (mg/kg/day)",
                                              "act log molar",
                                              "act dosage (mg/kg/day)"), .after = observation)
      rm(df1, df2)
      cat('\nRequest complete!')
      Sys.sleep(3) #Sleep time in-between requests
      return(df)
    }
    else{cat('\nDetected binary response choice!\n')
      df <- jsonlite::fromJSON(content(response, as = "text", encoding = "UTF-8"))
      rm(response, status_code) # removes status code debug
      names(df$row) <- df$rowdef$row_id
      df2 <- map_dfr(df$row, ~ slice(select(., isPrediction:value), 1)) # condenses responses
      df <- bind_cols(df$rowdef, df2) # rebinds to parent data frame
      df <- rename(df, effect_desc = "description...3", stat_description = "description...6")

      df1 <- df %>% select('stat_description')
      df1 <- str_split_fixed(df1$stat_description, ';', n = Inf) %>%
        as.data.frame()

      df2 <- df1 %>%
        transmute('pred resp' = V1,
                  'ACT' = as.numeric(str_replace_all(V2, 'ACT=',"")),
                  'AUC' = str_replace_all(V3, 'AUC=',""),
                  'pval' = as.numeric(str_replace_all(V4, 'pval=',"")))

      df <- df %>% select(-c('stat_description', 'isPrediction'))
      df <- df %>% mutate(observation = str_replace_all(observation,'^\\d*\\.\\d* mg\\/kg\\/day',NA_character_))
      df <- bind_cols(df, df2) %>% relocate(c("pred resp",
                                              "ACT",
                                              "AUC",
                                              "pval"), .after = observation)
      rm(df1, df2)

      cat('\nRequest complete!')
      #Sys.sleep(3) #Sleep time in-between requests
      return(df)}
  }
}


#' Batch searching for read across prediction.
#'
#'
#' @param query A single DTXSID (in quotes).
#' @param n Number of nearest neighbors to search for. Defaults to 12.
#' @param s Minimum amount of Jaccard similarity to filter compounds by. Defaults to 0.1.
#' @param fp A fingerprint to search by. Defaults to Morgan fingerprints.
#' @param sel_by Select compounds by data sources. Defaults to `ToxRef`database.
#' @param summ Summarize results by data source. Defaults to `NULL` (no summarization).
#'
#' @return Returns a tibble with results.
#' @export
genra_batch_ra <- function(query,
                           n = 12, #suggested default
                           s = 0.1, #suggested default to get results
                           fp = c("chm_mrgn",
                                  "chm_httr",
                                  "chm_ct",
                                  "bio_txct", #toxcast fp, toxcast + tox21
                                  'tox_txrf' #toxref fp, from toxrefdb2.0
                           ),
                           #select only those chemicals that have the corresponding data
                           sel_by = c("tox_txrf", #ToxRef in vivo data
                                      "bio_txct", #ToxCast HTS data
                                      "no_filter"), #slow
                           #The type of information to be summarised.
                           summ = c(NULL, #default option
                                         "tox_txrf", #ToxRef in vivo data
                                         "bio_txct",#Toxcast in vitro data)
                                         "tox_txrf_dosage")

){

  if(identical(fp, c("chm_mrgn", "chm_httr", "chm_ct", "bio_txct", 'tox_txrf'))){fp <- 'chm_mrgn'}else{fp}

  if(identical(sel_by, c("tox_txrf", "bio_txct", "no_filter"))){sel_by <- 'tox_txrf'}else{sel_by}

  if(identical(summ, c(NULL, "tox_txrf",  "bio_txct",  "tox_txrf_dosage"))){summ <- ''}else{summ}

  defaultW <- getOption("warn")
  options(warn = -1)
  pboptions(type = 'timer', char = "#")
  df <- pblapply(query, genra_ra,n,s, fp, sel_by, summ)
  names(df) <- query
  df <- map_dfr(df, ~unnest(.), .id = 'compound')
  cat(green('\nBatch request complete!'))
  options(warn = defaultW)
  return(df)
}



# {
# examples
# ra <- genra_ra(query = "DTXSID7020182",
#               n = 12,
#               s = 0.1,
#               fp = "chm_mrgn",
#               sel_by = "tox_txrf",
#               summarise = "tox_txrf")
#
#
# ra2 <- genra_ra(query = "DTXSID1022421",
#                n = 12,
#                s = 0.1,
#                fp = "chm_mrgn",
#                sel_by = "tox_txrf",
#                summarise = "tox_txrf_dosage")
#
# ra4 <- genra_ra(query = "DTXSID2021602",
#                 n = 12,
#                 s = 0.1,
#                 fp = "chm_mrgn",
#                 sel_by = "tox_txrf",
#                 summarise = "tox_txrf_dosage")
#
# ra3 <- genra_ra(query = "DTXSID7020182",
#                n = 12,
#                s = 0.1,
#                fp = "chm_mrgn",
#                sel_by = "tox_txrf",
#                summarise = "bio_txct")
#
# t2 <- genra_batch_ra(dtx_list[5:9], n = 12, s = 0.1, fp = "chm_mrgn", sel_by = "tox_txrf", summarise = "tox_txrf_dosage")
# }

##Fingerprints----

#' Function to retrieve fingerprints
#'
#' Retrieves ToxPrint Chemotyper fingerprints by DTXSID
#'
#' @param query A DTXSID (in quotes)
#'
#' @return Returns a tibble with results.
#' @export

genra_fp <- function(query){
  base <- "https://comptox.epa.gov/genra-api/api/genra/v4/chemNN/?chem_id="
  url <- paste0(base, query,"&fp=chm_ct","&sel_by=tox_txrf")
  #cat(url,'\n')
  cat('\n','Parsing:', as.character(query),'\n')
  response <- VERB("GET", url = url)
  status_code <- response$status_code
  if (response$status_code != 200) {
    cat("Check connection; status code:", status_code)
    return(NA)
  } else {
    cat('\n','Requesting:', as.character(query),'\n')
    df <- jsonlite::fromJSON(content(response, as = "text", encoding = "UTF-8"))
    rm(response, status_code) # removes status code debug
    if(is.null(df)){cat('\n','No fingerprint available! \n')
      }else{
        df <- slice_head(df, n = 1) #where neighborhood cutdown occurs
        df <- unnest(df) %>% as.data.frame() #returns a dataframe
    #Sys.sleep(3) #Sleep time in-between requests
    cat('\n','Request complete! \n')
    #Sys.sleep(3) #Sleep time in-between requests}
    }
  }
  return(df)
}

#' Function to batch search for fingerprints
#'
#' Wrapper for batch searching for ToxPrint Chemotyper fingerprints by DTXSID
#'
#' @param query A list of DTXSIDs to search for.
#'
#' @return Returns a tibble with results.
#' @export
#'
genra_batch_fp <- function(query){
  defaultW <- getOption("warn")
  options(warn = -1)
  pboptions(type = 'timer', char = "#")
  df <- pblapply(query, genra_fp)
  names(df) <- query
  df <- compact(df)
  df <- map_dfr(df, ~unnest(.))
  options(warn = defaultW)
  return(df)
}


#' Creates a Toxprint Enrichment table
#'
#' Recommended usage is to *not* use this function, and use the `genra_batch_toxprint_tbl()` which wraps around`genra_batch_fp()` and this function.
#'
#' @param df Takes dataframe from the output of the`genra_batch_fp()` function and creates the in-vitro enrichment table.
#'
#' @return Returns a tibble with results.
#' @export
#'
genra_toxprint_tbl <- function(df){
  #takes a dataframe from output of batch_fp and creates table of invitro enrichment table

  if(nrow(df) == 0){
  cat('\nNo fingerprints able to be made!\n')
  }else{l <- unique(df$dsstox_sid)
  tbl <- vector(mode = 'list', length = length(l))
  names(tbl) <- l
  for (i in 1:length(tbl)) {
    cat('\n Creating table for:',l[i],'\n')
    comp <- filter(df, dsstox_sid == l[i])
    tbl[[i]] <- toxprint_dict %>% filter(tox_print %in% comp$fpds) %>%
      group_by(category) %>%
      summarize(count = n_distinct(assay_name)) %>%
      as.data.frame()
  }
  tbl <- map_dfr(tbl, ~unnest(.,keep_empty = TRUE, names_sep = "_"), .id = 'compound')
  tbl <- pivot_wider(tbl, names_from = category, values_from = count)
  cat('\n Comparison table finsihed! \n')
  return(tbl)}


}


#' Batch searching for Toxprint Enrichment table.
#'
#' Takes a list of DTXSIDs and creates the Toxprint Enrichment table.
#' @param query A single DTXSID(in quotes) or a list of DTXSIDs.
#'
#' @return Returns a tibble with results, or lets the user know if a table is not able to be made.
#' @export
genra_batch_toxprint_tbl <- function(query){
  df <- genra_batch_fp(query)
  cat('\n Batch search done, creating table... \n')
  df <- genra_toxprint_tbl(df)
  if(is.null(df)){cat('\nNo enrichment table able to be made!\n')}else{return(df)}
}


# weighted search
# https://ccte-api-genra-dev.epa.gov/genra-api/api/genra/v4/dataMatrix/?chem_id=DTXSID7020182&k0=12&s0=0.1&fp=chm_ct_W2_and_bio_txct_W1&sel_by=tox_txrf
# The syntax is akin to the follows: <fp_name>_W<weight>_and_<fp_name>_W<weight>_and_<fp_name>_W<weight>
