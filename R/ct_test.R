#TEST----
#' Retrieve results from TEST QSAR model.
#'
#' Returns queries from TEST QSAR models with the consensus model or the most likely model being returned.
#' Calls `ct_details()` and selects the QSAR-ready SMILES formula before requesting the results. Compounds without QSAR-ready SMILES will be dropped out. Compounds where the models are unable to make a predictions will be dropped as well.
#'
#' Please refer to the TEST QSAR documentation for further details.
#'
#' @param query A list of DTXSIDs to be queried.
#'
#' @return A tibble of results.
#' @export

ct_test <- function(query){

  df_pre <- ct_details(query) %>% select(dtxsid, qsarReadySmiles)

  #Removes bad/ no SMILES compounds
  cat('Removing bad/ no SMILES compounds\n')
  df <- df_pre %>% filter(!is.na(qsarReadySmiles))
  cat('\nDropped',nrow(df_pre)-nrow(df),'compounds.\n')

  #Converts symbols
  cat('\nConverting SMILES strings\n')
  for (i in 1:length(df$qsarReadySmiles)) {
    df$qsarReadySmiles[i] <-
      str_replace_all(df$qsarReadySmiles[i],'\\[', '%5B') %>%
      str_replace_all(., '\\]', '%5D') %>%
      str_replace_all(., '\\@', '%40') %>%
      str_replace_all(., '\\=', '%3D') %>%
      str_replace_all(., '\\.', '%2E') %>%
      str_replace_all(., '\\+', '%2B') %>%
      str_replace_all(., '\\-', '%2D') %>%
      str_replace_all(., '\\#', '%23')
  }


  url <- 'https://comptox.epa.gov/dashboard/web-test/'

  endpoints <- list('LC50', #96 hour fathead minnow
                    'LC50DM', #48 hour D. magna
                    'IGC50', #48 hour T. pyriformis
                    'LD50', #Oral rat
                    'BCF', #Bioconcentration factor
                    'DevTox', #Developmental toxicity
                    'ER_LogRBA', #Estrogen Receptor RBA
                    'ER_Binary', #Estrogen Receptor Binding
                    'Mutagenicity', #Ames mutagenicity
                    'BP', #Normal boiling point,
                    'FP' #Flashpoint

  )

  grid <- expand.grid(endpoints, df$qsarReadySmiles) %>% rename(end = Var1, sm = Var2)

  urls <- paste0(url, grid$e,'?smiles=', grid$sm)

  #cat('\n', urls, '\n') #debug
  cat('Sending T.E.S.T request\n')

  df <- map_dfr(urls, ~{
    #debug
    cat(.x,'\n')
    response <- VERB("GET", url = .x)
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% compact()
  })

  if('predictions' %in% colnames(df)){
    df <- df %>%
      unnest(cols = predictions, names_repair = 'universal') %>%
      filter(is.na(errorCode)) %>%
      filter(!is.na(preferredName)) %>%
      select(molarLogUnits:preferredName,
             predValMolarLog:predValMass,
             expValMolarLog:expActive) %>%
      filter(!is.na(predValMass) | !is.na(message)) %>%
      arrange(dtxsid,
              factor(endpoint,levels = endpoints),
              factor(method, levels = c('consensus','hc','sm','gc','nn'))
      ) %>%
      distinct(endpoint, dtxsid, .keep_all = T) %>%
    rename(compound = dtxsid)
    }else{df}

  cat(green('\nT.E.S.T. request complete!\n'))

  return(df)
}


ct_opera <- function(query){

  df_pre <- ct_details(query) %>% select(dtxsid, qsarReadySmiles)

  #Removes bad/ no SMILES compounds
  cat('Removing bad/ no SMILES compounds\n')
  df <- df_pre %>% filter(!is.na(qsarReadySmiles))
  cat('\nDropped',nrow(df_pre)-nrow(df),'compounds.\n')

  #Converts symbols
  cat('\nConverting SMILES strings\n')
  for (i in 1:length(df$qsarReadySmiles)) {
    df$qsarReadySmiles[i] <-
      str_replace_all(df$qsarReadySmiles[i],'\\[', '%5B') %>%
      str_replace_all(., '\\]', '%5D') %>%
      str_replace_all(., '\\@', '%40') %>%
      str_replace_all(., '\\=', '%3D') %>%
      str_replace_all(., '\\.', '%2E') %>%
      str_replace_all(., '\\+', '%2B') %>%
      str_replace_all(., '\\-', '%2D') %>%
      str_replace_all(., '\\#', '%23')
  }


  url <- 'https://comptox.epa.gov/dashboard/web-test/'

  endpoints <- list('LC50', #96 hour fathead minnow
                    'LC50DM', #48 hour D. magna
                    'IGC50', #48 hour T. pyriformis
                    'LD50', #Oral rat
                    'BCF', #Bioconcentration factor
                    'DevTox', #Developmental toxicity
                    'ER_LogRBA', #Estrogen Receptor RBA
                    'ER_Binary', #Estrogen Receptor Binding
                    'Mutagenicity' #Ames mutagenicity
  )

  grid <- expand.grid(endpoints, df$qsarReadySmiles) %>% rename(end = Var1, sm = Var2)

  urls <- paste0(url, grid$e,'?smiles=', grid$sm)

  #cat('\n', urls, '\n') #debug
  cat('Sending T.E.S.T request\n')

  df <- map_dfr(urls, ~{
    #debug
    #cat(.x,'\n')
    response <- VERB("GET", url = .x)
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% compact()
  })

  if('predictions' %in% colnames(df)){
    df <- df %>%
      unnest(cols = predictions, names_repair = 'universal') %>%
      filter(is.na(errorCode)) %>%
      filter(!is.na(preferredName)) %>%
      select(molarLogUnits:preferredName,
             predValMolarLog:predValMass,
             expValMolarLog:expActive) %>%
      filter(!is.na(predValMass) | !is.na(message)) %>%
      arrange(dtxsid,
              factor(endpoint,levels = endpoints),
              factor(method, levels = c('consensus','hc','sm','gc','nn'))
      ) %>%
      distinct(endpoint, dtxsid, .keep_all = T) %>%
    rename(compound = dtxsid)
  }else{df}

  cat(green('\nT.E.S.T. request complete!\n'))

  return(df)
}


ct_predict <- function(query){
  query <-ct_details(query)
  t <- ct_test(query)
  o <-
  return(df)
}
