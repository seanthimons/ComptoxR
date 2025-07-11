#' Detects chemical mixtures by name based on ratio patterns
#'
#' This function searches a vector of chemical names for patterns indicating a
#' ratio, such as "(1:1)" or "(2:1)". It is useful for identifying potential
#' mixtures that might not be flagged by other means. The search is robust to
#' extra whitespace.
#'
#' @param name_vector A character vector of chemical names to search.
#'
#' @return A logical vector of the same length as `name_vector`. Returns `TRUE`
#'   if a ratio pattern is found, `FALSE` if not, and `NA` for `NA` inputs.
#'
#' @export
#' @importFrom stringr str_detect
#'
#' @examples
#' test_names <- c(
#'   "Ethanol, water (1:1)",
#'   "Sodium chloride",
#'   "Styrene-butadiene copolymer (3:1)",
#'   "A name with extra spaces ( 2 : 1 )",
#'   "A name with decimals (1.5:1)",
#'   "1,2-Dichlorobenzene", # Should be FALSE
#'   NA
#' )
#' extract_mixture(names)
#' test_names %>% enframe(., name = 'idx', value = 'name') %>% mutate(bool_mix = extract_mixture(name))
#' # Expected output: TRUE, FALSE, TRUE, TRUE, TRUE, FALSE, NA
extract_mixture <- function(name_vector) {
  # This regex looks for a pattern like (number:number).
  # - \\( and \\) match literal parentheses.
  # - \\s* matches zero or more whitespace characters.
  # - \\d+ matches one or more digits.
  # - (?:\\.\\d+)? is an optional non-capturing group for a decimal part.
  #
  # The factory pattern is not needed here because the regex is simple and
  # its creation cost is virtually zero.
  ratio_pattern <- "\\(\\s*\\d+(?:\\.\\d+)?\\s*:\\s*\\d+(?:\\.\\d+)?\\s*\\)"

  # str_detect is already vectorized and returns a logical vector.
  stringr::str_detect(name_vector, ratio_pattern)
}
