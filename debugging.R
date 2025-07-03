q1  <- ct_list('CWA311HS')

q2  <- chemi_classyfire(query = q1)

q3 <- ct_details(query = q1, projection = 'all')  %>% 
  #glimpse()
  select(
  molFormula,
  preferredName,
  dtxsid,
  relatedSubstanceCount,
  relatedStructureCount,
  smiles,
  msReadySmiles,
  qsarReadySmiles,
  isotope,
  multicomponent,
  isMarkush,
  inchiString
)

q4 <- q3 %>% 
  left_join(., q2, by = c('dtxsid' = 'dtxsid'))

q5 <- q4 %>% 
  filter(is.na(kingdom)) %>% 
  select(
    dtxsid,
    preferredName,
    relatedSubstanceCount,
    relatedStructureCount,
     isMarkush
  ) %>% 
  # select(
  #   dtxsid,
  #   preferredName, 
  #   smiles, 
  #   qsarReadySmiles,
  #  # msReadySmiles,
  #   #isotope, 
  #   multicomponent, 
  #   isMarkush) %>% 
  #filter(isMarkush == FALSE) %>% 
  print()
  glimpse()

related <- ct_related(query = q5$dtxsid)

chemi_classyfire(related$dtxsid)
