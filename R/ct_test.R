
#TEST----
ct_test <- function(q){
  #Takes a SMILES string and sends for eval

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

  grid <- expand.grid(endpoints, q) %>% rename(end = Var1, sm = Var2)

  urls <- paste0(url, grid$e,'?smiles=', grid$sm)

  #cat('\n', urls, '\n') #debug
  cat('Sending T.E.S.T request\n')

  df <- map_dfr(urls, ~{
    cat(.x,'\n')
    response <- VERB("GET", url = .x)
    df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% compact()
  })

  if('predictions' %in% colnames(l2)){df <- df %>%
    unnest(cols = predictions, names_repair = 'universal') %>%
    filter(is.na(errorCode)) %>%
    filter(!is.na(preferredName)) %>%
    select(molarLogUnits:preferredName,
           predValMolarLog:predValMass,
           expValMolarLog:expActive) %>%
    arrange(dtxsid,
            factor(endpoint,levels = endpoints),
            factor(method, levels = c('consensus','hc','sm','gc','nn'))) %>%
    distinct(endpoint, dtxsid, .keep_all = T) %>%
    rename(compound = dtxsid)}else{df}

  cat(green('\nT.E.S.T. request complete!\n'))

  return(df)
}

#Bulk Test request----
ct_bulk_test <- function(q){
  #Wrapper for ct_details and ct_test
  #Takes DTXSID list for variable

  df <- ct_details(q)

  #Removes bad/ no SMILES compounds
  cat('Removing bad/ no SMILES compounds\n')
  df <- df %>% filter(!is.na(qsarReadySmiles))

  #Converts symbols
  cat('Converting SMILES strings\n')
  for (i in 1:length(df$qsarReadySmiles)) {
    df$qsarReadySmiles[i] <- str_replace_all(df$qsarReadySmiles[i],
                                             '\\[', '%5B') %>%
      str_replace_all(., '\\]', '%5D') %>%
      str_replace_all(., '\\@', '%40') %>%
      str_replace_all(., '\\=', '%3D') %>%
      str_replace_all(., '\\.', '%2E') %>%
      str_replace_all(., '\\+', '%2B') %>%
      str_replace_all(., '\\-', '%2D') %>%
      str_replace_all(., '\\#', '%23')
  }

  df <- ct_test(df$qsarReadySmiles)

  return(df)
}
