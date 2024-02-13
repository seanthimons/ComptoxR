#####
test <- tribble(
~compound,~oral_amount,~dermal_amount,~bac_amount,~cancer_amount,~persist_amount,
'A',5,5,180,13,1,
'B', 10, 1,60,12,1,
'C',15,20,360,NA,1,
'D', 0, NA, NA,NA,1,
'E',1,1,NA,NA,1,
'F',2,2,NA,NA,1
)


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
  for (i in 1=length(df$qsarReadySmiles)) {
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


  url <- 'https=//comptox.epa.gov/dashboard/web-test/'

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
      select(molarLogUnits=preferredName,
             predValMolarLog=predValMass,
             expValMolarLog=expActive) %>%
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

# Executive summary
'https://comptox.epa.gov/dashboard-api/ccdapp2/executive-summary-links/search/by-dtxsid?id=DTXSID7020182'

###


#######TODO-----

tp_list <- list(tp_scores = NULL, bias = NULL, variable_coverage = NULL)

tp <- test %>%
  select(c('compound',bias$endpoint))

bias <- bias %>%
  select(endpoint, weight) %>%
  pivot_wider(names_from = endpoint,
              values_from = weight)

#Variable coverage----

cli_rule(left = 'Variable data coverage')

tp_list$variable_coverage <- tp_variable_coverage(table = test, id = 'name')
print(head(tp_list$variable_coverage, n = nrow(tp_list$variable_coverage)))

cat_line()
cli_rule()


#Backfilling----

if(missing(back_fill) == TRUE){cli_alert_warning('No back filling option specified!')
  back_fill <- NULL
}else{
  cli_alert_warning('Back filling option selected: {back_fill}')
}
cat_line()

#TP scores----
tp_scores <- tp %>%
  #removes INF
  mutate(
    across(
      .cols = everything(), ~ ifelse(is.infinite(.x), 0, .x))
  ) %>%
  #tie breaking logic needed here....
  mutate(
    across(
      .cols = !contains('name'),
      ~{if(length(na.omit(.)) == 1){
        ifelse(is.na(.x) == TRUE, 0, 1)
      }else{
        if(sd(na.omit(.)) == 0){
          ifelse(is.na(.), NA, 1)
        }else{tp_single_score(., back_fill= NULL) %>%
            round(digits = 4)}

      }}
    )
  ) %>%
  mutate(
    across(
      where(is.numeric), ~replace_na(.,0))
  )

tp_names <- tp_scores[,'name'] %>%
  as_tibble() %>%
  rename('name' = value)

tp_scores <- data.frame(mapply('*',tp_scores[,2:ncol(tp_scores)], bias)) %>%
  as_tibble()

tp_scores <- cbind(tp_names, tp_scores)

tp_scores1 <- tp_scores %>%
  rowwise() %>%
  mutate(score = sum(
    across(!contains('name')))) %>%
  relocate(score, .after = 'name') %>%
  arrange(desc(score)) %>%
  ungroup()

tp_list$tp_scores <- tp_scores
###############

'DTXSID3020465'



af <- ct_list('WIKIANTIFUNGALS')

cli_alert_warning('Large request detected!\nRequest may time out!\nRecommend to change search parameters or break up requests!\n')


