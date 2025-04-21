
#' EPI Suite searching for Analysis function
#'
#' @param query A vector
#'
#' @returns tibble


epi_suite_search <- function(query){


  req_list <- map(query, ~{
    request(
      base_url = Sys.getenv('epi_burl')) %>%
      req_url_path_append("/search") %>%
      req_url_query(query =  .x)
  })

  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  df <- resps %>%
    set_names(query) %>%
    resps_successes() %>%
    resps_data(\(resp) resp_body_json(resp)) %>%
    map(.,
        ~map(.x,
             ~if(is.null(.x)){NA}else{.x}) %>%
          as_tibble) %>%
    compact()


  {
    cli::cli_rule(left = 'EPI Suite compound searching')
    cli::cli_dl()
    cli::cli_li(
      c('Compounds requested' = "{length(query)}"))
    cli::cli_li(
      c('Compounds found' = "{length(df)}"))
    cli::cli_end()
    cli::cat_line()
  }

  if(length(df) > 0){return(df)}else{
    cli::cli_alert_danger('No data found!')
    return(NULL)
  }


}

epi_suite_analysis <- function(query){

  query_list <- unique(as.vector(query)) %>%
    as.list() %>%
    set_names(., unique(as.vector(query)))

  #Chose to have the data be pulled as a tibble rather than a list for diagnositic purposes

  query_list <- epi_suite_search(query_list)

  query_dict <- query_list

  query_list <- query_list %>%
    map(., ~pull(.x, 'cas'))

  req_list <- map(query_list, ~{
    request(base_url = Sys.getenv('epi_burl')) %>%
      req_url_path_append("/submit") %>%
      req_url_query(cas =  .x)
  })

  cli::cli_alert_warning('Sending requests for analysis...')

  resps <- req_list %>%
    req_perform_sequential(., on_error = 'continue', progress = TRUE)

  df <- resps %>%
    set_names(query_list) %>%
    resps_successes() %>%
    map(., ~resp_body_json(.x))

  {
    cli::cli_rule(left = 'EPI Suite analysis results')
    cli::cli_dl()
    cli::cli_li(
      c('Compounds requested' = "{length(query_list)}"))
    cli::cli_li(
      c('Compounds found' = "{length(df)}"))
    cli::cli_end()
    cli::cat_line()
    }

# df <- list(dict = query_dict, data = df)

  return(df)
}

#' Pull data from EPI Suite query object
#'
#' @param response
#' @param endpoints
#'
#' @returns list or dataframe
#' @export

epi_suite_pull_data <- function(epi_obj, endpoints = NULL){

  if(missing(epi_obj)){cli::cli_abort('Please provide raw analysis object')}
  if(missing(endpoints) | is.null(endpoints)){cli::cli_abort("Missing aggregaion endpoint")}

  df <- switch(
    endpoints,
    'eco' = {
      epi_obj %>%
        map(., ~{
            keep(., names(.x) %in% c("ecosar")) %>%
            pluck(.,'ecosar', 'modelResults') %>%
            map(.,
                ~modify_in(.,
                           'flags',
                           ~list_simplify(.x) %>%
                             paste(., collapse = " "))) %>%
            map(., as_tibble) %>%
            list_rbind() %>%
            mutate(
              across(everything(), as.character),
              across(everything(), ~na_if(.x, ""))
              )
        }) %>%
        list_rbind(names_to = 'raw_search')
    },
    'fate' = {
      # biodegradationRate
      biodegrade <- epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("biodegradationRate")) %>%
          pluck(., "biodegradationRate", "models") %>%
          map(., ~discard_at(.x, 'factors')) %>%
          map(., as_tibble) %>%
          list_rbind() %>%
          add_row(name = 'Readily Biodegradable?') %>%
          mutate(
            result = case_when(
              str_detect(name, pattern = 'MITI Linear Model Prediction|MITI Non-Linear Model Prediction') & value >= 0.5 ~ 'degradable',
              str_detect(name, pattern = 'MITI Linear Model Prediction|MITI Non-Linear Model Prediction') & value < 0.5 ~ 'not degradable',
              str_detect(name, pattern = 'Linear Model Prediction|Non-Linear Model Prediction') & value >= 0.5 ~ 'fast',
              str_detect(name, pattern = 'Linear Model Prediction|Non-Linear Model Prediction') & value < 0.5 ~ 'not fast',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & between(value, 4, 5)  ~ 'hour-days',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & between(value, 3, 4)  ~ 'days-weeks',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & between(value, 2, 3)  ~ 'weeks-months',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & between(value, 1, 2)  ~ 'months-longer',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & value < 1  ~ 'longer',
              str_detect(name, pattern = 'Ultimate Biodegradation Timeframe|Primary Biodegradation Timeframe') & value > 5  ~ 'hours',
              str_detect(name, pattern = 'Anaerobic Model Prediction') & value >= 0.5 ~ 'fast',
              str_detect(name, pattern = 'Anaerobic Model Prediction') & value < 0.5 ~ 'not fast',
              .default = NA),
            final = case_when(
              name == "Ultimate Biodegradation Timeframe" & value >= 3 ~ TRUE,
              name == "Ultimate Biodegradation Timeframe" & value < 3 ~ FALSE,
              name == "MITI Linear Model Prediction" & value < 0.5 ~ FALSE,
              name == "MITI Linear Model Prediction" & value >= 0.5 ~ TRUE,
              .default = NA),
            result = case_when(
              name == 'Readily Biodegradable?' & sum(final == TRUE, na.rm = TRUE) == 2 ~ 'yes',
              name == 'Readily Biodegradable?' & sum(final == TRUE, na.rm = TRUE) != 2 ~ 'no',
              .default = result)
            ) %>%
            select(-final)
        }) %>%
        list_rbind(names_to = 'raw_search')

      hydrocarbon_biodegrade <- epi_obj %>%
        map(., ~{
            keep(., names(.x) %in% c("hydrocarbonBiodegradationRate")) %>%
            pluck(., "hydrocarbonBiodegradationRate", 'selectedValue') #%>% flatten()
        }) %>%
        map(., ~modify_at(., 'value', ~if(is.null(.x)) NA else .x)) %>%
        map(., as_tibble) %>%
        list_rbind(names_to = 'raw_search') %>%
        filter(!is.na(value))

      bioconc <- epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("bioconcentration")) %>%
          pluck(., 'bioconcentration')
        }) %>%
        map(.,
            ~keep(., names(.x) %in% c('logBioconcentrationFactor', 'logBioaccumulationFactor')) %>%
              as_tibble()
          ) %>%
        list_rbind(names_to = 'raw_search')

      list(
        bioconc = bioconc,
        biodegrade = biodegrade,
        hydrocarbon_biodegrade = hydrocarbon_biodegrade
        )
    },
    'transport' = {
      epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("fugacityModel")) %>%
          map(., ~{
            pluck(., 'model')
            }) %>%
          map(., ~keep(., names(.x) %in% c(
            "Air",
            "Water",
            "Soil",
            "Sediment",
            "Persistence"))) %>%
          flatten() %>%
          map_at(., .at = c(
            "Air",
            "Water",
            "Soil",
            "Sediment"), .f = ~{pluck(., 1, 'MassAmount')}) %>%
          map(., ~enframe(.x, name = 'name', value = 'value')) %>%
          list_rbind(names_to = 'parameter') %>%
          select(-name)
        })},
    'treatment' = {
      epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("sewageTreatmentModel")) %>%
          pluck(., 'sewageTreatmentModel', 'model') %>%
          keep(., names(.) %in% c(
            'TotalAir',
            'TotalSludge',
            'TotalBiodeg',
            'FinalEffluent',
            'TotalRemoval'
          )) %>%
          map(., ~pluck(., 'Percent')) %>%
          flatten() %>%
          as_tibble()
        }) %>%
        list_rbind(names_to = 'raw_search')
    },
    'analogs' = {

      epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("analogs")) %>% flatten() %>% unname()
        }) %>%
        compact()
    },
    'water' = {

      epi_obj %>%
        map(., ~{
          keep(., names(.x) %in% c("waterVolatilization")) %>%
            pluck(., 1) %>%
            discard_at(., 'parameters') %>%
            as_tibble()
        }) %>%
        list_rbind(names_to = 'raw_search')
    },
    cli::cli_abort('Incorrect endpoint selection')
  )

  return(df)
}

