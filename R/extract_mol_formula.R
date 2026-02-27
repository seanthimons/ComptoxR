# In file: R/extract_formulas.R (or wherever the factory is)

#' Creates a highly robust, two-pass function for extracting molecular formulas
#'
#' This internal "factory" function builds a pre-validated, high-performance
#' extractor that finds and validates chemical formulas only when they appear
#' inside parentheses or square brackets. It is designed to run once when the
#' package is loaded and return a closure that performs fast extraction.
#'
#' Performance notes:
#' - The list of element symbols and the validator regex are built once, avoiding
#'   repeated string assembly and allocations on every call.
#' - stringr/stringi still compile the regex internally at match-time, but
#'   pre-building the long alternations and groups avoids per-call construction
#'   overhead and improves maintainability.
#'
#' Robustness notes (updated):
#' - Correct handling of bracket characters (explicit alternation instead of a
#'   fragile character class).
#' - Candidate finder allows spaces, middle dot (\u00b7), plus/minus, and periods inside
#'   bracketed content so complexes and hydrates are captured.
#' - Roman numeral filter is case-insensitive and whitespace-tolerant to avoid
#'   misclassifying oxidation states like "(III)" or "( ii )" as formulas.
#' - Carbon backbone range filter recognizes hyphen and en dash (e.g., "C9\u201312").
#'
#' @return A function for extracting molecular formulas from within enclosures.
#' @noRd
create_formula_extractor_final <- function() {
  # --- ONE-TIME EXPENSIVE SETUP ---

  # Periodic table symbols (including lanthanides/actinides + common elements)
	#fmt:skip
  elements_list <- c(
    'He','Li','Be','Ne','Na','Mg','Al','Si','Cl','Ar','Ca','Sc','Ti','Cr','Mn','Fe','Co','Ni','Cu','Zn','Ga','Ge','As','Se',
    'Br','Kr','Rb','Sr','Zr','Nb','Mo','Tc','Ru','Rh','Pd','Ag','Cd','In','Sn','Sb','Te','Xe','Cs','Ba','La','Ce','Pr','Nd',
    'Pm','Sm','Eu','Gd','Tb','Dy','Ho','Er','Tm','Yb','Lu','Hf','Ta','Re','Os','Ir','Pt','Au','Hg','Tl','Pb','Bi','Po','At',
    'Rn','Fr','Ra','Ac','Th','Pa','Np','Pu','Am','Cm','Bk','Cf','Es','Fm','Md','No','Lr','Rf','Db','Sg','Bh','Hs','Mt','Ds',
    'Rg','Cn','Nh','Fl','Mc','Lv','Ts','Og','H','B','C','N','O','F','P','S','K','V','I','Y','W','U'
  )
  elements_pattern <- paste(elements_list, collapse = "|")

  element_chunk   <- glue::glue("(?:{elements_pattern})\\d*")
  group_chunk     <- glue::glue("(?:\\((?:{element_chunk})+\\)\\d*|\\[(?:{element_chunk})+\\]\\d*)")
  validator_regex <- glue::glue("^(?:{element_chunk}|{group_chunk})+(?:[+-]\\d*)?$")

  # FIX: Do NOT allow '(' or ')' inside the (...) alternative; allow them inside [...] only.
  candidate_regex <- "(\\([A-Za-z0-9+\\-\\.\\u00b7\\s]*\\)|\\[[A-Za-z0-9()+\\-\\.\\u00b7\\s]*\\])"

  roman_numeral_regex <- "(?i)^\\s*(?:i|v|x|l|c|d|m)+\\s*$"
  carbon_range_regex  <- "^\\s*C\\d+\\s*[-\\u2013]\\s*\\d+\\s*$"

  function(text_vector) {
    candidates <- stringr::str_extract_all(text_vector, candidate_regex)
    lapply(candidates, function(cand_list) {
      if (length(cand_list) == 0) return(character(0))

      trimmed <- stringr::str_sub(cand_list, 2, -2)
      trimmed <- stringr::str_squish(trimmed)

      keep_roman  <- !stringr::str_detect(trimmed, roman_numeral_regex)
      keep_carbon <- !stringr::str_detect(trimmed, carbon_range_regex)

      cleaned     <- stringr::str_replace_all(trimmed, "[\\u00b7\\.\\s]+", "")
      is_formula  <- stringr::str_detect(cleaned, validator_regex)

      res <- trimmed[keep_roman & keep_carbon & is_formula]
      unique(res)  # de-duplicate while preserving order
    })
  }
}

#' Extract molecular formulas from text
#'
#' Finds and returns chemically valid molecular formulas from a character vector,
#' restricted to content inside parentheses or square brackets.
#'
#' Behavior:
#' - Correctly handles parentheses, square brackets, stoichiometric numbers, and
#'   grouped substructures (e.g., "(NH3)2").
#' - Recognizes complexes and hydrates inside brackets when they include spaces,
#'   middle dot (U+00B7), plus/minus, or periods (these are normalized before validation).
#' - Ignores oxidation state Roman numerals in brackets, e.g., "(III)" or "( ii )".
#' - Excludes carbon backbone ranges like "C9-12".
#'
#' @param text_vector A character vector of text to search.
#' @return A list of character vectors. Each element corresponds to one input
#'   string and contains all formulas found inside its bracketed content.
#' @export
#' @importFrom stringr str_extract_all str_detect str_squish str_replace_all
#' @importFrom glue glue
#'
#' @examples
#' texts <- c(
#'   "Water (H2O) and ethanol (C2H5OH).",
#'   "Complex: [Pt(NH3)2Cl2] catalyst.",
#'   "Hydrate: (CuSO4 . 5H2O)",
#'   "Oxidation state: iron (III) chloride",  # "(III)" is ignored
#'   "Backbone range: C9-12 alcohols"         # "C9-12" is ignored
#' )
#' extract_formulas(texts)
extract_formulas <- function(text_vector) {

	.extractor <- .ComptoxREnv$extractor
  if (is.null(.extractor)) {
    .extractor <- create_formula_extractor_final()
    .ComptoxREnv$extractor <- .extractor
  }

  .extractor(text_vector)
}

# R/dev-helpers.R (optional)
# --------------------------
#' Rebuild and refresh the cached formula extractor (for interactive dev)
#' @keywords internal
reload_formula_extractor <- function() {
  .ComptoxREnv$extractor <- create_formula_extractor_final()
  invisible(TRUE)
}
