library(httr2)

make_request <- function(
    query,
    request_method,
    search_method,
    dry_run
    ) {
  base_url <- "https://api-ccte.epa.gov/"

  if(is_missing(search_method)){
    cli::cli_alert_warning('Missing search method, defaulting to `equal`')
    search_method <- 'equal'
  }

  search_method <- arg_match(search_method, values = c('equal', 'starts', 'contains'))

  path <- switch(
    search_method,
    "equal" = "chemical/search/equal/",
    "starts" = "chemical/search/start-with/",
    "contains" = "chemical/search/contain/",
    cli_abort("Invalid path modification")
  )

  req <- request(base_url) %>%
    req_headers(
      accept = "application/json",
      `x-api-key` = ct_api_key()
    ) %>%
    req_url_path_append(path)

  query = unique(as.vector(query))
  query = enframe(query, name = 'idx', value = 'raw_search') %>%
    mutate(
      cas_chk = str_remove(raw_search, "^0+"),
      cas_chk = str_remove_all(cas_chk, "-"),
      cas_chk = as.cas(cas_chk),

      searchValue  = str_to_upper(raw_search) %>%
        str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),

      searchValue = case_when(
        !is.na(cas_chk) ~ cas_chk,
        .default = searchValue
      )
    ) %>%
    select(-cas_chk) %>%
    filter(!is.na(searchValue))

  #req %>% req_dry_run()

  # HACK Until POSTs work

  if(missing(request_method)){
    cli::cli_alert_warning('Missing method, defaulting to GET request')
    request_method <- 'GET'
  }else{
    request_method <- arg_match(request_method, values = c('GET', 'POST'))
  }

  req <- switch(
    request_method,
    "GET" = req %>% req_method("GET"),
    "POST" = req %>% req_method("POST"),
    cli::cli_abort("Invalid method")
  )

  if (method == 'GET'){
    req <- map(query$searchValue, ~ {
      req <-  req %>%
        req_url_path_append(., URLencode(.x))

      req <- switch(
        path_modification,
        "equal" = req,
        #TODO Could expose this as an new arguement
        "starts" = req %>% req_url_query(., top = '500'),
        "contains" = req %>% req_url_query(., top = '500'),
        cli_abort("Invalid path modification")
      )
    })
  }

  if (method == 'POST'){
    cli::cli_abort('POST requests not allowed at this time!')

  #   sublists <- split(query, rep(1:ceiling(nrow(query)/50), each = 50, length.out = nrow(query)))
  #
  #   req <- map(sublists, ~ {
  #     req %>%
  #       req_body_json(., .x$searchValue, type = "application/json")
  #   })
  #
  }

  {
    cli::cli_rule(left = 'String search options')
    cli::cli_dl()
    cli::cli_li(c('Compound count' = "{nrow(query)}"))
    #cli::cli_li(c('Batch iterations' = "{ceiling(length(query)/50L)}"))
    cli::cli_li(c('Search type' = "{search_method}"))
    #cli::cli_li(c('Suggestions' = "{sugs}"))
    cli::cli_end()
    cli::cat_line()
  }

  if(missing(dry_run)){
    dry_run <- FALSE
  }

  if (dry_run) {

    map(req, req_dry_run)

  }else{

    resps <- req %>% req_perform_sequential(., on_error = 'continue', progress = TRUE)

    resps %>%
      resps_successes() %>%
      resps_data(\(resp) resp_body_json(resp)) %>%
      map(., ~map(.x, ~if(is.null(.x)){NA}else{.x}) %>% as_tibble) %>%
      list_rbind()

  }
}


# testing -----------------------------------------------------------------

# library(ctxR)
# q1 <- chemical_starts_with(word = 'bisphenol')

q1 <- make_request(query = c("bisphenol"), path_modification = 'starts')


query = unique(as.vector(query))
query = enframe(query, name = 'idx', value = 'raw_search') %>%
  mutate(
    cas_chk = str_remove(raw_search, "^0+"),
    cas_chk = str_remove_all(cas_chk, "-"),
    cas_chk = as.cas(cas_chk),

    searchValue  = str_to_upper(raw_search) %>%
      str_replace_all(., c('-' = ' ', '\\u00b4' = "'")),

    searchValue = case_when(
      !is.na(cas_chk) ~ cas_chk,
      .default = searchValue
    )
  ) %>%
  select(-cas_chk) %>%
  filter(!is.na(searchValue))

# ions --------------------------------------------------------------------


q1 <-
  map(pt$elements$Symbol, ~chemi_search(
  #query = 'DTXSID4023886',
  searchType = 'features',
  element_inc = .x,
  element_exc = 'ALL'), .progress = T) %>%
  keep(., ~is_tibble(.x)) %>%
  list_rbind()

q2 <- ct_details(query = q1$sid, projection = 'all')

q5 <- ct_details(query = ComptoxR::testing_chemicals$dtxsid, projection = 'all')

q6 <- q2 %>%
        select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString) %>%
        mutate(
          inchiString = str_replace(inchiString, ".*?/", ""),
          class = case_when(
            str_detect(molFormula, "\\[") ~ "INORG", #NUC
            str_detect(molFormula, "^C[a-z]") ~ 'INORG',
            str_detect(molFormula, "^C[0-9]*H?[0-9]*") ~ "ORG",

            str_detect(inchiString, "^C[0-9]*H?[0-9]*") ~"ORG",

            str_detect(smiles, "\\*") ~ "ORG",

            is.na(molFormula) ~ 'INORG', #TODO figure out if this will crash on other things than quartz

            isMarkush == TRUE ~ "ORG",

            .default = "INORG")) %>%
        split(.$class)

#TODO


#q1 <- testing_chemicals %>% pull(casrn) %>% sample(5)

q1 <- ct_details(query = ComptoxR::testing_chemicals$dtxsid, projection = 'all') %>%
  select(molFormula, preferredName, dtxsid, casrn, smiles, isMarkush, inchiString) %>%
  mutate(
    inchiString = str_replace(inchiString, ".*?/", ""),
    class = case_when(
        str_detect(molFormula, organic_final_regex) ~'ORG',
      # str_detect(molFormula, "\\[") ~ "INORG", #NUC
      # str_detect(molFormula, "^C[a-z]") ~ 'INORG',
      # str_detect(molFormula, "^C[0-9]*H?[0-9]*") ~ "ORG",
      #
      # str_detect(inchiString, "^C[0-9]*H?[0-9]*") ~"ORG",
      #
      # str_detect(smiles, "\\*") ~ "ORG",
      #
      # is.na(molFormula) ~ 'INORG', #TODO figure out if this will crash on other things than quartz
      #
      # isMarkush == TRUE ~ "ORG",

      .default = "INORG")) %>%
  split(.$class)


# Define the regex pattern for elements commonly found in organic compounds
organic_element_pattern <- paste0(
  "(C|H|N|O|S|F|Cl|Br|I)"
)

# Define the regex pattern for numbers (subscripts)
num_pattern <- "(?:[1-9]\\d*)?"

# Define the regex pattern for element groups
organic_element_group_pattern <- paste0(
  "(?:", organic_element_pattern, num_pattern, ")+"
)

# Define the regex pattern for parentheses groups
organic_element_parentheses_group_pattern <- paste0(
  "\\(", organic_element_group_pattern, "\\)", num_pattern
)

# Define the regex pattern for square bracket groups
organic_element_square_bracket_group_pattern <- paste0(
  "\\[(?:", organic_element_group_pattern, "|", organic_element_parentheses_group_pattern, ")+\\]", num_pattern
)

# Combine all patterns into the final regex for organic compounds
organic_final_regex <- paste0(
  "^(", organic_element_square_bracket_group_pattern, "|", organic_element_parentheses_group_pattern, "|", organic_element_group_pattern, ")+$"
)

# Example usage in R
stringr::str_detect("C6H12O6", organic_final_regex)

# Define the regex pattern for elements less common in organic compounds
inorganic_element_pattern <- paste0(
  "(Li|Be|Na|Mg|Al|Si|P|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Xe|Cs|Ba|La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og)"
)

# Define the regex pattern for numbers (subscripts)
num_pattern <- "(?:[1-9]\\d*)?"

# Define the regex pattern for element groups
inorganic_element_group_pattern <- paste0(
  "(?:", inorganic_element_pattern, num_pattern, ")+"
)

# Define the regex pattern for parentheses groups
inorganic_element_parentheses_group_pattern <- paste0(
  "\\(", inorganic_element_group_pattern, "\\)", num_pattern
)

# Define the regex pattern for square bracket groups
inorganic_element_square_bracket_group_pattern <- paste0(
  "\\[(?:", inorganic_element_group_pattern, "|", inorganic_element_parentheses_group_pattern, ")+\\]", num_pattern
)

# Combine all patterns into the final regex for inorganic compounds
inorganic_final_regex <- paste0(
  "^(", inorganic_element_square_bracket_group_pattern, "|", inorganic_element_parentheses_group_pattern, "|", inorganic_element_group_pattern, ")+$"
)

# Example usage in R
stringr::str_detect("NaCl", inorganic_final_regex)


q11 <- q1$ORG %>% pull(casrn) %>% sample(10)

q2 <- epi_suite_analysis(query = q11)

epi_names <- q2$`000533-74-4` %>% names()

q3 <- epi_suite_pull_data(epi_obj = q2, endpoints = 'eco')
q3 <- epi_suite_pull_data(epi_obj = q2, endpoints = 'analogs')

q3 <- epi_suite_pull_data(epi_obj = q2, endpoints = 'fate')













