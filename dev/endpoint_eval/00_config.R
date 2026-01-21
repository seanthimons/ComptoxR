# ==============================================================================
# Configuration & Global Helpers
# ==============================================================================

# These OpenAPI schema references indicate endpoints that accept full Chemical
# objects. Functions for these endpoints will first call chemi_resolver() to
# convert identifiers (DTXSID, CAS, SMILES, etc.) to complete Chemical objects.
CHEMICAL_SCHEMA_PATTERNS <- c(
  "#/components/schemas/Chemical",
  "#/components/schemas/ChemicalRecord",
  "#/components/schemas/ResolvedChemical",
  "#/components/schemas/DSSToxRecord",
  "#/components/schemas/DSSToxRecord2"
)

# Helper: NULL-coalesce
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  if (length(x) == 1 && is.na(x)) return(y)
  x
}

# Helper: ensure columns exist in data frame
ensure_cols <- function(df, cols_with_defaults) {
  nr <- nrow(df)
  for (col in names(cols_with_defaults)) {
    if (!(col %in% names(df))) {
      val <- cols_with_defaults[[col]]
      if (is.list(val) && length(val) == 1) {
        # Handle list-column defaults
        df[[col]] <- replicate(nr, val[[1]], simplify = FALSE)
      } else {
        df[[col]] <- rep(val, length.out = nr)
      }
    }
  }
  df
}

# Endpoint exclusion patterns - these endpoints are removed during preprocessing
ENDPOINT_PATTERNS_TO_EXCLUDE <- "render|replace|add|freeze|metadata|version|reports|download|export|protocols"
