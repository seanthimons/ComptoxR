#' GHS Safety comparison
#'
#' @param query A list of DTXSIDs to search for
#'
#' @return A list of data
#' @export

chemi_safety <- function(query) {

  # url <- "https://hcd.rtpnc.epa.gov/api/safety"
  url <- "https://hazard-dev.sciencedataexperts.com/api/resolver/safety-flags"

  chemicals <- vector(mode = "list", length = length(query))

  chemicals <- map2(
    chemicals, query,
    \(x, y) x <- list(
      sid = y
    )
  )

  payload <- chemicals

  response <- POST(
    url = url,
    body = rjson::toJSON(payload),
    content_type("application/json"),
    accept("application/json, text/plain, */*"),
    encode = "json",
    progress()
  )

  df <- content(response, "text", encoding = "UTF-8") %>%
    jsonlite::fromJSON(simplifyVector = FALSE)

  df <- pluck(df, "flags") %>%
    set_names(., query)

  data <- list(
    headers = NULL,
    # rqcode = NULL,
    # reg_info = NULL,
    # handling = NULL,
    # accident_release = NULL,
    ghs = NULL,
    ghs_codes = NULL
  )

  # Headers----
  data$headers <- df %>%
    map_dfr(., ~ pluck(., "chemical")) %>%
    rename(dtxsid = sid)

  # GHS----

  # data$ghs <- df %>%
  #   map(., ~ pluck(., "flags", "GHS"))


  # GHS codes----

  data$ghs_codes <- df %>%
    map(., ~ pluck(., "flags", "GHS Codes")) %>%
    map_dfr(., ~ map_dfr(., as_tibble), .id = "dtxsid") %>%
    rename(., "score" = "value")

  # Physical Hazards-----

  data$physical_hazards <- vector(mode = "list", length = 12L)

  names(data$physical_hazards) <- list(
    "Explosives",
    "Flammable Gases",
    "Aerosols",
    "Flammable Liquids",
    "Flammable Solids",
    "Self-Reactive Substances",
    "Pyrophoric",
    "Self-Heating Substances",
    "Substances which, in contact with water emit flammable gases",
    "Oxidizers",
    "Corrosive to Metals",
    "Desensitized explosives"
  )

  ##Explosives----
  data$physical_hazards$Explosives <- data$ghs_codes %>% filter(., score %in% c(
    "H200",
    "H201",
    "H202",
    "H203",
    "H205",
    "H209",
    "H210",
    "H211",
    "H204"
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H200|H201|H209|H210|H211') ~ 'VH',
      str_detect(score, 'H204') ~ 'M'
      , .default = 'ERR'
    ))

  ##"Flammable Gases"----
  data$physical_hazards$`Flammable Gases` <- data$ghs_codes %>% filter(., score %in% c(
    'H230',
    'H231',
    'H232',
    'H220',
    'H221'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H230|H231|H232|220') ~ 'VH',
      str_detect(score, 'H221') ~ 'H'
      , .default = 'ERR'
    ))
  ##Aerosols----
  data$physical_hazards$Aerosols <- data$ghs_codes %>% filter(., score %in% c(
    'H222',
    'H229',
    'H223'

  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H222') ~ 'VH',
      str_detect(score, 'H223') ~ 'H',
      str_detect(score, 'H229') ~ 'M'
      , .default = 'ERR'
    ))

  ##

  data$physical_hazards$`Flammable Liquids` <- data$ghs_codes %>% filter(., score %in% c(
    'H224',
    'H225',
    'H226',
    'H227'

  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H224') ~ 'VH',
      str_detect(score, 'H225') ~ 'H',
      str_detect(score, 'H226') ~ 'M',
      str_detect(score, 'H227') ~ 'L'
      , .default = 'ERR'
    ))
  ##
  data$physical_hazards$`Flammable Solids` <- data$ghs_codes %>% filter(., score %in% c(
    'H228'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H228') ~ 'H', .default = 'ERR'
    ))

  ##

  data$physical_hazards$`Self-Reactive Substances` <- data$ghs_codes %>% filter(., score %in% c(
    'H240',
    'H241',
    'H242'

  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H240') ~ 'VH',
      str_detect(score, 'H241') ~ 'H',
      str_detect(score, 'H242') ~ 'M', .default = 'ERR'
    ))

  data$physical_hazards$`Pyrophoric` <- data$ghs_codes %>% filter(., score %in% c(
    'H250'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H250') ~ 'VH' , .default = 'ERR'
    ))

  ##

  data$physical_hazards$`Self-Heating Substances` <- data$ghs_codes %>% filter(., score %in% c(
    'H251',
    'H252'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H251') ~ 'VH',
      str_detect(score, 'H252') ~ 'H', .default = 'ERR'
    ))

  ##

  data$physical_hazards$`Substances which, in contact with water emit flammable gases` <- data$ghs_codes %>% filter(., score %in% c(
    'H260',
    'H261'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H260') ~ 'VH',
      str_detect(score, 'H261') ~ 'H', .default = 'ERR'
    ))

  data$physical_hazards$Oxidizers <- data$ghs_codes %>% filter(., score %in% c(
    'H270',
    'H271',
    'H272'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H270|H271') ~ 'VH',
      str_detect(score, 'H272') ~ 'H', .default = 'ERR'
    ))

  ##

  data$physical_hazards$`Corrosive to Metals` <- data$ghs_codes %>% filter(., score %in% c(
    'H290'
  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H290') ~ 'VH', .default = 'ERR'
    ))

  data$physical_hazards$`Desensitized explosives` <- data$ghs_codes %>% filter(., score %in% c(
    'H206',
    'H207',
    'H208'

  )) %>%
    mutate(score = case_when(
      str_detect(score, 'H206') ~ 'VH',
      str_detect(score, 'H207') ~ 'H',
      str_detect(score, 'H208') ~ 'M', .default = 'ERR'
    ))

#Coerce-----

  temp <- imap(data$physical_hazards,
               ~{
                 nm1 <- .y
                 .x %>% rename_with(~nm1, 2)
               }
  ) %>%
    keep(., ~nrow(.) > 0)

  temp <- append(
    list(dtxsid = data$headers %>% select(name, dtxsid)),
    temp
  ) %>%
    reduce(., left_join, by ='dtxsid') %>%
    distinct(name, .keep_all = T)

  data$physical_hazards <- temp

  data$ghs_codes <- NULL

  data <- data %>% compact()

  df <- data
  return(df)
}

