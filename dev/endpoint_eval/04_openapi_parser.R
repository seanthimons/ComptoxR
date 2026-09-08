wrapmaint::bind_tools("parser", environment())
supported_methods <- c("get", "post")
body_requires_resolution <- function(...) uses_chemical_schema(...)
# ==============================================================================
# OpenAPI Parsing
# ==============================================================================

# ------------------------------------------------------------------------------
# Helpers (Extracted from openapi_to_spec)
# ------------------------------------------------------------------------------

# Extract parameter metadata (examples, descriptions, defaults, enums, types, required status)

# Check if a request body uses the Chemical schema pattern
# Returns TRUE if the request body contains Chemical objects that should be resolved first
uses_chemical_schema <- function(request_body, openapi_spec) {
  if (is.null(request_body) || !is.list(request_body)) {
    return(FALSE)
  }

  # Navigate: requestBody -> content -> application/json -> schema -> $ref
  content <- request_body[["content"]] %||% list()
  json_schema <- content[["application/json"]][["schema"]] %||% list()

  # Get the schema reference
  ref <- json_schema[["$ref"]]
  if (is.null(ref) || !nzchar(ref)) {
    return(FALSE)
  }

  # Parse the reference
  ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
  if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
    return(FALSE)
  }

  schema_name <- ref_parts[4]

  # Resolve the schema from components
  components <- openapi_spec[["components"]] %||% list()
  schemas <- components[["schemas"]] %||% list()
  schema_def <- schemas[[schema_name]]

  if (is.null(schema_def) || !is.list(schema_def)) {
    return(FALSE)
  }

  # Check if the schema has a 'chemicals' property that references Chemical, ChemicalRecord, or ResolvedChemical
  properties <- schema_def[["properties"]] %||% list()

  # Check 'chemicals' property specifically
  chemicals_prop <- properties[["chemicals"]]
  if (!is.null(chemicals_prop)) {
    # Check if it's an array of Chemical-like objects
    items <- chemicals_prop[["items"]] %||% list()
    item_ref <- items[["$ref"]] %||% ""

    # Check if the array items reference a Chemical-like schema
    # Uses the CHEMICAL_SCHEMA_PATTERNS constant defined at module level
    if (any(item_ref %in% CHEMICAL_SCHEMA_PATTERNS)) {
      return(TRUE)
    }
  }

  # Also check for 'main', 'selectedForSimilarity' or other single Chemical references
  for (prop_name in c("main", "selectedForSimilarity", "chemical")) {
    prop <- properties[[prop_name]]
    if (!is.null(prop)) {
      prop_ref <- prop[["$ref"]] %||% ""
      if (grepl("#/components/schemas/Chemical", prop_ref, fixed = TRUE)) {
        return(TRUE)
      }
    }
  }

  return(FALSE)
}

# Determine the body schema type for code generation
# Returns: "chemical_array" (needs resolver), "string_array" (SMILES), "object_array" (inline objects), "string", "simple_object", or "unknown"

# Determine the response schema type for code generation
# Returns: "array", "object", "scalar", "binary", or "unknown"

# Extract metadata from request body schema reference
# Parses POST endpoint request bodies that reference schemas in #/components/schemas

# Detect pagination strategy for an endpoint based on route pattern and parameter names
#
# Iterates through PAGINATION_REGISTRY entries (most specific first) to classify
# how an endpoint paginates. Returns strategy metadata for the spec tibble.
#
# @param route Character; the endpoint route path (e.g., "/api/amos/method_pagination/{limit}/{offset}")
# @param path_params Character; comma-separated path parameter names
# @param query_params Character; comma-separated query parameter names
# @param body_params Character; comma-separated body parameter names
# @param registry List; pagination registry (default: PAGINATION_REGISTRY from 00_config.R)
# @return A list with strategy, registry_key, params, param_location, description

# ------------------------------------------------------------------------------
# Main Parsing Functions
# ------------------------------------------------------------------------------

#' Convert an OpenAPI specification to a tidy data.frame of endpoint specs
#'
#' Parses the OpenAPI JSON object and extracts routes, HTTP methods, and parameter information.
#' @param openapi List parsed from an OpenAPI JSON file (as produced by `jsonlite::fromJSON`).
#' @param default_base_url Optional base URL to use if the OpenAPI document does not specify one.
#' @param name_strategy Strategy for naming generated functions: "operationId" (uses the operationId field) or "method_path" (constructs a name from HTTP method and path).
#' @return A tibble with columns: route, method, summary, has_body, params (list of parameter names).
#' @export
get_body_schema_type <- function(request_body, openapi_spec) {
  if (is.null(request_body) || !is.list(request_body)) {
    return("unknown")
  }

  # Navigate: requestBody -> content -> application/json -> schema
  content <- request_body[["content"]] %||% list()
  json_schema <- content[["application/json"]][["schema"]] %||% list()

  # Check for inline schema (no $ref)
  schema_type <- json_schema[["type"]]
  if (!is.null(schema_type) && nzchar(schema_type)) {
    # Inline schema with direct type
    if (schema_type == "string") {
      return("string")
    } else if (schema_type == "array") {
      # Check array item type
      items <- json_schema[["items"]] %||% list()
      item_type <- items[["type"]] %||% ""
      if (item_type == "string") {
        return("string_array")
      } else if (item_type == "object" && !is.null(items[["properties"]])) {
        # Inline object array (e.g., ncc-cats endpoint)
        return("object_array")
      }
    } else if (schema_type == "object") {
      return("simple_object")
    }
    return("unknown")
  }

  # Get the schema reference
  ref <- json_schema[["$ref"]]
  if (is.null(ref) || !nzchar(ref)) {
    return("unknown")
  }

  # Parse the reference
  ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
  if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
    return("unknown")
  }

  schema_name <- ref_parts[4]

  # Resolve the schema from components
  components <- openapi_spec[["components"]] %||% list()
  schemas <- components[["schemas"]] %||% list()
  schema_def <- schemas[[schema_name]]

  if (is.null(schema_def) || !is.list(schema_def)) {
    return("unknown")
  }

  # Check 'chemicals' property
  properties <- schema_def[["properties"]] %||% list()
  chemicals_prop <- properties[["chemicals"]]

  if (!is.null(chemicals_prop)) {
    items <- chemicals_prop[["items"]] %||% list()
    item_ref <- items[["$ref"]] %||% ""
    item_type <- items[["type"]] %||% ""

    # Check if the array items reference a Chemical-like schema
    # Uses the CHEMICAL_SCHEMA_PATTERNS constant defined at module level
    if (any(item_ref %in% CHEMICAL_SCHEMA_PATTERNS)) {
      return("chemical_array")
    }

    # String array (SMILES) - doesn't need resolver
    if (item_type == "string") {
      return("string_array")
    }
  }

  return("simple_object")
}
