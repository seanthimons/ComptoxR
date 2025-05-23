{
  # Define the regex pattern for elements commonly found in organic compounds
  organic_element_pattern <- paste0(
    "(C|H|N|O|S|F|Cl|Br|I)"
  )

  # Define the regex pattern for numbers (subscripts)
  num_pattern <- "(?:[1-9]\\d*)?"

  # Define the regex pattern for element groups
  organic_element_group_pattern <- paste0(
    "(?:",
    organic_element_pattern,
    num_pattern,
    ")+"
  )

  # Define the regex pattern for parentheses groups
  organic_element_parentheses_group_pattern <- paste0(
    "\\(",
    organic_element_group_pattern,
    "\\)",
    num_pattern
  )

  # Define the regex pattern for square bracket groups
  organic_element_square_bracket_group_pattern <- paste0(
    "\\[(?:",
    organic_element_group_pattern,
    "|",
    organic_element_parentheses_group_pattern,
    ")+\\]",
    num_pattern
  )

  # Combine all patterns into the final regex for organic compounds
  organic_final_regex <- paste0(
    "^(",
    organic_element_square_bracket_group_pattern,
    "|",
    organic_element_parentheses_group_pattern,
    "|",
    organic_element_group_pattern,
    ")+$"
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
    "(?:",
    inorganic_element_pattern,
    num_pattern,
    ")+"
  )

  # Define the regex pattern for parentheses groups
  inorganic_element_parentheses_group_pattern <- paste0(
    "\\(",
    inorganic_element_group_pattern,
    "\\)",
    num_pattern
  )

  # Define the regex pattern for square bracket groups
  inorganic_element_square_bracket_group_pattern <- paste0(
    "\\[(?:",
    inorganic_element_group_pattern,
    "|",
    inorganic_element_parentheses_group_pattern,
    ")+\\]",
    num_pattern
  )

  # Combine all patterns into the final regex for inorganic compounds
  inorganic_final_regex <- paste0(
    "^(",
    inorganic_element_square_bracket_group_pattern,
    "|",
    inorganic_element_parentheses_group_pattern,
    "|",
    inorganic_element_group_pattern,
    ")+$"
  )

  # Example usage in R
  stringr::str_detect("NaCl", inorganic_final_regex)
}

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

q2 <- ct_details(query = temp, projection = 'all')

q3 <- q2 %>%
  select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString) %>%
  mutate(
    inchiString = str_replace(inchiString, ".*?/", ""),
    class = case_when(
      isMarkush == TRUE ~ "MARKUSH",
      # is.na(molFormula) ~ 'INORG', #TODO figure out if this will crash on other things than quartz
      str_detect(molFormula, organic_final_regex) ~ 'ORG',
      str_detect(molFormula, inorganic_final_regex) ~ 'INORG',
      .default = 'UNKNOWN'
    )
  ) %>%
  split(.$class)


