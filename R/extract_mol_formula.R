#' Creates a highly robust, two-pass function for extracting molecular formulas.
#'
#' This is an internal "factory" function. It is not exported for users.
#' It runs once when the package is loaded to create the optimized extractor.
#'
#' @return A function for extracting molecular formulas.
#' @noRd 

create_formula_extractor_final <- function() {
  # (The full code for the factory function goes here, as we developed it)
  # ... (pasting the full code for completeness)
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
  candidate_regex <- "\\b([A-Z][a-z]?|\\d+|[()\\[\\]])+\\b"
  
  function(text_vector) {
    candidates <- stringr::str_extract_all(text_vector, candidate_regex)
    lapply(candidates, function(cand_list) {
      if (length(cand_list) == 0) return(character(0))
      cand_list[stringr::str_detect(cand_list, validator_regex)]
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