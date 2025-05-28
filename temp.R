# Ensure 'dplyr' and 'stringr' are available
library(dplyr)
library(stringr)

# --- Define Regex Patterns for FORMULAS ---

# Organic elements for FORMULA regex
organic_element_pattern_string <- "C|H|D|T|N|O|S|P|Si|B|F|Cl|Br|I"
organic_element_pattern <- paste0("(", organic_element_pattern_string, ")")

# Inorganic elements for FORMULA regex (includes common non-metals EXCEPT C, and all metals/other elements)
inorganic_element_pattern_string <- paste0(
  "Li|Be|B|Na|Mg|Al|Si|P|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
  "He|Ne|Ar|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Xe|Cs|Ba|",
  "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og",
  "|H|D|T|N|O|S|F|Cl|Br|I" # Note: P, Si, B, etc. are repeated but | makes it fine. CRITICALLY NO 'C'
)
inorganic_element_pattern <- paste0("(", inorganic_element_pattern_string, ")")

num_pattern <- "(?:[1-9]\\d*)?"

# Organic patterns
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

# Inorganic patterns
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

# Isotope pattern for FORMULA
isotope_regex_pattern <- paste0(
  "(^\\d+[A-Z][a-z]?)|", # e.g., 14C...
  "(^\\[\\d+[A-Z][a-z]?\\](?:[1-9]\\d*)?$)|", # e.g., [90Sr] or [90Sr]2
  "((?<![A-Za-z])D(?![a-z]))|", # D (Deuterium)
  "((?<![A-Za-z])T(?![a-z]))" # T (Tritium)
)

# --- SMILES Classification Helper Functions (Refined) ---

smiles_is_likely_organic_refined <- function(s) {
  if (is.na(s) || s == "") return(FALSE)

  s_parts <- str_split(s, "\\.")[[1]] # Split SMILES by '.' for multi-component structures
  is_complex_organic_found <- FALSE

  for (part in s_parts) {
    # Skip purely ionic non-carbon parts like [Na+]
    if (
      grepl("^\\[[A-Za-z]{1,2}[0-9]*[+\\-]+[0-9]*\\]$", part) &&
        !grepl("C", part, ignore.case = TRUE)
    )
      next #ignore.case for 'c' too

    # Exclude specific simple C-containing SMILES often considered inorganic from this organic check
    # These will be caught by smiles_is_likely_inorganic if they are the primary structure
    if (
      part == "O=C=O" ||
        part == "C" ||
        part == "[C]" ||
        part == "[CH4]" ||
        part == "C#N" ||
        part == "N#C" ||
        part == "[C-]#N" ||
        part == "N#[C+]" || # Cyanide
        grepl("^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$", part) || # Carbonate [O-]C([O-])=O
        grepl("^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$", part) || # Another carbonate form
        (grepl("CO3", part) && grepl("\\[", part)) # General carbonate ion in brackets
    ) {
      next # This part is a simple inorganic carbon molecule, check other parts
    }

    # Handle simple C-ions like [C-], [CH3+]. If it's acetylide [C-]#[C-], it's organic by C#C.
    if (
      grepl("^\\[C[H0-4]?[0-9]*[+\\-]*[0-9]*\\]$", part) && part != "[C-]#[C-]"
    ) {
      next
    }

    # Look for aromatic carbon 'c' OR aliphatic 'C' involved in typical organic bonding.
    # Regex additions:
    # C[HNOSPSiBFClBrIUDT]: C bonded to common organic heteroatoms.
    # ([HNOSPSiBFClBrIUDT])C: Common organic heteroatoms bonded to C.
    # Elements derived from organic_element_pattern_string elements (excluding C itself)
    # H, D, T, N, O, S, P, Si, B, F, Cl, Br, I
    # The pattern below uses a selection of these for brevity & commonality in SMILES.
    # `[NOSPSiB]` and halogens `[FClBrI]`
    if (
      grepl("c", part) || # Aromatic carbon
        (grepl("C", part) && # Aliphatic carbon is present AND...
          (grepl(
            "CC|C=C|C#C|C\\(|C[1-9]|C@|C[NOSPSiBFClBrI]|[NOSPSiBFClBrI]C",
            part
          ))) # Typical organic structures or C-heteroatom bonds
    ) {
      is_complex_organic_found <- TRUE
      break # Found an organic part, no need to check further parts of this SMILES
    }
  }
  return(is_complex_organic_found)
}

smiles_is_likely_inorganic <- function(s) {
  if (is.na(s) || s == "") return(FALSE)

  # No aromatic carbon 'c' (a strong indicator of organic)
  if (grepl("c", s)) return(FALSE)

  s_parts <- str_split(s, "\\.")[[1]]
  all_parts_inorganic_or_simple_C <- TRUE # Assume true until proven otherwise

  for (part in s_parts) {
    # If a part was already deemed organic by the more specific organic checker, this SMILES isn't purely inorganic.
    # (This function is typically called if smiles_is_likely_organic_refined returned FALSE for the whole string)
    # However, for robustness, we can re-check parts if needed, but it might be redundant.

    if (grepl("C", part)) {
      # If carbon is present in this part
      # Check if it's a known simple inorganic carbon form
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
        part == "[C-]#[C-]" # Acetylide is borderline; here treating as simple for inorganic check

      if (!is_simple_inorg_C_part) {
        # This C-containing part is not one of the recognized simple inorganic forms.
        # And it wasn't caught by smiles_is_likely_organic_refined (otherwise this function wouldn't be called or this path taken).
        # This implies it might be an unclassified complex C-containing part.
        all_parts_inorganic_or_simple_C <- FALSE
        break
      }
    } else {
      # No carbon in this part, assume it's inorganic (e.g., [Na+], O=[Si]=O)
      # Could add checks for non-allowed complex non-carbon structures if necessary
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
  select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString) %>%
  mutate(
    inchiString = str_replace(inchiString, ".*?/", ""),
    is_isotope_formula = grepl(isotope_regex_pattern, molFormula, perl = TRUE),

    class_stage1 = case_when(
      isMarkush == TRUE ~ "MARKUSH",
      is_isotope_formula == TRUE ~ "ISOTOPE",
      str_detect(molFormula, "C") &
        str_detect(molFormula, organic_final_regex) ~
        'ORG_FORMULA',
      str_detect(molFormula, inorganic_final_regex) ~ 'INORG_FORMULA',
      .default = 'UNKNOWN_FORMULA'
    ),

    class = case_when(
      class_stage1 != "UNKNOWN_FORMULA" ~ class_stage1,
      sapply(smiles, smiles_is_likely_organic_refined) ~ "ORG_SMILES",
      sapply(smiles, smiles_is_likely_inorganic) ~ "INORG_SMILES",
      .default = 'UNKNOWN_FINAL'
    )
  ) %>%
  select(-class_stage1) %>%
  split(.$class)


q2$UNKNOWN_FINAL %>%
  select(-is_isotope_formula, -isMarkush, -class)
