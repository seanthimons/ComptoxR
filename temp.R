#' Classifies chemical compounds as Organic, Inorganic, Isotope, or Markush
#' based on molecular formula and SMILES strings.
#'
#' This function takes a dataframe of chemical compounds and adds two new
#' columns: 'class' for detailed classification and 'super_class' for
#' broader categorization.
#'
#' @param df A dataframe containing chemical compound information.
#'   Must include the following columns:
#'   - `molFormula`: Molecular formula (e.g., "C6H12O6", "H2SO4").
#'   - `preferredName`: Preferred name of the compound.
#'   - `dtxsid`: DSSTox Substance ID.
#'   - `smiles`: SMILES string representation (e.g., "CCO", "O=C=O").
#'   - `isMarkush`: Logical indicating if it's a Markush structure.
#'   - `inchiString`: InChI string (e.g., "InChI=1S/C6H12O6/c1-2-3-4-5-6(7)8-9/h1H,2-6H,7-9H,(H,2,3) (H,4,5)(H,6,7)").
#'
#' @return A dataframe with the original columns plus 'class' and 'super_class'.
#'
#' @examples
#' # Example usage with dummy data:
#' # df_example <- tibble::tribble(
#' #   ~molFormula, ~preferredName, ~dtxsid, ~smiles, ~isMarkush, ~inchiString,
#' #   "CHNaO2", "Sodium formate", "DTXSID2027090", "[Na+].[O-]C=O", FALSE, "InChI=1S/CH2O2.Na/c2-1-3;/h1H,(H,2,3);/q;+1/p-1",
#' #   "C2Ca", "Calcium carbide (CaC2)", "DTXSID4026399", "[Ca++].[C-]#[C-]", FALSE, "InChI=1S/C2.Ca/c1-2;/q-2;+2",
#' #   "C6H12O6", "Glucose", "DTXSID12345", "OC[C@H](O)[C@@H](O)[C@H](O)[C@H](O)C=O", FALSE, "InChI=1S/C6H12O6/c1-2-3-4-5-6(7)8-9/h1H,2-6H,7-9H,(H,2,3) (H,4,5)(H,6,7)",
#' #   "Fe2O3", "Iron(III) oxide", "DTXSID67890", "[O-2].[O-2].[O-2].[Fe+3].[Fe+3]", FALSE, "InChI=1S/Fe2O3/c1-3-2",
#' #   "14CH4", "Carbon-14", "DTXSID54321", "[14CH4]", FALSE, "InChI=1S/CH4/h1H4/i1+0",
#' #   "C2H4", "Polyethylene", "DTXSID98765", "*CC*", TRUE, "InChI=1S/C2H4/c1-2/h1-2H2",
#' #   "CO2", "Carbon Dioxide", "DTXSID222", "O=C=O", FALSE, "InChI=1S/CO2/c1-2-3",
#' #   "Na2CO3", "Sodium Carbonate", "DTXSID333", "[Na+].[Na+].[O-]C([O-])=O", FALSE, "InChI=1S/CH2O3.2Na/c2-1(3)4;/h(H2,2,3,4);;q-2;2*+1/p+2",
#' #   "CCl4", "Carbon Tetrachloride", "DTXSID444", "ClC(Cl)(Cl)Cl", FALSE, "InChI=1S/CCl4/c1-2(3,4)5",
#' #   "CS2", "Carbon Disulfide", "DTXSID555", "S=C=S", FALSE, "InChI=1S/CS2/c1-2-3",
#' #   "[Cu]", "Copper Atom", "DTXSID99999", "[Cu]", FALSE, "InChI=1S/Cu", # Pure element, uncharged
#' #   "[Na+]", "Sodium Ion", "DTXSID88888", "[Na+]", FALSE, "InChI=1S/Na/q+1" # Pure element, charged
#' # )
#' # classified_df <- classify_compounds(df_example)
#' # print(classified_df)
classify_compounds <- function(df) {
  # --- Define Regex Patterns for FORMULAS ---

  # Organic elements for FORMULA regex
  organic_element_pattern_string <- "C|H|D|T|N|O|S|P|Si|B|F|Cl|Br|I"
  organic_element_pattern <- paste0("(", organic_element_pattern_string, ")")

  # Inorganic elements for FORMULA regex (includes common non-metals EXCEPT C, and all metals/other elements)
  inorganic_element_pattern_string <- paste0(
    "Li|Be|B|Na|Mg|Al|Si|P|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
    "He|Ne|Ar|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Xe|Cs|Ba|",
    "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og",
    "|H|D|T|N|O|S|F|Cl|Br|I" # CRITICALLY NO 'C' here, as this is for purely inorganic elements
  )
  inorganic_element_pattern <- paste0(
    "(",
    inorganic_element_pattern_string,
    ")"
  )

  # Metal pattern for specific inorganic carbon compounds and general metal presence
  metal_pattern_string <- paste0(
    "Li|Be|Na|Mg|Al|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
    "Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Cs|Ba|",
    "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og"
  )

  num_pattern <- "(?:[1-9]\\d*)?"

  # Organic patterns for FORMULA (for strict checks on C, H, N, O, etc. without metals)
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

  # Inorganic patterns for FORMULA (for strict checks on non-carbon elements)
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

  # --- SMILES Classification Helper Functions (Refined from 5-06/claude.txt) ---

  smiles_is_likely_organic_refined <- function(s) {
    if (is.na(s) || s == "") return(FALSE)

    s_parts <- str_split(s, "\\.")[[1]] # Split SMILES by '.' for multi-component structures
    is_complex_organic_found <- FALSE

    for (part in s_parts) {
      # Skip purely ionic non-carbon parts like [Na+]
      if (
        grepl("^\\[[A-Za-z]{1,2}[0-9]*[+\\-]+[0-9]*\\]$", part, perl = TRUE) &&
          !grepl("C", part, ignore.case = TRUE)
      )
        next

      # Exclude specific simple C-containing SMILES often considered inorganic OR specific borderline cases
      if (
        part == "O=C=O" ||
          part == "C" ||
          part == "[C]" ||
          part == "[CH4]" ||
          part == "C#N" ||
          part == "N#C" ||
          part == "[C-]#N" ||
          part == "N#[C+]" || # Cyanide
          grepl("^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$", part, perl = TRUE) || # Carbonate
          grepl("^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$", part, perl = TRUE) || # Another carbonate form
          (grepl("CO3", part, perl = TRUE) &&
            grepl("\\[", part, perl = TRUE)) || # General carbonate ion
          part == "[C-]#[C-]" # Treat acetylide ion as non-complex-organic for this function
      ) {
        next
      }

      # Handle simple C-ions like [C-], [CH3+].
      # If it's acetylide [C-]#[C-], it was handled above.
      if (grepl("^\\[C[H0-4]?[0-9]*[+\\-]*[0-9]*\\]$", part, perl = TRUE)) {
        next
      }

      # Look for aromatic carbon 'c' OR aliphatic 'C' involved in typical organic bonding.
      organic_bond_pattern <- "CC|C=C|C#C|C\\(|C[1-9]|C@|C[NOSPSiBFClBrI]|[NOSPSiBFClBrI]C"
      if (
        grepl("c", part, perl = TRUE) || # Aromatic carbon
          (grepl("C", part, perl = TRUE) && # Aliphatic carbon is present AND...
            (grepl(organic_bond_pattern, part, perl = TRUE))) # Typical organic structures or C-heteroatom bonds
      ) {
        is_complex_organic_found <- TRUE
        break
      }
    }
    return(is_complex_organic_found)
  }

  smiles_is_likely_inorganic <- function(s) {
    if (is.na(s) || s == "") return(FALSE)

    # No aromatic carbon 'c' (a strong indicator of organic)
    if (grepl("c", s, perl = TRUE)) return(FALSE)

    s_parts <- str_split(s, "\\.")[[1]]
    all_parts_inorganic_or_simple_C <- TRUE

    for (part in s_parts) {
      if (grepl("C", part, perl = TRUE)) {
        # If carbon is present in this part, check if it's a known simple inorganic carbon form
        is_simple_inorg_C_part <-
          part == "O=C=O" ||
          part == "C" ||
          part == "[C]" ||
          part == "[CH4]" ||
          part == "C#N" ||
          part == "N#C" ||
          part == "[C-]#N" ||
          part == "N#[C+]" ||
          grepl("^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$", part, perl = TRUE) ||
          grepl("^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$", part, perl = TRUE) ||
          (grepl("CO3", part, perl = TRUE) &&
            grepl("\\[", part, perl = TRUE)) ||
          part == "[C-]#[C-]" # Acetylide treated as simple inorganic C here

        if (!is_simple_inorg_C_part) {
          all_parts_inorganic_or_simple_C <- FALSE
          break
        }
      } else {
        # No carbon in this part, assume it's inorganic (e.g., [Na+], O=[Si]=O)
      }
    }
    return(all_parts_inorganic_or_simple_C)
  }

  # --- Classification Logic (Enhanced) ---
  df_classified <- df %>%
    mutate(
      # Clean InChIString - keeping as a new column to preserve original
      inchiString_processed = str_replace(inchiString, ".*?/", ""),
      is_isotope_formula = grepl(
        isotope_regex_pattern,
        molFormula,
        perl = TRUE
      ),

      # Stage 1 Classification: Formula-based (more nuanced for C-containing inorganic compounds)
      class_stage1 = case_when(
        isMarkush == TRUE ~ "MARKUSH",
        is_isotope_formula == TRUE ~ "ISOTOPE",

        # --- NEW RULE: Handle single elements (charged or uncharged) specifically ---
        # This will catch [Cu], [Na+], [O-2], and also simple "Cu"
        # It should come before other inorganic rules to catch simple cases quickly.
        (grepl(
          "^\\[[A-Za-z]{1,2}[0-9]*[+\\-]*[0-9]*\\]$",
          molFormula,
          perl = TRUE
        ) | # Matches [Cu], [Na+], [O-2]
          grepl("^[A-Z][a-z]?[0-9]*$", molFormula, perl = TRUE)) & # Matches Cu, O, Fe2, H2 (single element or simple diatomic/monoatomic with num)
          !str_detect(molFormula, "C") & # Exclude C-only formulas that might be caught by the general regex (like C or CH4)
          str_detect(molFormula, inorganic_element_pattern) ~
          'INORG_FORMULA', # Ensure the element is known inorganic

        # Specific inorganic carbon compounds (ordered from most specific patterns)
        molFormula %in% c("C", "CO", "CO2", "CH4") ~ 'INORG_FORMULA', # Methane, Carbon, CO, CO2
        (grepl("CO3", molFormula, ignore.case = TRUE) |
          grepl("HCO3", molFormula, ignore.case = TRUE)) &
          str_detect(molFormula, metal_pattern_string) ~
          'INORG_FORMULA', # Carbonates/Bicarbonates with metals
        grepl("C2(Ca|Mg|Na2|K2)", molFormula) ~ 'INORG_FORMULA', # Simple Carbides like CaC2, K2C2
        grepl("CN(Na|K|Ag|Pb|Hg)?", molFormula) ~ 'INORG_FORMULA', # Simple Cyanides, e.g., NaCN, KCN, AgCN
        grepl("SCN(Na|K|Ag|Pb|Hg)?", molFormula) ~ 'INORG_FORMULA', # Simple Thiocyanates, e.g., NaSCN, KSCN
        molFormula %in% c("CCl4", "CF4", "CBr4", "CI4", "CS2") ~
          'INORG_FORMULA', # Simple carbon halides/sulfides

        # General Organic Formulas (contains Carbon and Hydrogen - this is a strong organic indicator)
        str_detect(molFormula, "C") & str_detect(molFormula, "H") ~
          'ORG_FORMULA',

        # Purely inorganic formulas (no Carbon) - This covers more complex inorganic compounds without C.
        # It's here *after* the specific single-element rule to avoid redundant checks.
        !str_detect(molFormula, "C") &
          str_detect(molFormula, inorganic_final_regex) ~ # Added perl=TRUE for consistency
          'INORG_FORMULA',

        # Fallback for remaining C-containing formulas.
        # If they reach here, it means:
        # 1. They are NOT Markush/Isotope.
        # 2. They are NOT any of the *specific* inorganic C forms listed above.
        # 3. They do NOT contain Hydrogen (so they didn't match the ORG_FORMULA C+H rule).
        # These compounds (like C2Cl4 from previous example) are best decided by SMILES rules,
        # so classify as UNKNOWN_FORMULA here to force the fallthrough to the SMILES stage.
        str_detect(molFormula, "C") ~ 'UNKNOWN_FORMULA', # This was the critical change for C2Cl4

        .default = 'UNKNOWN_FORMULA' # Should be rare with these rules
      ),

      # Final Classification: Prioritize stage1, then fall back to SMILES
      class = case_when(
        class_stage1 != "UNKNOWN_FORMULA" ~ class_stage1,
        sapply(smiles, smiles_is_likely_organic_refined) ~ "ORG_SMILES",
        sapply(smiles, smiles_is_likely_inorganic) ~ "INORG_SMILES",
        .default = 'UNKNOWN_FINAL'
      ),

      # New Super Category Column
      super_class = case_when(
        class == "MARKUSH" ~ "Markush",
        class == "ISOTOPE" ~ "Isotope",
        class %in% c("ORG_FORMULA", "ORG_SMILES") ~ "Organic",
        class %in% c("INORG_FORMULA", "INORG_SMILES") ~ "Inorganic",
        .default = "Unknown" # For any remaining UNKNOWN_FINAL
      )
    ) %>%
    select(-class_stage1) # Remove intermediate stage

  return(df_classified)
}

# --- Analysis here ---
# DO NOT RUN

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

q2 <- ct_details(query = pt$elements$dtxsid, projection = 'all') %>%
  select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString)

q2 <- ct_details(query = temp, projection = 'all') %>%
  select(molFormula, preferredName, dtxsid, smiles, isMarkush, inchiString)

{
  q1 <- q2 %>%
    slice_sample(n = 100)

  q3 <- classify_compounds(q1) %>%
    filter(isMarkush == FALSE) %>%
    select(dtxsid, smiles, super_class)

  # q4 <- q1 %>%
  #   pull(dtxsid) %>%
  #   chemi_classyfire(query = .)

  # q5 <- q4 %>%
  #   discard(., is.logical) %>%
  #   map(., function(inner_list) {
  #     map(inner_list, function(x) {
  #       if (is.null(x)) {
  #         NA # Convert NULL to NA
  #       } else {
  #         x # Otherwise return the original value
  #       }
  #     })
  #   }) %>%
  #   map(., as_tibble) %>%
  #   list_rbind(names_to = 'dtxsid')

  # q6 <- left_join(q3, q5) %>%
  #   mutate(
  #     agree = case_when(
  #       super_class == kingdom ~ TRUE,
  #       .default = FALSE
  #     ),
  #     .after = smiles
  #   ) #%>% filter(!is.na(kingdom), agree == FALSE) %>% select(-agree)
}
