# ==============================================================================
# Configuration & Global Helpers
# ==============================================================================

# These OpenAPI schema references indicate endpoints that accept full Chemical
# objects. Functions for these endpoints will first call chemi_resolver_lookup() to
# convert identifiers (DTXSID, CAS, SMILES, etc.) to complete Chemical objects.
CHEMICAL_SCHEMA_PATTERNS <- c(
  "#/components/schemas/Chemical",
  "#/components/schemas/ChemicalRecord",
  "#/components/schemas/ResolvedChemical",
  "#/components/schemas/DSSToxRecord",
  "#/components/schemas/DSSToxRecord2"
)

# Registry of known pagination patterns across all EPA APIs.
# Each entry describes how to detect pagination via route patterns or parameter names.
# Used by detect_pagination() in 04_openapi_parser.R.
PAGINATION_REGISTRY <- list(
  offset_limit_path = list(
    strategy = "offset_limit",
    route_pattern = "_pagination/\\{[^}]+\\}/\\{[^}]+\\}$",
    param_names = c("limit", "offset"),
    param_location = "path",
    description = "AMOS-style offset/limit via path parameters"
  ),
  cursor_path = list(
    strategy = "cursor",
    route_pattern = "_keyset_pagination/\\{[^}]+\\}$",
    param_names = c("limit", "cursor"),
    param_location = c("path", "query"),
    description = "AMOS-style keyset/cursor pagination"
  ),
  page_number_query = list(
    strategy = "page_number",
    route_pattern = NULL,
    param_names = c("pageNumber"),
    param_location = "query",
    description = "CTX hazard/exposure pageNumber query parameter"
  ),
  offset_size_body = list(
    strategy = "offset_limit",
    route_pattern = NULL,
    param_names = c("offset", "limit"),
    param_location = "body",
    description = "Chemi search offset+limit in request body"
  ),
  offset_size_query = list(
    strategy = "offset_limit",
    route_pattern = NULL,
    param_names = c("offset", "size"),
    param_location = "query",
    description = "Common Chemistry offset+size query parameters"
  ),
  page_size_query = list(
    strategy = "page_size",
    route_pattern = NULL,
    param_names = c("page", "size"),
    param_location = "query",
    description = "Chemi resolver classyfire page+size query parameters"
  ),
  page_items_query = list(
    strategy = "page_size",
    route_pattern = NULL,
    param_names = c("page", "itemsPerPage"),
    param_location = "query",
    description = "Chemi resolver pubchem page+itemsPerPage query parameters"
  )
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
ENDPOINT_PATTERNS_TO_EXCLUDE <- "render|replace|add|freeze|metadata|version|reports|download|export|protocols|preflight|universalpreflight|caspreflight|file"
