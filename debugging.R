
q1 <- ct_list('CWA311HS') %>% 
  map(., ~ pluck(., 'dtxsids')) %>%
  list_c() %>%
  unique()

q2 <- chemi_safety_section(query = q1, section = 'Regulatory Information')

q3 <- q2 %>% 
  compact() %>% 
map(., ~as_tibble(.x))
q3$DTXSID8020913$`State Drinking Water Guidelines`
