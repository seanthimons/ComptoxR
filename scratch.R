test <- tribble(
~compound,~oral_amount,~dermal_amount,~bac_amount,~cancer_amount,~persist_amount,
'A',5,5,180,13,1,
'B', 10, 1,60,12,1,
'C',15,20,360,NA,1,
'D', 0, NA, NA,NA,1,
'E',1,1,NA,NA,1,
'F',2,2,NA,NA,1
)

test <- ct_list(list_name = 'CWA311HS')

t1 <- test %>% mutate(toxcastSelect = activeAssays/totalAssays) %>% arrange(desc(toxcastSelect))

test <- t1 %>% slice_head(n= 25)

t1 <- hc_table(test$dtxsid)


tbl %>%
  select('compound', !contains('_amount')) %>%
  datatable(
    options = list(
    columnDefs = list(list(className = 'dt-center', targets = '_all')))) %>%
  formatStyle(names(tbl %>% select('compound', !contains('_amount'))),
    backgroundColor = styleEqual(c('VH', 'H','M','L', NA), c('red', 'orange', 'yellow', 'green', 'light grey')))



ct_test <- function(query){

try()

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


##############

try(

  'https://comptox.epa.gov/dashboard/web-test/'
  response <- VERB("GET", url = .x)
  df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% compact()
  )

class(try())

if(class(try)){}


t5 <- ct_details('DTXSID5025948')
t5 <- t5 %>% select(descriptorStringTsv)
t5 <- str_split(t5$descriptorStringTsv, '\t')
t5 <- set_colnames(t5, 'tp')
names(t5) <- 'tp'
t5 <- bind_cols(toxprint_ID_key, t5)

testing <- function(query){
if(length(query) > 1){
  cat('\nOver\n')
  length(query)
}else{
    cat('\nEqual\n')
  length(query)
  }
}

#Production volumes----
ct_production_vol <- function(query){

 urls <- paste0('https://comptox.epa.gov/dashboard-api/ccdapp2/production-volume/search/by-dtxsid?id=', query)

 df <- map_dfr(urls, ~{
   cat('\n',.x,'\n')
   response <- VERB("GET", url = .x)
   df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>%
     keep(names(.) == 'dtxsid' | names(.) == 'data')
})
 df <- df %>% unpack(cols = 'data')
return(df)
}

#test <- ct_production_vol('DTXSID1029706')

prod_volume <- ct_production_vol(hs311$dtxsid)

prod_volume <- prod_volume %>% distinct(., dtxsid, .keep_all = T) %>%
  select(dtxsid, amount)

ranged_vol <- prod_volume %>%
  filter(str_detect(amount, '-')) %>%
  separate_wider_delim(amount, delim = '-', names = c('low', 'high')) %>%
  mutate(high = str_remove_all(high, '<| |,')%>% as.numeric,
         low = str_remove_all(low, '<| |,') %>% as.numeric ,
         amount = rowMeans(across(low:high))
         ) %>%
  select(dtxsid, amount)

singed_vol <- prod_volume %>% filter(!str_detect(amount, '-')) %>%
  mutate(amount = str_remove_all(amount, '<| |,') %>% as.numeric)

prod_volume <- bind_rows(ranged_vol, singed_vol)


#####################


tp_test <- function(table, ID = NULL, bias = NULL, ...){

  if(is.null(ID) == TRUE){
    ID <- colnames(table[1,1])
    cat(cat('\nDefaulting to first column for ID: '),ID,'\n')
  }
  if(is.null(bias) == TRUE){
    cat(colorize('\nNo bias table detected, defaulting to filter = 0.1!\nDid you know about `hc_endpoint_coverage()`?\n', fg ='yellow'))

    bias <- hc_endpoint_coverage(table, ID, suffix = '_amount', filter = 0.1)
    print(bias)
    cat('\n')
  }

  tp <- table %>% select(c(ID,bias$endpoint))

  bias <- bias %>%
    select(endpoint, weight) %>%
    pivot_wider(names_from = endpoint,
                values_from = weight)

  tp_scores <- tp %>%
    #removes INF
    mutate(across(.cols = everything(), ~ ifelse(is.infinite(.x), 0, .x))) %>%
    #tie breaking logic needed here....
    mutate(across(.cols = !contains(ID),
                  ~{if(length(na.omit(.)) == 1){
                    ifelse(is.na(.x) == TRUE, 0, 1)
                    }else{
                      if(sd(na.omit(.)) == 0){
                        ifelse(is.na(.), NA, 1)
                      }else{tp_single_score(., ...) %>% round(digits = 4)}

                  }})) %>%
    mutate(across(where(is.numeric), ~replace_na(.,0)))

  tp_names <- tp_scores[,ID]

  tp_scores <- data.frame(mapply('*',tp_scores[,2:ncol(tp_scores)], bias)) %>% as_tibble()

  tp_scores <- cbind(tp_names, tp_scores)

  tp_scores <- tp_scores %>%
    rowwise() %>%
    mutate(score = sum(c_across(cols = !contains(ID))))

  return(tp_scores)
}















