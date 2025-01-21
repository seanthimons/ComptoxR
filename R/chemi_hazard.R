#' Hazard Comparison
#'
#' @description
#'
#'   Retrieves records for queried compounds.Generates a list:
#'    \itemize{
#'     \item `headers`: DTXSID and preferred name
#'     \item `data`: longform table of DTXSIDs, name, and data needed to create a HTML table with formatting
#'     \item `score` table with raw binned values
#'     \item `records` table with converted values from `score`, changes based on `coerce` arguement. Used for ToxPi calculations
#'  }
#'
#' @details
#' The `coerce` option will greatly change how the final numerical outputs of the function work:
#' \itemize{
#'   \item `simple`: Currently changes the lettered bins with *no* respect to the final authority level of the source:
#'    \itemize{
#'      \item 'VH' = `5`
#'      \item 'H' = `4`
#'      \item 'M' = `3`
#'      \item 'L' = `2`
#'      \item 'I' = `1`
#'      \item 'ND or NA' = `NA`
#'  }
#'    \item `bin`: Currently changes the lettered bins *with* respect to the final authority level of the source:
#'    \itemize{
#'      \item 'Authorative' = No change
#'      \item 'Screening' = -1/3 score penalty
#'      \item 'QSAR model' = -2/3 score penalty
#'  }
#'    \item `numerical`: Generates opinionated numerical equivalents (for GHS codes) or retrieves experimental endpoint data. Inverts data to better be used for ToxPi analysis.
#' }
#'
#' @param query A list of DTXSIDS to search for.
#' @param cts_generations A number of metabolite generations to predict for. Maximum of `4` allowed.
#' @param analogs String of variables to search for. Defaults to no analogs to look for if not specified.
#' @param min_sim Tanimoto similarity coefficient to search for analogs by. Defaults to `0.8` if an analog option and no variable is specified .
#' @param enhance Enhance responses with subjective endpoint definitions.
#' @param coerce Boolean variable to coerce the data to a numerical equivalent. Defaults to `TRUE`.
#'
#' @return A lists of dataframes
#' @export

chemi_hazard <- function(query,
                           # cts_generations = c(1, 2, 3, 4),
                           analogs = c('substructure', 'similar', 'toxprint'),
                           min_sim = NULL,
                           coerce = c('simple', 'bin', 'numerical')
){
  #Arguments----
  ##CTS generations----
  # if(!missing(cts_generations) & length(cts_generations) > 1){
  #   stop('Only one CTS option method allowed')}else{
  #     if(!missing(cts_generations) & length(cts_generations) == 1){
  #       cts_generations <- match.arg(as.character(cts_generations), choices = c('1', '2', '3', '4'))
  #     }else{cts_generations <- NULL}
  #   }

  ##Analogs----
  if(missing(analogs)){
    analogs <- NULL}else{
      if(!missing(analogs) & length(analogs) >1){
        cli_abort('Only one analog method allowed')}else{
          if(!c(analogs %in% c('substructure', 'similar', 'toxprint'))){
            cli_abort('Analog parameter not allowed!')}else{
              analogs <- stringr::str_to_upper(analogs)
            }
        }
    }

  ##Min similarity----

  if(!is.null(analogs) & !is.null(min_sim)){
    min_sim <- as.character(min_sim)
  }else{

    min_sim <- '0.8'
    #cli_abort('Something went wrong with the analog search...')
  }

  #Payload generation----
  chemicals <- vector(mode = 'list', length = length(query))

  chemicals <- map2(chemicals,query,
                    ~{.x <- list(chemical = list(
                      sid = .y))}
  )

  payload <- list(
    'chemicals' = chemicals,
    'options' = list(
      #  cts = cts_generations,
      minSimilarity = min_sim,
      analogSearchType = analogs))

  ##Payload output----
  # if(is.null(cts_generations)){cts_generations_payload <- 'NULL'}else{cts_generations_payload <- cts_generations}
  if(is.null(analogs)){analogs_payload <- 'NULL'}else{analogs_payload <- analogs}
  if(is.null(min_sim)){min_sim_payload <- 'NULL'}else{min_sim_payload <- min_sim}

  cli_rule(left = 'Hazard payload options')
  cli_dl(
    c('Number of compounds' = '{length(query)}',
      #  'CTS generations' = '{cts_generations_payload}',
      'Analog search pattern' = '{analogs_payload}',
      'Minimum simularity' = '{min_sim_payload}'
    )
  )
  cli::cli_rule()
  cli::cli_end()

  response <- POST(
    url = "https://hcd.rtpnc.epa.gov/api/hazard",
    body = payload,
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = 'json',
    progress() #progress bar
  )
  cli::cat_line()
  cli::cli_rule()

  if(response$status != 200){cli_abort('Bad request for compound!')}

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

  #records----
  data$records <- df %>%
    map(., ~pluck(., 'scores')) %>%
    {. <- set_names(., names_list)} %>%
    map(., ~set_names(.x, endpoint_names$hazardId)) %>%
    #fills in the empty records with an empty list
    map(., ~map(., ~modify_if(., .p = is_empty, .f = ~{(
      list(
        list(
          "name" = NA,
          "source" = NA,
          "listType"= NA,
          "score" = NA,
          "rationale" = NA,
          "route" = NA,
          "valueMass" = NA,
          "valueMassUnits" = NA,
          'CAS' = NA,
          'cas' = NA,
          'hazardName' = NA
        )
      )
    )}
    )
    )
    ) %>%
    map_dfr(., #dtx
            ~map_dfr(., #endpoint
                     ~.x,
                     , .id = 'endpoint'
            )
            , .id ='dtxsid'
    ) %>%
    unnest_wider(.,
                 col = 'records' ,
                 names_sep = '_') %>%
    select(-records_hazardName) %>%
    rename_with(~str_remove(., "records_"), everything())

  #merging----
  common_cols <- reduce(map(data[2:3], names), intersect)

  df <- data[2:3] %>% reduce(., left_join, by = common_cols) %>%
    select(-name) %>%
    left_join(data$headers, ., by = 'dtxsid') %>%
    mutate(data_id = 1:n()) %>%
    relocate(., data_id, .before = dtxsid)

  data <- list(
    headers = NULL,
    data = NULL,
    score = NULL,
    display_table = NULL,
    records = NULL
  )

  data$headers = df %>%
    select(dtxsid, name) %>%
    distinct()

  data$data = df %>%
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
             .keep_all = T) %>%
    mutate(display_score = case_when(
      finalAuthority == 'Authoritative' ~ paste0('<b>', finalScore, '</b>'),
      finalAuthority == 'QSAR Model' ~ paste0('<i>', finalScore, '</i>'),
      .default = finalScore
    ))

  data$score = data$data %>%
    pivot_wider(.,
                id_cols = dtxsid,
                names_from = hazardId,
                values_from = finalScore)

  data$display_table = data$data %>%
    pivot_wider(.,
                id_cols = dtxsid,
                names_from = hazardId,
                values_from = display_score)

  data$records = NULL

  #Coercing-----
  if(missing(coerce)){
    coerce <- 'simple'
  }

  # Coerce switch -----------------------------------------------------------

  {
    cli_rule(left = 'Hazard coercion options')
    cli_dl(
      c('Method' = '{coerce}')
    )
    cli_rule()
    cli_end()
  }

  switch(coerce,
         simple = {
           ## Simple----
           data$records <- data$data %>%
             mutate(amount = case_when(

               finalScore == 'VH' ~ 5,
               finalScore == 'H' ~ 4,
               finalScore == 'M' ~ 3,
               finalScore == 'L' ~ 2,
               finalScore == 'I' ~ 1,
               .default = NA_real_)) %>%
             pivot_wider(.,
                         id_cols = dtxsid,
                         names_from = hazardId,
                         values_from = amount)
         },
         bin = {
           ## Bin ----
           data$records <- data$data %>%
             mutate(
               auth_val = case_when(
                 finalAuthority == 'Authoritative' ~ 0,
                 finalAuthority == 'Screening' ~ 1/3,
                 finalAuthority == 'QSAR Model' ~ 2/3,
                 .default = 0),
               score_val = case_when(
                 finalScore == 'VH' ~ 5,
                 finalScore == 'H' ~ 4,
                 finalScore == 'M' ~ 3,
                 finalScore == 'L' ~ 2,
                 finalScore == 'I' ~ 1,
                 .default = NA_real_),
               amount = score_val - auth_val) %>%
             pivot_wider(.,
                         id_cols = dtxsid,
                         names_from = hazardId,
                         values_from = amount)
         },
         num = {
           ## Numerical----
           {
             #actual data
             temp_r <- df %>%
               select(1,9:ncol(df))

             #headers
             temp_d <- data$data %>%
               select(1,2,5,6)

             records <- list('hcodes' = NULL, 'cat' = NULL, 'num' = NULL, 'nd' = NULL)

             temp_df <- left_join(temp_d, temp_r, by = 'data_id') %>%
               mutate(hazardCode = str_replace_all(hazardCode, '-', NA_character_),
                      valueMass = case_when(
                        #TEST predictions
                        str_detect(source, 'T.E.S.T.') & str_detect(rationale, 'Positive for|Negative for') ~ NA_integer_,
                        #Cancer slope values
                        str_detect(source, 'mid-Atlantic') & str_detect(rationale, 'SFO') ~ NA_integer_,
                        .default = valueMass))

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
                 .default = NA))

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


                 ##### Filters start----
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
                 ##### Filters end----

                 .default = NA_real_
               ),
               invert_flag = case_when(
                 str_detect(endpoint, 'acuteMammalianOral|acuteMammalianDermal|acuteMammalianInhalation|acuteAquatic|chronicAquatic') ~ TRUE,
                 .default = FALSE
               )) %>% #filter(is.na(amount))
               select(data_id, endpoint, amount, invert_flag)

             ###ND or I data ----
             records$nd <- temp_df %>%
               filter(finalScore == 'ND' | finalScore == 'I') %>%
               mutate(amount = NA_real_,
                      invert_flag = FALSE) %>%
               select(data_id, endpoint, amount, invert_flag)

             ##Merging----
             records <- map(records, ~.x
                            # , .id = 'source'
             ) %>%
               list_rbind() %>%
               mutate(amount = case_when(
                 invert_flag == TRUE ~ 1/amount,
                 .default = amount
               )) %>%
               select(-invert_flag)

             ##Missing----
             records_temp <- anti_join(records_check, records, by = 'data_id')
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
         }
  )

  return(data)
}
