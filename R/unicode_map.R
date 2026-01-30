# PURPOSE: Create a comprehensive dictionary of Unicode mappings for chemical names.
# Both uppercase and lowercase Greek letters are mapped to lowercase pseudo-delimited names (e.g., .alpha.).
# Scientific symbols and other non-ASCII characters are mapped to their ASCII equivalents.
# This script is part of the dev-unicode-cleaning branch.

# Greek Alphabet mapping (both cases -> lowercase)
greek_map <- c(
  # Lowercase
  "\u03b1" = ".alpha.", "\u03b2" = ".beta.", "\u03b3" = ".gamma.", "\u03b4" = ".delta.",
  "\u03b5" = ".epsilon.", "\u03b6" = ".zeta.", "\u03b7" = ".eta.", "\u03b8" = ".theta.",
  "\u03b9" = ".iota.", "\u03ba" = ".kappa.", "\u03bb" = ".lambda.", "\u03bc" = ".mu.",
  "\u03bd" = ".nu.", "\u03be" = ".xi.", "\u03bf" = ".omicron.", "\u03c0" = ".pi.",
  "\u03c1" = ".rho.", "\u03c2" = ".sigma.", "\u03c3" = ".sigma.", "\u03c4" = ".tau.",
  "\u03c5" = ".upsilon.", "\u03c6" = ".phi.", "\u03c7" = ".chi.", "\u03c8" = ".psi.",
  "\u03c9" = ".omega.",
  # Uppercase
  "\u0391" = ".alpha.", "\u0392" = ".beta.", "\u0393" = ".gamma.", "\u0394" = ".delta.",
  "\u0395" = ".epsilon.", "\u0396" = ".zeta.", "\u0397" = ".eta.", "\u0398" = ".theta.",
  "\u0399" = ".iota.", "\u039a" = ".kappa.", "\u039b" = ".lambda.", "\u039c" = ".mu.",
  "\u039d" = ".nu.", "\u039e" = ".xi.", "\u039f" = ".omicron.", "\u03a0" = ".pi.",
  "\u03a1" = ".rho.", "\u03a3" = ".sigma.", "\u03a4" = ".tau.", "\u03a5" = ".upsilon.",
  "\u03a6" = ".phi.", "\u03a7" = ".chi.", "\u03a8" = ".psi.", "\u03a9" = ".omega.",
  # Symbol variants
  "\u03d0" = ".beta.", "\u03d1" = ".theta.", "\u03d5" = ".phi.", "\u03d6" = ".pi.",
  "\u03f0" = ".kappa.", "\u03f1" = ".rho.", "\u03f5" = ".epsilon.",
  # Mathematical Greek (Mathematical Bold/Italic/etc often found in chemical names)
  # Examples from fix.replace.unicode.R
  "\u1D6C2" = ".alpha.", "\u1D6FC" = ".alpha.", "\u1D736" = ".alpha.", "\u1D770" = ".alpha.", "\u1D7AA" = ".alpha.",
  "\u1D6C3" = ".beta.", "\u1D6FD" = ".beta.", "\u1D737" = ".beta.", "\u1D771" = ".beta.", "\u1D7AB" = ".beta."
  # ... Add more if identified, but standard Greek covers 99%
)

# Mathematical and scientific symbols
math_map <- c(
  "\u00b1" = "+/-",
  "\u2265" = ">=",
  "\u2264" = "<=",
  "\u2260" = "!=",
  "\u2248" = "~",
  "\u221e" = "inf",
  "\u221a" = "sqrt",
  "\u00d7" = "*",
  "\u00b7" = "*",
  "\u2215" = "/",
  "\u00f7" = "/",
  "\u2212" = "-", # Minus sign
  "\u2013" = "-", # En dash
  "\u2014" = "-", # Em dash
  "\u2219" = "*",
  "\u2261" = "==",
  "\u220f" = "II",
  "\u222a" = "U",
  "\u2229" = "^"
)

# Subscripts and Superscripts (map to normal numbers)
script_map <- c(
  "\u00b9" = "1", "\u00b2" = "2", "\u00b3" = "3",
  "\u2070" = "0", "\u2074" = "4", "\u2075" = "5", "\u2076" = "6", "\u2077" = "7", "\u2078" = "8", "\u2079" = "9",
  "\u2080" = "0", "\u2081" = "1", "\u2082" = "2", "\u2083" = "3", "\u2084" = "4", "\u2085" = "5", "\u2086" = "6", "\u2087" = "7", "\u2088" = "8", "\u2089" = "9",
  "\u207b" = "-", "\u207a" = "+"
)

# Units and other symbols
misc_map <- c(
  "\u00b5" = "u", # Micro sign
  "\u03bc" = "u", # Small Greek Mu
  "\u00b0" = "",  # Degree sign (usually removed in chemical names)
  "\u2122" = "",  # TM
  "\u00ae" = "",  # Registered
  "\u00a9" = "",  # Copyright
  "\u2026" = "...",
  "\u2032" = "'", # Prime
  "\u00b4" = "'", # Acute accent
  "\u201c" = "\"", "\u201d" = "\"", # Smart quotes
  "\u2018" = "'", "\u2019" = "'",  # Smart single quotes
  "\u00a0" = " ",  # Non-breaking space
  "\u33c0" = "KO", "\u33c1" = "MO", # Square units
  "\u2192" = "->", # Right arrow
  "\u2191" = "^",  # Up arrow
  "\u00a7" = "S",  # Section
  "\u00b6" = "P",  # Paragraph
  "\u2020" = "|",  # Dagger
  "\u2021" = "|"   # Double dagger
)

# Latin characters with accents -> ASCII equivalents
latin_map <- c(
  "\u00fc" = "u", "\u00f9" = "u", "\u00fa" = "u", "\u00fb" = "u",
  "\u00e9" = "e", "\u00e8" = "e", "\u00eb" = "e", "\u00ea" = "e",
  "\u00e0" = "a", "\u00e1" = "a", "\u00e2" = "a", "\u00e3" = "a", "\u00e4" = "a", "\u00e5" = "a",
  "\u00f2" = "o", "\u00f3" = "o", "\u00f4" = "o", "\u00f5" = "o", "\u00f6" = "o", "\u00f8" = "o",
  "\u00ec" = "i", "\u00ed" = "i", "\u00ee" = "i", "\u00ef" = "i",
  "\u00f1" = "n",
  "\u00e7" = "c",
  "\u00df" = "ss",
  "\u00c6" = "AE", "\u00e6" = "ae"
)

# Combine all into one dictionary
unicode_map <- c(greek_map, math_map, script_map, misc_map, latin_map)

# Remove duplicates if any (by choosing the first occurrence)
unicode_map <- unicode_map[!duplicated(names(unicode_map))]

# Sort by name length descending to ensure longer sequences or specific characters are handled?
# Since these are single characters usually, order doesn't matter for fixed replacement 
# unless we have multi-char sequences. stringi::stri_replace_all_fixed handles this.

# Save as package data
usethis::use_data(unicode_map, overwrite = TRUE, internal = TRUE)
