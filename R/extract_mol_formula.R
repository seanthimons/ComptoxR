# In file: R/extract_formulas.R (or wherever the factory is)

#' Creates a highly robust, two-pass function for extracting molecular formulas
#'
#' This is an internal "factory" function that only extracts formulas found
#' inside parentheses or square brackets. It is not exported for users.
#' It runs once when the package is loaded to create the optimized extractor.
#'
#' @return A function for extracting molecular formulas from within enclosures.
#' @noRd
create_formula_extractor_final <- function() {
  # --- ONE-TIME EXPENSIVE SETUP ---
  # This part (defining elements and the validator) remains the same.
  # fmt: skip
  elements_list <- c(
    'He', 'Li', 'Be', 'Ne', 'Na', 'Mg', 'Al', 'Si', 'Cl', 'Ar', 'Ca', 'Sc',
    'Ti', 'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn', 'Ga', 'Ge', 'As', 'Se',
    'Br', 'Kr', 'Rb', 'Sr', 'Zr', 'Nb', 'Mo', 'Tc', 'Ru', 'Rh', 'Pd', 'Ag',
    'Cd', 'In', 'Sn', 'Sb', 'Te', 'Xe', 'Cs', 'Ba', 'La', 'Ce', 'Pr', 'Nd',
    'Pm', 'Sm', 'Eu', 'Gd', 'Tb', 'Dy', 'Ho', 'Er', 'Tm', 'Yb', 'Lu', 'Hf',
    'Ta', 'Re', 'Os', 'Ir', 'Pt', 'Au', 'Hg', 'Tl', 'Pb', 'Bi', 'Po', 'At',
    'Rn', 'Fr', 'Ra', 'Ac', 'Th', 'Pa', 'Np', 'Pu', 'Am', 'Cm', 'Bk', 'Cf',
    'Es', 'Fm', 'Md', 'No', 'Lr', 'Rf', 'Db', 'Sg', 'Bh', 'Hs', 'Mt', 'Ds',
    'Rg', 'Cn', 'Nh', 'Fl', 'Mc', 'Lv', 'Ts', 'Og',
    'H', 'B', 'C', 'N', 'O', 'F', 'P', 'S', 'K', 'V', 'I', 'Y', 'W', 'U'
  )
  elements_pattern <- paste(elements_list, collapse = "|")
  element_chunk <- glue::glue("(?:{elements_pattern})\\d*")
  group_chunk <- glue::glue("(?:[\\[(](?:{element_chunk})+[\\])]\\d*)")
  validator_regex <- glue::glue(r"(^({element_chunk}(?:{element_chunk}|{group_chunk})*)$)")

  # --- UPDATED REGEX FOR CANDIDATE FINDING ---
  # This regex now specifically finds text enclosed in () or [].
  # It's intentionally broad to capture the whole block for later processing.
  candidate_regex <- "[\\[(][A-Za-z0-9()-.\\[\\]]+[\\])]"

  # These filter patterns are still useful.
  roman_numeral_regex <- "^(?:I|V|X|L|C|D|M){1,}$" # Anchored for whole string check
  carbon_range_regex <- "^C\\d+-\\d+$" # Anchored for whole string check

  # --- RETURN THE MODIFIED WORKHORSE FUNCTION ---
  function(text_vector) {
    # 1. Extract all potential enclosed candidates from the text vector.
    candidates <- stringr::str_extract_all(text_vector, candidate_regex)

    # 2. Iterate through each list of candidates found in each text element.
    lapply(candidates, function(cand_list) {
      if (length(cand_list) == 0) {
        return(character(0))
      }

      # 3. NEW STEP: Trim the outer parentheses/brackets from each candidate.
      # e.g., "(H2O)" becomes "H2O"
      trimmed_candidates <- stringr::str_sub(cand_list, 2, -2)

      # 4. Filter the *trimmed* candidates.
      # Filter out Roman numerals
      valid_mask_roman <- !stringr::str_detect(trimmed_candidates, roman_numeral_regex)
      # Filter out carbon backbone ranges
      valid_mask_carbon <- !stringr::str_detect(trimmed_candidates, carbon_range_regex)
      # Filter based on the formula validation regex
      valid_mask_formula <- stringr::str_detect(trimmed_candidates, validator_regex)

      # Combine all filters and apply to the trimmed candidates
      final_mask <- valid_mask_roman & valid_mask_carbon & valid_mask_formula
      trimmed_candidates[final_mask]
    })
  }
}

#' Extract molecular formulas from text

#'
#' This function finds and extracts chemically valid molecular formulas from a
#' character vector. It correctly handles parentheses, brackets, and numbers,
#' and validates against a list of all known chemical elements.
#'
#' @param text_vector A character vector of text to search.
#'
#' @return A list of character vectors. Each element of the list corresponds
#'   to an element of the input `text_vector` and contains all formulas found.
#'
#' @export
#' @importFrom stringr str_extract_all str_detect
#' @importFrom glue glue
#'
#' @examples
#' texts <- c("Water is H2O.", "Invalid: Az(B2)3.", "Complex: [Pt(NH3)2Cl2]")
#' extract_formulas(texts)

extract_formulas <- function(text_vector) {
  # This function simply calls the pre-built, optimized extractor.
  ComptoxR:::.extractor(text_vector)
}

