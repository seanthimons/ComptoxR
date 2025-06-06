temp <- ct_list(
  list_name = c(
    'PRODWATER',
    'EPAHFR',
    'EPAHFRTABLE2',
    'CALWATERBDS',
    'FRACFOCUS'
  )
) %>%
  map(., ~ pluck(., 'dtxsids')) %>%
  list_c() %>%
  unique()

# q2 <- ct_details(query = pt$elements$dtxsid, projection = 'all') %>%
#   select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString)

q2 <- ct_details(query = temp, projection = 'all') %>%
  select(
  molFormula,
preferredName,
dtxsid,
smiles,
isotope,
multicomponent,
isMarkush,
inchiString
)

{
  q1 <- q2 %>%
    slice_sample(n = 100)

  dput(q1)

  q1 %>%
    pull('dtxsid') %>%
    pretty_print(.)

  q3 <- ct_classify(q1) #%>%
    #filter(isMarkush == FALSE) #%>%
    #select(dtxsid, smiles, super_class) #%>% filter(super_class != 'Inorganic')

  q4 <- q1 %>%
    pull(dtxsid) %>%
    chemi_classyfire(query = .)

  q5 <- q4 %>%
    map_if(., is.logical, ~{list(
      kingdom = NA,
      klass = NA,
      subklass = NA,
      superklass = NA
    )}) %>%
    map(., function(inner_list) {
      map(inner_list, function(x) {
        if (is.null(x)) {
          NA
        } else {
          x
        }
      })
    }) %>%
    map(., as_tibble) %>%
    list_rbind(names_to = 'dtxsid')

  q6 <- left_join(q3, q5) %>%
    #select(-kingdom)
    mutate(
      agree = case_when(
        super_class == kingdom ~ TRUE,
        .default = FALSE
      ),
      .after = smiles
    ) #%>% filter(!is.na(kingdom), agree == FALSE) %>% select(-agree)
}


q0 <- chemi_resolver(query = q1$dtxsid) %>% set_names(., 'chemical')

q0 <- chemi_hazard(query = q1$dtxsid, analogs = 'substructure', min_sim = 0.85)

q1 <- chemi_safety_section(query = )
