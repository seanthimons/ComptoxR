
prodwater <- ct_list('PRODWATER')

query <- prodwater$dtxsid

  #Payload generation----
  chemicals <- vector(mode = 'list', length = length(query))

  chemicals <- map2(chemicals,query,
                    ~{.x <- list(chemical = list(
                      sid = .y
                        )
                      )
                    })


  payload <- list(
    'chemicals' = chemicals,
    'options' = list(
      cts = NULL,
      minSimilarity = NULL,
      analogSearchType = NULL))

  response <- POST(
    url = "https://hcd.rtpnc.epa.gov/api/hazard",
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = 'json',
    progress() #progress bar
  )

  df <- content(response, "text", encoding = 'UTF-8') %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  #Cleaning----
  df <- df %>% pluck('hazardChemicals') %>%
    map(., ~ discard(.x, names(.x) == 'requestChemical')) %>%
    map(., ~ discard(.x, names(.x) == 'chemicalId'))

  names_list <- df %>%
    map(., ~map_at(., 'chemical', ~ keep(.x, names(.x) == 'sid'))) %>%
    map(., ~ discard(.x, names(.x) == 'scores')) %>%
    list_c() %>% list_c %>% unname()

  data <- list(headers = NULL, score = NULL, records = NULL)

  ##headers----
  data$headers <- df %>%
    map(., 1) %>%
    map_df(., ~.x) %>%
    mutate(dtxsid = sid) %>%
    select(dtxsid,name)

  ##score----
  data$score <- df %>%
    map(., 2) %>%
    set_names(as.list(data$headers$dtxsid)) %>%
    map(.,  ~map_df(., ~discard(.x, names(.x) == 'records'))) %>%
    map_dfr(., ~.x, .id = 'dtxsid')

  ##endpoint names----
  endpoint_names <- df %>%
    map(., ~pluck(., 'scores')) %>%
    map_dfr(.,  ~map(., ~keep(.x, names(.x) == 'hazardId'))) %>%
    distinct() %>%
    as.list()

  ##records----
  data$records <- df %>%
    map(., ~pluck(., 'scores')) %>%
    {. <- set_names(., names_list)} %>%
    map(., ~set_names(.x, endpoint_names$hazardId)) %>%
    map(., ~map(., ~modify_if(., .p = is_empty, .f = ~{(list(name = NA))}))) %>%
    map_dfr(., #dtx
            ~map_dfr(., #endpoint
                     ~.x,
                     , .id = 'endpoint'
            )
            , .id ='dtxsid'
    ) %>%
    unnest_wider(.,
                 col = 'records' ,
                 names_sep = '_'
    ) %>%
    select(-records_hazardName) %>%
    rename_with(~str_remove(., "records_"), everything()) %>%
    rename(note1 = `1`)

  #Merging----
  common_cols <- reduce(map(data[2:3], names), intersect)

  df <- data[2:3] %>% reduce(., left_join, by = common_cols) %>%
    select(-name) %>%
    left_join(data$headers, ., by = 'dtxsid') %>%
    mutate(data_id = 1:n()) %>%
    relocate(., data_id, .before = dtxsid)

  #Coercing-----
  # if(coerce == TRUE){

  data <- list(
    headers = NULL,
    data = NULL,
    score = NULL,
    records = NULL)

  ##Headers----

  data$headers <- df %>%
    select(dtxsid, name) %>%
    distinct()

  ##Data----
  data$data <- df %>%
      select(data_id,
             dtxsid:hazardId,
             finalAuthority,
             finalScore,
      ) %>%
      arrange(
        factor(hazardId, levels = c(
          "acuteMammalianOral",
          "acuteMammalianDermal",
          "acuteMammalianInhalation",
          "developmental",
          "reproductive",
          "endocrine",
          "genotoxicity",
          "carcinogenicity",
          "neurotoxicitySingle",
          "neurotoxicityRepeat",
          "systemicToxicitySingle",
          "systemicToxicityRepeat",
          "eyeIrritation",
          "skinIrritation",
          "skinSensitization",
          "acuteAquatic",
          "chronicAquatic",
          "persistence",
          "bioaccumulation",
          "exposure"
        )),
        factor(finalScore, levels = c(
          'VH',
          'H',
          'M',
          'L',
          'I',
          'ND',
          NA)),
        factor(finalAuthority, levels = c(
          'Authoritative',
          'Screening',
          'QSAR Model',
          NA))) %>%
      distinct(.,
               dtxsid,
               hazardId,
               .keep_all = T)
  ##Score----
  data$score <- data$data %>%
    pivot_wider(.,
                  id_cols = dtxsid,
                  names_from = hazardId,
                  values_from = finalScore)

  ##Records----
  {
  temp_r <- df %>%
    select(1,9:ncol(df))

  temp_d <- data$data %>%
    select(1,2,5,6)

  records <- list('hcodes' = NULL, 'cat' = NULL, 'num' = NULL, 'nd' = NULL, 'missing' = NULL)

  temp_df <- left_join(temp_d, temp_r, by = 'data_id') %>%
    mutate(hazardCode = str_replace_all(hazardCode, '-', NA_character_),
           valueMass = case_when(
             str_detect(source, 'T.E.S.T.') & str_detect(rationale, 'Positive for|Negative for') ~ NA_integer_,
             str_detect(source, 'mid-Atlantic') & str_detect(rationale, 'SFO') ~ NA_integer_,
             .default = valueMass

           ))

  ###check list----
  records_check <- left_join(temp_d, temp_r, by = 'data_id') %>% select(data_id)

  ###Hcodes----
  records$hcodes <- temp_df %>%
    filter(!is.na(hazardCode)) %>%
    select(data_id, endpoint, finalScore, hazardCode) %>%
    mutate(amount = case_when(

      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'VH' ~ 50,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'H' ~ 175,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'M' ~ 1150,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'L' ~ 2000,

      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'VH' ~ 200,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'H' ~ 600,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'M' ~ 1500,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'L' ~ 2000,

      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'VH' ~ 2,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'H' ~ 6,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'M' ~ 15,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'L' ~ 20,

      str_detect(endpoint, 'carcinogenicity') & finalScore == 'VH' ~ 10000,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'genotoxicity') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'genotoxicity') & finalScore == 'H' ~ 500,

      str_detect(endpoint, 'reproductive') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'reproductive') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'reproductive') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'developmental') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'developmental') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'developmental') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'neurotoxicitySingle') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'neurotoxicitySingle') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'neurotoxicityRepeat') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'neurotoxicityRepeat') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'systemicToxicitySingle') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'systemicToxicitySingle') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'systemicToxicityRepeat') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'systemicToxicityRepeat') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'skinSensitization') & finalScore == 'H' ~ 100,

      str_detect(endpoint, 'skinIrritation') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'eyeIrritation') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'eyeIrritation') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'eyeIrritation') & finalScore == 'M' ~ 10,

      str_detect(endpoint, 'acuteAquatic') & finalScore == 'VH' ~ 1,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'H' ~ 5,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'M' ~ 50,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'L' ~ 100,

      str_detect(endpoint, 'chronicAquatic') & finalScore == 'VH' ~ 0.1,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'H' ~ 0.55,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'M' ~ 5.5,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'L' ~ 10,

      .default = NA_real_
    ),
    invert_flag = case_when(
      str_detect(endpoint, 'acuteMammalianOral|acuteMammalianDermal|acuteMammalianInhalation|acuteAquatic|chronicAquatic') ~ TRUE,
      .default = FALSE
    )) %>% select(data_id, endpoint, amount, invert_flag)

  ###Numerical----
  records$num <- temp_df %>%
    filter(finalScore != 'ND' & finalScore != 'I' & !is.na(valueMass)) %>%
    #filter(!str_detect(rationale,'Score of|Positive for |Negative for ')) %>%
    select(data_id, endpoint, valueMass
           # ,valueMassUnits,
           # rationale,
           # finalScore
           ) %>%
    rename(amount = valueMass) %>%
    mutate(invert_flag = case_when(
      str_detect(endpoint, 'persistence|acuteMammalianOral|acuteMammalianDermal|acuteMammalianInhalation|acuteAquatic|chronicAquatic') ~ TRUE,
      .default = NA_real_))

  ###Category----
  records$cat <- temp_df %>%
    filter(finalScore != 'ND' & finalScore != 'I') %>%
    filter(is.na(hazardCode) & is.na(valueMass)) %>%
    select(
      data_id,
      dtxsid,
      endpoint,
      finalScore,
      hazardStatement,
      rationale,
      category) %>%
    #filter(str_detect(rationale,'Score of|Positive for|Negative for|Chemical appears in|Score was assigned|Positive prediction|Prediction of')) %>%
    mutate(amount = case_when(


      #### Acute Mam Oral----
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'VH' ~ 50,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'H' ~ 175,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'M' ~ 1150,
      str_detect(endpoint, 'acuteMammalianOral') & finalScore == 'L' ~ 2000,

      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'VH' ~ 200,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'H' ~ 600,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'M' ~ 1500,
      str_detect(endpoint, 'acuteMammalianDermal') & finalScore == 'L' ~ 2000,

      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'VH' ~ 2,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'H' ~ 6,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'M' ~ 15,
      str_detect(endpoint, 'acuteMammalianInhalation') & finalScore == 'L' ~ 20,

      str_detect(endpoint, 'carcinogenicity') & finalScore == 'VH' ~ 10000,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'carcinogenicity') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'genotoxicity') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'genotoxicity') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'genotoxicity') & finalScore == 'L' ~ 1,


      str_detect(endpoint, 'endocrine') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'endocrine') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'reproductive') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'reproductive') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'reproductive') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'developmental') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'developmental') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'developmental') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'neurotoxicitySingle') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'neurotoxicitySingle') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'neurotoxicityRepeat') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'neurotoxicityRepeat') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'systemicToxicitySingle') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'systemicToxicitySingle') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'systemicToxicityRepeat') & finalScore == 'H' ~ 500,
      str_detect(endpoint, 'systemicToxicityRepeat') & finalScore == 'M' ~ 100,

      str_detect(endpoint, 'skinSensitization') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'skinSensitization') & finalScore == 'L' ~ 1,


      str_detect(endpoint, 'skinIrritation') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'skinIrritation') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'eyeIrritation') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'eyeIrritation') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'eyeIrritation') & finalScore == 'M' ~ 10,

      str_detect(endpoint, 'acuteAquatic') & finalScore == 'VH' ~ 1,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'H' ~ 5,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'M' ~ 50,
      str_detect(endpoint, 'acuteAquatic') & finalScore == 'L' ~ 100,

      str_detect(endpoint, 'chronicAquatic') & finalScore == 'VH' ~ 0.1,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'H' ~ 0.55,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'M' ~ 5.5,
      str_detect(endpoint, 'chronicAquatic') & finalScore == 'L' ~ 10,

      str_detect(endpoint, 'persistence') & finalScore == 'VH' ~ 1000,
      str_detect(endpoint, 'persistence') & finalScore == 'H' ~ 100,
      str_detect(endpoint, 'persistence') & finalScore == 'M' ~ 10,
      str_detect(endpoint, 'persistence') & finalScore == 'L' ~ 1,

      str_detect(endpoint, 'bioaccumulation') & finalScore == 'H' ~ 1000,
      str_detect(endpoint, 'bioaccumulation') & finalScore == 'L' ~ 1,

      .default = NA_real_
  ),
  invert_flag = case_when(
      str_detect(endpoint, 'acuteMammalianOral|acuteMammalianDermal|acuteMammalianInhalation|acuteAquatic|chronicAquatic') ~ TRUE,
    .default = FALSE
  )) %>% #filter(is.na(amount))
  select(data_id, endpoint, amount, invert_flag)

  ###No data----
  records$nd <- temp_df %>%
    filter(finalScore == 'ND' | finalScore == 'I') %>%
    mutate(amount = NA_real_,
           invert_flag = FALSE) %>%
    select(data_id, endpoint, amount, invert_flag)

  ##Merging----
  records <- map_dfr(records, ~.x
                     # , .id = 'source'
                     ) %>%
    mutate(amount = case_when(
      invert_flag == TRUE ~ 1/amount,
      .default = amount
    )) %>%
    select(-invert_flag)

  ##Missing----
records_temp <- anti_join(records_check, records)
records_temp <- temp_df %>%
  filter(., data_id %in% records_temp$data_id)

if(nrow(records_temp)> 0 ) cli_abort('Filters failed!\nFile a bug report with reprex!')

##Records spreading----
data$records <- left_join(select(data$data, data_id:name), records, by = 'data_id') %>%
  select(-data_id) %>%
  pivot_wider(.,
              id_cols = dtxsid,
              names_from = endpoint,
              values_from = amount)

}

}else{df}


