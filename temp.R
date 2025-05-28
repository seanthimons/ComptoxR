# Ensure 'dplyr' and 'stringr' are available
library(dplyr)
library(stringr)

# --- Define Regex Patterns for FORMULAS (Unchanged from original) ---
organic_element_pattern_string <- "C|H|D|T|N|O|S|P|Si|B|F|Cl|Br|I"
organic_element_pattern <- paste0("(", organic_element_pattern_string, ")")

inorganic_element_pattern_string <- paste0(
  "Li|Be|B|Na|Mg|Al|Si|P|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
  "He|Ne|Ar|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Xe|Cs|Ba|",
  "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og",
  "|H|D|T|N|O|S|F|Cl|Br|I" # Note: P, Si, B, etc. are repeated but | makes it fine. CRITICALLY NO 'C'
)
inorganic_element_pattern <- paste0("(", inorganic_element_pattern_string, ")")

num_pattern <- "(?:[1-9]\\d*)?"

organic_element_group_pattern <- paste0(
  "(?:",
  organic_element_pattern,
  num_pattern,
  ")+"
)
organic_element_parentheses_group_pattern <- paste0(
  "\\(",
  organic_element_group_pattern,
  "\\)",
  num_pattern
)
organic_element_square_bracket_group_pattern <- paste0(
  "\\[(?:",
  organic_element_group_pattern,
  "|",
  organic_element_parentheses_group_pattern,
  ")+\\]",
  num_pattern
)
organic_final_regex <- paste0(
  "^(",
  organic_element_square_bracket_group_pattern,
  "|",
  organic_element_parentheses_group_pattern,
  "|",
  organic_element_group_pattern,
  ")+$"
)

inorganic_element_group_pattern <- paste0(
  "(?:",
  inorganic_element_pattern,
  num_pattern,
  ")+"
)
inorganic_element_parentheses_group_pattern <- paste0(
  "\\(",
  inorganic_element_group_pattern,
  "\\)",
  num_pattern
)
inorganic_element_square_bracket_group_pattern <- paste0(
  "\\[(?:",
  inorganic_element_group_pattern,
  "|",
  inorganic_element_parentheses_group_pattern,
  ")+\\]",
  num_pattern
)
inorganic_final_regex <- paste0(
  "^(",
  inorganic_element_square_bracket_group_pattern,
  "|",
  inorganic_element_parentheses_group_pattern,
  "|",
  inorganic_element_group_pattern,
  ")+$"
)

isotope_regex_pattern <- paste0(
  "(^\\d+[A-Z][a-z]?)|", # e.g., 14C...
  "(^\\[\\d+[A-Z][a-z]?\\](?:[1-9]\\d*)?$)|", # e.g., [90Sr] or [90Sr]2
  "((?<![A-Za-z])D(?![a-z]))|", # D (Deuterium)
  "((?<![A-Za-z])T(?![a-z]))" # T (Tritium)
)

# --- SMILES Classification Helper Functions (Refined) ---

smiles_is_likely_organic_refined <- function(s) {
  if (is.na(s) || s == "") return(FALSE)

  s_parts <- str_split(s, "\\.")[[1]]
  is_complex_organic_found <- FALSE

  organic_C_bond_indicators <- "CC|C=C|C#C|C\\(|C[1-9]|C@|C[NOSPSiBFClBrI]|[NOSPSiBFClBrI]C|C=O|C=N|C=S"

  for (part in s_parts) {
    if (
      grepl("^\\[[A-Za-z]{1,2}[0-9]*[+\\-]+[0-9]*\\]$", part) &&
        !grepl("C", part, ignore.case = TRUE)
    ) {
      next
    }

    if (
      part == "O=C=O" ||
        part == "C" ||
        part == "[C]" ||
        part == "[CH4]" ||
        part == "C#N" ||
        part == "N#C" ||
        part == "[C-]#N" ||
        part == "N#[C+]" ||
        grepl("^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$", part) ||
        grepl("^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$", part) ||
        (grepl("CO3", part) && grepl("\\[", part)) ||
        part == "[C-]#[C-]" ||
        part == "[S-]C#N" ||
        part == "N#C[S-]" ||
        part == "S=C=N" ||
        part == "N=C=S"
    ) {
      next
    }

    if (
      grepl("^\\[C[H0-4]?[0-9]*[+\\-]*[0-9]*\\]$", part) && part != "[C-]#[C-]"
    ) {
      next
    }

    if (
      grepl("c", part) ||
        (grepl("C", part) && (grepl(organic_C_bond_indicators, part)))
    ) {
      is_complex_organic_found <- TRUE
      break
    }
  }
  return(is_complex_organic_found)
}

smiles_is_likely_inorganic <- function(s) {
  if (is.na(s) || s == "") return(FALSE)
  if (grepl("c", s)) return(FALSE)

  s_parts <- str_split(s, "\\.")[[1]]
  all_parts_inorganic_or_simple_C <- TRUE

  for (part in s_parts) {
    if (grepl("C", part)) {
      is_simple_inorg_C_part <-
        part == "O=C=O" ||
        part == "C" ||
        part == "[C]" ||
        part == "[CH4]" ||
        part == "C#N" ||
        part == "N#C" ||
        part == "[C-]#N" ||
        part == "N#[C+]" ||
        grepl("^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$", part) ||
        grepl("^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$", part) ||
        (grepl("CO3", part) && grepl("\\[", part)) ||
        part == "[C-]#[C-]" ||
        part == "[S-]C#N" ||
        part == "N#C[S-]" ||
        part == "S=C=N" ||
        part == "N=C=S"

      if (!is_simple_inorg_C_part) {
        all_parts_inorganic_or_simple_C <- FALSE
        break
      }
    }
  }
  return(all_parts_inorganic_or_simple_C)
}


# --- Classification Logic ---

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

q2 <- ct_details(query = temp, projection = 'all') %>%
  select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString)

q3 <- q2 %>%
  mutate(
    inchiString = str_replace(inchiString, ".*?/", ""),
    is_isotope_formula = grepl(
      isotope_regex_pattern,
      molFormula,
      perl = TRUE
    ),
    class_stage1 = case_when(
      isMarkush == TRUE ~ "MARKUSH",
      is_isotope_formula == TRUE ~ "ISOTOPE",
      str_detect(molFormula, "C") &
        str_detect(molFormula, organic_final_regex) ~
        'ORG_FORMULA',
      str_detect(molFormula, inorganic_final_regex) ~ 'INORG_FORMULA',
      .default = 'UNKNOWN_FORMULA'
    ),

    # Use rowwise for sapply if functions are not fully vectorized for data frame columns
    # or ensure sapply is applied correctly. Default sapply behavior on a column should be fine.
    class = case_when(
      class_stage1 != "UNKNOWN_FORMULA" ~ class_stage1,
      sapply(smiles, smiles_is_likely_organic_refined) ~ "ORG_SMILES",
      sapply(smiles, smiles_is_likely_inorganic) ~ "INORG_SMILES",
      .default = 'UNKNOWN_FINAL'
    )
  ) %>%
  mutate(
    super_category = case_when(
      class == "MARKUSH" ~ "Markush",
      class == "ISOTOPE" ~ "Isotope",
      class %in% c("ORG_FORMULA", "ORG_SMILES") ~ "Organic",
      class %in% c("INORG_FORMULA", "INORG_SMILES") ~ "Inorganic",
      class == "UNKNOWN_FINAL" ~ "Unknown",
      TRUE ~ "Other"
    )
  ) %>%
  select(-class_stage1) %>%
  split(.$super_category)


q3$UNKNOWN_FINAL %>%
  select(-is_isotope_formula, -isMarkush, -class)
