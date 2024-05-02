# To clean data
library(tidyverse)
library(lubridate)
library(janitor)

# To scrape data
library(rvest)
library(httr)
library(polite)

url <- 'https://en.wikipedia.org/wiki/Oxidation_state#List_of_oxidation_states_of_the_elements'

url_bow <- polite::bow(url)
url_bow

ind_html <-
  polite::scrape(url_bow) %>%  # scrape web page
  rvest::html_nodes("table.wikitable") %>% # pull out specific table
  rvest::html_table()

pt <- ind_html[[3]] %>%
  .[4:121,1:19] %>%
  setNames(., LETTERS[1:19]) %>%
  as_tibble() %>%
  mutate(
    I = as.character(I),
    A = as.numeric(A)) %>%
  mutate(across(B:S, ~na_if(., ""))) %>%
  pivot_longer(., cols = D:R, values_to = 'oxidation_state', values_drop_na = T) %>%
  select(-name) %>%
  setNames(., c('number', 'element', 'symbol', 'group', 'oxs')) %>%
  mutate(
    ox = case_when(
      stringr::str_detect(oxs, "\\+") ~ "+",
      stringr::str_detect(oxs, "\\u2212") ~ "-",
      .default = " "),
    oxs = stringr::str_remove_all(oxs, "[[:symbol:]]"),
    oxidation_state = paste0(oxs,ox) %>% str_trim(),
    search = case_when(
      oxidation_state == '0' ~ symbol,
      oxidation_state == '1-' ~ paste0(symbol,ox),
      oxidation_state == '1+' ~ paste0(symbol,ox),
      .default = paste0(symbol,oxidation_state)
    )

  ) %>%
  select(!c(oxs:ox))

