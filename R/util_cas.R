#' Checks if a string is a syntactically and algorithmically valid CASRN
#'
#' A valid CAS Registry Number (CASRN) is a string in the format "dd...d-dd-d",
#' containing 5 to 10 digits in total. The final digit is a check-digit
#' calculated using a specific algorithm. This function validates both the
#' format and the check-digit calculation.
#'
#' @param x A character vector of potential CASRN strings.
#'
#' @return A logical vector of the same length as `x`. Returns `TRUE` for
#'   each valid CASRN, `FALSE` for invalid ones, and `NA` for `NA` inputs.
#'
#' @export
#' @importFrom stringr str_detect str_remove_all str_split_i
#'
#' @examples
#' is_cas("50-00-0")  # Valid
#' is_cas("50-00-1")  # Invalid check digit
#' is_cas("7732-18-5") # Valid
#' is_cas("100-42-5")  # Valid
#' is_cas("not-a-casrn")
#' is_cas(c("50-00-0", "50-00-1", NA, "7732-18-5"))
is_cas <- function(x) {
  x <- as.character(x)
  out <- !is.na(x) & grepl("^\\d{2,7}-\\d{2}-\\d$", x)
  ok <- which(out)
  if (length(ok) > 0) {
    digits <- gsub("-", "", x[ok], fixed = TRUE)
    n <- nchar(digits)
    # Left-pad the body to 9 digits so the check-digit weights are always 9:1
    body <- substr(digits, 1, n - 1)
    body <- paste0(strrep("0", 9 - nchar(body)), body)
    d <- matrix(as.integer(unlist(strsplit(body, ""), use.names = FALSE)), ncol = 9, byrow = TRUE)
    out[ok] <- as.vector(d %*% 9:1) %% 10 == as.integer(substr(digits, n, n))
  }
  out[is.na(x)] <- NA
  out
}

#' Coerces and validates a string to a standard CASRN format
#'
#' This function attempts to convert a string into a valid Chemical Abstracts
#' Service Registry Number (CASRN). It handles common data quality issues such
#' as extra non-digit characters, missing hyphens, and leading zeros.
#' The function extracts all digits, trims any leading zeros, formats the
#' result into the standard "xx-yy-z" structure, and then validates it using
#' the `is_cas()` check-digit algorithm.
#'
#' @param x A character vector of potential CASRN strings.
#'
#' @return A character vector of the same length as `x`. Returns the correctly
#'   formatted, canonical CASRN string if valid, otherwise returns `NA_character_`.
#'
#' @export
#' @importFrom stringr str_remove_all str_sub
#'
#' @seealso [is_cas()] for the underlying validation logic.
#'
#' @examples
#' # Handles standard and padded formats
#' as_cas("50-00-0")
#' as_cas("0050-00-0") # Padded with leading zeros
#' as_cas("000575-38-2") # Another padded example
#'
#' # Handles extra characters and missing hyphens
#' as_cas("CAS: 7732-18-5")
#' as_cas("50000")
#'
#' # Returns NA for invalid CASRNs
#' as_cas("50-00-1") # Invalid check digit
#' as_cas("not-a-casrn")
as_cas <- function(x) {
  x <- as.character(x)
  # Source identifiers such as NOCAS_1355346 are not CAS numbers, even if
  # their digits happen to satisfy the CAS checksum after reformatting.
  nocas <- grepl("^\\s*NO[_[:space:]-]*CAS(?:[_[:space:]-]|$)", x, ignore.case = TRUE, perl = TRUE)

  # Keep only digits, trim leading zeros; a CASRN has 5 to 10 digits
  digits <- sub("^0+", "", gsub("[^0-9]", "", x))
  n <- nchar(digits)
  ok <- !is.na(x) & !nocas & n >= 5 & n <= 10

  cand <- paste(substr(digits, 1, n - 3), substr(digits, n - 2, n - 1), substr(digits, n, n), sep = "-")
  ok[ok] <- is_cas(cand[ok])
  out <- rep(NA_character_, length(x))
  out[ok] <- cand[ok]
  out
}
