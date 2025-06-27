#' Classifies chemical compounds
#'
#' Classifies chemical compounds as Organic, Inorganic, Isotope, or Markush
#' based on molecular formula and SMILES strings.
#'
#' This function takes a dataframe of chemical compounds and adds three new
#' columns: 'class' for detailed classification, 'super_class' for
#' broader categorization, and 'composition' to identify mixtures.
#'
#' @param df A dataframe containing chemical compound information.
#'   Must include the following columns: `molFormula`, `preferredName`,
#'   `dtxsid`, `smiles`, `isMarkush`, `isotope`, `multicomponent`, `inchiString`.
#'
#' @return A dataframe with the original columns plus 'class', 'super_class',
#'   and 'composition'.
#'
#' @export
#' @importFrom dplyr mutate case_when select %>%
#' @importFrom stringr str_detect str_split
#'
#' @examples
#' # Example usage with dummy data:
#' # df_example <- tibble::tribble(
#' #   ~molFormula, ~preferredName, ~dtxsid, ~smiles, ~isMarkush, ~isotope, ~multicomponent,
#' #   "CHNaO2", "Sodium formate", "DTXSID2027090", "[Na+].[O-]C=O", FALSE, 0L, 1L,
#' #   "C6H12O6", "Glucose", "DTXSID12345", "OC[C@H](O)...", FALSE, 0L, 0L,
#' #   "Fe2O3", "Iron(III) oxide", "DTXSID67890", "[O-2].[O-2]...", FALSE, 0L, 1L,
#' #   "[89Sr]", "Strontium-89", "DTXSID54321", "[89Sr]", FALSE, 1L, 0L,
#' #   "C2H4", "Polyethylene", "DTXSID98765", "*CC*", TRUE, 0L, 0L,
#' #   "Cl2Sn", "Stannous chloride", "DTXSID8021351", "[Cl-].[Cl-].[Sn++]", FALSE, 0L, 1L,
#' #   NA, "Some Markush", "DTXSID9028831", NA, TRUE, 0L, 0L
#' # )
#' # classified_df <- ct_classify(df_example)
#' # print(classified_df)
ct_classify <- function(df) {
  # Call the pre-built, optimized internal classifier function.
  ComptoxR:::.classifier(df)
}


#' Creates a high-performance compound classifier function.
#'
#' This is an internal "factory" function that pre-builds all necessary
#' regex patterns and helper functions. It is not exported for users.
#'
#' @return A function that takes a dataframe and classifies its compounds.
#' @noRd
create_compound_classifier <- function() {

  # --- ONE-TIME EXPENSIVE SETUP ---
  # All regex patterns and helper functions are defined here, once.

  # --- Define Regex Patterns for FORMULAS ---
  organic_element_pattern_string <- "C|H|D|T|N|O|S|P|Si|B|F|Cl|Br|I"
  organic_element_pattern <- paste0("(", organic_element_pattern_string, ")")
  inorganic_element_pattern_string <- paste0(
    "Li|Be|B|Na|Mg|Al|Si|P|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
    "He|Ne|Ar|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Xe|Cs|Ba|",
    "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og",
    "|H|D|T|N|O|S|F|Cl|Br|I"
  )
  inorganic_element_pattern <- paste0("(", inorganic_element_pattern_string, ")")
  metal_pattern_string <- paste0(
    "Li|Be|Na|Mg|Al|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|",
    "Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|Cs|Ba|",
    "La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og"
  )
  num_pattern <- "(?:[1-9]\\d*)?"
  organic_element_group_pattern <- paste0("(?:", organic_element_pattern, num_pattern, ")+")
  organic_element_parentheses_group_pattern <- paste0("\\(", organic_element_group_pattern, "\\)", num_pattern)
  organic_element_square_bracket_group_pattern <- paste0("\\[(?:", organic_element_group_pattern, "|", organic_element_parentheses_group_pattern, ")+\\]", num_pattern)
  organic_final_regex <- paste0("^(", organic_element_square_bracket_group_pattern, "|", organic_element_parentheses_group_pattern, "|", organic_element_group_pattern, ")+$")
  inorganic_element_group_pattern <- paste0("(?:", inorganic_element_pattern, num_pattern, ")+")
  inorganic_element_parentheses_group_pattern <- paste0("\\(", inorganic_element_group_pattern, "\\)", num_pattern)
  inorganic_element_square_bracket_group_pattern <- paste0("\\[(?:", inorganic_element_group_pattern, "|", inorganic_element_parentheses_group_pattern, ")+\\]", num_pattern)
  inorganic_final_regex <- paste0("^(", inorganic_element_square_bracket_group_pattern, "|", inorganic_element_parentheses_group_pattern, "|", inorganic_element_group_pattern, ")+$")
  isotope_regex_pattern <- paste0("(^\\d+[A-Z][a-z]?)|", "(^\\[\\d+[A-Z][a-z]?\\](?:[1-9]\\d*)?$)|", "((?<![A-Za-z])D(?![a-z]))|", "((?<![A-Za-z])T(?![a-z]))")

  # --- SMILES Classification Helper Functions ---
  # These are also static and can be pre-defined
  smiles_is_likely_organic_refined <- function(s) {
    if (is.na(s) || s == "") return(FALSE)
    s_parts <- stringr::str_split(s, "\\.")[[1]]
    is_complex_organic_found <- FALSE
    for (part in s_parts) {
      if (stringr::str_detect(part, "^\\[[A-Za-z]{1,2}[0-9]*[+\\-]+[0-9]*\\]$") && !stringr::str_detect(part, "C")) next
      if (part %in% c("O=C=O", "C", "[C]", "[CH4]", "C#N", "N#C", "[C-]#N", "N#[C+]", "[C-]#[C-]")) next
      if (stringr::str_detect(part, "^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$") || stringr::str_detect(part, "^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$") || (stringr::str_detect(part, "CO3") && stringr::str_detect(part, "\\["))) next
      if (stringr::str_detect(part, "^\\[C[H0-4]?[0-9]*[+\\-]*[0-9]*\\]$")) next
      organic_bond_pattern <- "CC|C=C|C#C|C\\(|C[1-9]|C@|C[NOSPSiBFClBrI]|[NOSPSiBFClBrI]C"
      if (stringr::str_detect(part, "c") || (stringr::str_detect(part, "C") && stringr::str_detect(part, organic_bond_pattern))) {
        is_complex_organic_found <- TRUE
        break
      }
    }
    return(is_complex_organic_found)
  }

  smiles_is_likely_inorganic <- function(s) {
    if (is.na(s) || s == "") return(FALSE)
    if (stringr::str_detect(s, "^\\[[A-Za-z]{1,2}[0-9]*[+\\-]*[0-9]*\\]$") || stringr::str_detect(s, "^[A-Z][a-z]?[=]?([A-Z][a-z]?)$")) return(TRUE)
    if (stringr::str_detect(s, "c")) return(FALSE)
    s_parts <- stringr::str_split(s, "\\.")[[1]]
    all_parts_inorganic_or_simple_C <- TRUE
    for (part in s_parts) {
      if (stringr::str_detect(part, "C")) {
        is_simple_inorg_C_part <- part %in% c("O=C=O", "C", "[C]", "[CH4]", "C#N", "N#C", "[C-]#N", "N#[C+]", "[C-]#[C-]") || stringr::str_detect(part, "^\\[O-\\]C\\(\\[O-\\]\\)=\\[O\\]$") || stringr::str_detect(part, "^C\\(\\[O-\\]\\)\\(\\[O-\\]\\)=\\[O\\]$") || (stringr::str_detect(part, "CO3") && stringr::str_detect(part, "\\["))
        if (!is_simple_inorg_C_part) {
          all_parts_inorganic_or_simple_C <- FALSE
          break
        }
      }
    }
    return(all_parts_inorganic_or_simple_C)
  }

  # --- RETURN THE LIGHTWEIGHT WORKHORSE FUNCTION ---
  # This function "remembers" all the patterns and helpers defined above.
  function(df) {
    df %>%
      dplyr::mutate(
        is_isotope_formula = stringr::str_detect(molFormula, isotope_regex_pattern),
        class_stage1 = dplyr::case_when(
          isTRUE(isMarkush) ~ "MARKUSH",
          isTRUE(isotope == 1L) | (is.na(isotope) & isTRUE(is_isotope_formula)) ~ "ISOTOPE",
          molFormula %in% c("C", "CO", "CO2", "CH4") ~ 'INORG_FORMULA',
          (stringr::str_detect(molFormula, "CO3") | stringr::str_detect(molFormula, "HCO3")) & stringr::str_detect(molFormula, metal_pattern_string) ~ 'INORG_FORMULA',
          stringr::str_detect(molFormula, "C2(Ca|Mg|Na2|K2)") ~ 'INORG_FORMULA',
          stringr::str_detect(molFormula, "CN(Na|K|Ag|Pb|Hg)?") ~ 'INORG_FORMULA',
          stringr::str_detect(molFormula, "SCN(Na|K|Ag|Pb|Hg)?") ~ 'INORG_FORMULA',
          molFormula %in% c("CCl4", "CF4", "CBr4", "CI4", "CS2") ~ 'INORG_FORMULA',
          (stringr::str_detect(molFormula, "^\\[[A-Za-z]{1,2}[0-9]*[+\\-]*[0-9]*\\]$") | stringr::str_detect(molFormula, "^[A-Z][a-z]?[0-9]*$")) & stringr::str_detect(molFormula, inorganic_element_pattern) ~ 'INORG_FORMULA',
          stringr::str_detect(molFormula, "C") & stringr::str_detect(molFormula, "H") ~ 'ORG_FORMULA',
          !stringr::str_detect(molFormula, "C") & stringr::str_detect(molFormula, inorganic_final_regex) ~ 'INORG_FORMULA',
          stringr::str_detect(molFormula, "C") ~ 'UNKNOWN_FORMULA',
          .default = 'UNKNOWN_FORMULA'
        ),
        class = dplyr::case_when(
          class_stage1 != "UNKNOWN_FORMULA" ~ class_stage1,
          sapply(smiles, smiles_is_likely_organic_refined) ~ "ORG_SMILES",
          sapply(smiles, smiles_is_likely_inorganic) ~ "INORG_SMILES",
          .default = 'UNKNOWN_FINAL'
        ),
        super_class = dplyr::case_when(
          class == "MARKUSH" ~ "Markush",
          class == "ISOTOPE" ~ "Isotope",
          class %in% c("ORG_FORMULA", "ORG_SMILES") ~ "Organic compounds",
          class %in% c("INORG_FORMULA", "INORG_SMILES") ~ "Inorganic compounds",
          .default = "Unknown"
        ),
        composition = dplyr::case_when(
          stringr::str_detect(preferredName, "\\(\\d+:\\d+\\)") ~ "MIXTURE", # Classify as MIXTURE if preferredName contains a ratio (e.g., (2:1))
          multicomponent == 1L ~ "MIXTURE",
          super_class == 'Unknown' ~ "UNKNOWN",
          .default = "SINGLE SUBSTANCE"
        )
      ) %>%
      dplyr::select(-class_stage1, -is_isotope_formula)
  }
}
