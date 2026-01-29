# ==============================================================================
# OpenAPI Parsing
# ==============================================================================

# ------------------------------------------------------------------------------
# Helpers (Extracted from openapi_to_spec)
# ------------------------------------------------------------------------------

sanitize_name <- function(x) {
  x <- stringr::str_replace_all(x, "[^A-Za-z0-9_]", "_")
  x <- stringr::str_replace_all(x, "_+", "_")
  x <- stringr::str_trim(x)
  x
}

method_path_name <- function(route, method) {
  p <- gsub("^/|/$", "", route)
  p <- gsub("\\{([^}]+)\\}", "by_\\1", p)
  p <- gsub("[^A-Za-z0-9]+", "_", p)
  p <- gsub("_+", "_", p)
  tolower(paste0(method, "_", p))
}

dedup_params <- function(params) {
  if (!length(params)) return(list())
  keys <- purrr::map_chr(params, ~ paste(.x[["name"]] %||% "", .x[["in"]] %||% "", sep = "@"))
  params[!duplicated(keys)]
}

param_names <- function(params, where, exclude_pattern = "^files\\[\\]$") {
  purrr::map_chr(
    purrr::keep(params, ~ identical(.x[["in"]], where) &&
                          !grepl(exclude_pattern, .x[["name"]] %||% "")),
    ~ .x[["name"]] %||% ""
  ) -> nm
  nm[nzchar(nm)]
}

# Extract parameter metadata (examples, descriptions, defaults, enums, types, required status)
param_metadata <- function(params, where, exclude_pattern = "^files\\[\\]$") {
  relevant_params <- purrr::keep(params, ~ identical(.x[["in"]], where) &&
                                            !grepl(exclude_pattern, .x[["name"]] %||% ""))
  if (length(relevant_params) == 0) return(list())

  metadata <- purrr::map(relevant_params, function(p) {
    schema <- p[["schema"]] %||% list()

    list(
      name = p[["name"]] %||% "",
      example = p[["example"]] %||% schema[["default"]] %||% NA,  # Fallback to default
      description = p[["description"]] %||% schema[["description"]] %||% "",  # Check schema too
      default = schema[["default"]] %||% NA,  # Explicit default field
      enum = schema[["enum"]] %||% NULL,  # Allowed values
      type = schema[["type"]] %||% NA,  # Data type
      required = p[["required"]] %||% FALSE  # Required status
    )
  })

  # Filter out params with no name
  metadata <- purrr::keep(metadata, ~ nzchar(.x$name))

  # Convert to named list for easier lookup
  names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
  metadata
}

# Check if a request body uses the Chemical schema pattern
# Returns TRUE if the request body contains Chemical objects that should be resolved first
uses_chemical_schema <- function(request_body, openapi_spec) {
  if (is.null(request_body) || !is.list(request_body)) return(FALSE)

  # Navigate: requestBody -> content -> application/json -> schema -> $ref
  content <- request_body[["content"]] %||% list()
  json_schema <- content[["application/json"]][["schema"]] %||% list()

  # Get the schema reference
  ref <- json_schema[["$ref"]]
  if (is.null(ref) || !nzchar(ref)) return(FALSE)

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

  if (is.null(schema_def) || !is.list(schema_def)) return(FALSE)

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
get_body_schema_type <- function(request_body, openapi_spec) {
  if (is.null(request_body) || !is.list(request_body)) return("unknown")

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
  if (is.null(ref) || !nzchar(ref)) return("unknown")

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

  if (is.null(schema_def) || !is.list(schema_def)) return("unknown")

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

# Determine the response schema type for code generation
# Returns: "array", "object", "scalar", "binary", or "unknown"
get_response_schema_type <- function(responses, openapi_spec) {
  if (is.null(responses) || !is.list(responses)) return("unknown")
  
  # Look for successful response codes
  success_codes <- intersect(names(responses), c("200", "201", "202", "204", "default"))
  if (length(success_codes) == 0) return("unknown")
  
  # Check first successful response
  resp <- responses[[success_codes[1]]]
  content <- resp$content %||% list()
  
  # Check for binary/image content types first
  if (any(grepl("^image/", names(content))) || any(grepl("octet-stream", names(content)))) {
    return("binary")
  }
  
  # Check application/json response
  json_schema <- content[["application/json"]]$schema %||% list()
  
  # If no JSON schema, return unknown
  if (length(json_schema) == 0) return("unknown")
  
  # Check for $ref - need to resolve it
  if (!is.null(json_schema[["$ref"]])) {
    ref <- json_schema[["$ref"]]
    ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
    if (length(ref_parts) >= 4 && ref_parts[2] == "components" && ref_parts[3] == "schemas") {
      schema_name <- ref_parts[4]
      components <- openapi_spec[["components"]] %||% list()
      schemas <- components[["schemas"]] %||% list()
      json_schema <- schemas[[schema_name]] %||% list()
    }
  }
  
  # Determine type from schema
  schema_type <- json_schema[["type"]] %||% ""
  
  if (schema_type == "array") return("array")
  if (schema_type == "object") return("object")
  if (schema_type %in% c("string", "number", "integer", "boolean")) return("scalar")
  
  # Default to unknown
  return("unknown")
}

# Extract metadata from request body schema reference
# Parses POST endpoint request bodies that reference schemas in #/components/schemas
extract_body_schema_metadata <- function(request_body, openapi_spec) {
  if (is.null(request_body) || !is.list(request_body)) return(list())

  # Navigate: requestBody -> content -> application/json -> schema -> $ref
  content <- request_body[["content"]] %||% list()
  json_schema <- content[["application/json"]][["schema"]] %||% list()

  # Check if this is a schema reference
  ref <- json_schema[["$ref"]]
  if (is.null(ref) || !nzchar(ref)) return(list())

  # Parse the reference (e.g., "#/components/schemas/LookupRequest")
  # Format: #/components/schemas/{SchemaName}
  ref_parts <- strsplit(ref, "/", fixed = TRUE)[[1]]
  if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
    return(list())
  }

  schema_name <- ref_parts[4]

  # Resolve the schema from components
  components <- openapi_spec[["components"]] %||% list()
  schemas <- components[["schemas"]] %||% list()
  schema_def <- schemas[[schema_name]]

  if (is.null(schema_def) || !is.list(schema_def)) return(list())

  # Extract properties
  properties <- schema_def[["properties"]] %||% list()
  required_fields <- schema_def[["required"]] %||% character(0)

  # Build metadata for each property
  metadata <- purrr::imap(properties, function(prop, prop_name) {
    list(
      name = prop_name,
      description = prop[["description"]] %||% "",
      type = prop[["type"]] %||% NA,
      enum = prop[["enum"]] %||% NULL,
      default = prop[["default"]] %||% NA,
      required = prop_name %in% required_fields,
      example = prop[["example"]] %||% prop[["default"]] %||% NA
    )
  })

  # Filter and return as named list
  metadata <- purrr::keep(metadata, ~ nzchar(.x$name))
  names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
  metadata
}

order_path_by_route <- function(path_names, route) {
  if (!length(path_names)) return(character(0))
  m <- stringr::str_match_all(route, "\\{([^}]+)\\}")
  if (length(m) >= 1 && length(m[[1]]) && nrow(m[[1]]) > 0) {
    in_route <- m[[1]][, 2]
    unique(c(in_route[in_route %in% path_names], setdiff(path_names, in_route)))
  } else {
    unique(path_names)
  }
}

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
openapi_to_spec <- function(
  openapi,
  default_base_url = NULL,
  name_strategy = c("operationId", "method_path"),
  preprocess = TRUE
) {
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")
  if (!requireNamespace("tibble", quietly = TRUE)) stop("Package 'tibble' is required.")
  if (!requireNamespace("stringr", quietly = TRUE)) stop("Package 'stringr' is required.")

  name_strategy <- match.arg(name_strategy)
  
  # Preprocess schema if requested
  if (preprocess && is.character(openapi) && file.exists(openapi)) {
    openapi <- preprocess_schema(openapi)
  }

  # Detect schema version (Swagger 2.0 vs OpenAPI 3.0)
  schema_version <- detect_schema_version(openapi)
  cli::cli_alert_info("Detected schema version: {schema_version$type} {schema_version$version}")

  # Get schema definitions/components based on version
  # Swagger 2.0 uses "definitions", OpenAPI 3.0 uses "components/schemas"
  if (identical(schema_version$type, "swagger")) {
    definitions <- openapi[["definitions"]] %||% list()
    # For Swagger 2.0, we'll pass definitions to body extraction
    components <- list(schemas = definitions)  # Normalize for resolve_schema_ref compatibility
  } else {
    definitions <- NULL
    components <- openapi[["components"]] %||% list()
  }

  base_url <- default_base_url %||% {
    srv <- openapi$servers
    if (is.list(srv) && length(srv) && !is.null(srv[[1]]$url)) srv[[1]]$url else "https://example.com"
  }

  paths <- openapi$paths
  if (!is.list(paths) || !length(paths)) stop("OpenAPI object has no 'paths'.")

  purrr::imap_dfr(paths, function(path_item, route) {
    path_level_params <- path_item$parameters %||% list()
    meths <- intersect(names(path_item), c("get", "post", "put", "patch", "delete", "head", "options", "trace"))

    purrr::map_dfr(meths, function(method) {
      op <- path_item[[method]]
      op_params <- op$parameters %||% list()
      parameters <- dedup_params(c(path_level_params, op_params))

      path_names  <- order_path_by_route(param_names(parameters, "path"), route)
      
      # Extract query parameters with $ref resolution
      components <- openapi[["components"]] %||% list()
      query_result <- extract_query_params_with_refs(parameters, components)
      query_names <- query_result$names  # Use resolved/flattened parameter names
      query_meta <- query_result$metadata  # Use enhanced metadata from resolved schemas
      
      # Extract parameter metadata (examples and descriptions)
      path_meta  <- param_metadata(parameters, "path")

      # Extract request body schema metadata for POST/PUT/PATCH
      body_props <- if (method %in% c("post", "put", "patch")) {
        if (identical(schema_version$type, "swagger")) {
          # Swagger 2.0: body is in parameters array, resolve against definitions
          extract_body_properties(op$parameters, definitions, schema_version = schema_version)
        } else {
          # OpenAPI 3.0: body is in requestBody object
          extract_body_properties(op$requestBody, components)
        }
      } else {
        list(type = "unknown", properties = list())
      }

      # Extract body parameter names (ordered by required first, then alphabetically)
      body_names <- if (body_props$type == "object" && length(body_props$properties) > 0) {
        required_names <- names(purrr::keep(body_props$properties, ~ .x$required))
        optional_names <- names(purrr::keep(body_props$properties, ~ !.x$required))
        c(required_names, optional_names)
      } else if (body_props$type %in% c("array", "object_array") && !is.null(body_props$item_schema)) {
        # For array bodies with object items (ref or inline), extract object properties
        item_properties <- body_props$item_schema$properties
        if (length(item_properties) > 0) {
          required_names <- names(purrr::keep(item_properties, ~ .x$required))
          optional_names <- names(purrr::keep(item_properties, ~ !.x$required))
          c(required_names, optional_names)
        } else {
          character(0)
        }
      } else if (body_props$type %in% c("string", "string_array") && length(body_props$properties) > 0) {
        # Simple body types (string or string_array) - extract synthetic parameter names
        names(body_props$properties)
      } else {
        character(0)
      }

      # Create simplified body_meta for backward compatibility
      body_meta <- if (length(body_names) > 0) {
        purrr::map(body_names, function(name) {
          if (body_props$type == "object") {
            body_props$properties[[name]]
          } else if (body_props$type %in% c("array", "object_array") && !is.null(body_props$item_schema)) {
            body_props$item_schema$properties[[name]]
          } else if (body_props$type %in% c("string", "string_array")) {
            # Simple body types - use the synthetic parameter metadata
            body_props$properties[[name]]
          } else {
            list(name = name, type = NA, description = "", enum = NULL, default = NA, required = FALSE, example = NA)
          }
        })
      } else {
        list()
      }
      names(body_meta) <- body_names


      # Combine all parameters (path parameters first, then query parameters)
      combined <- c(path_names, query_names)

      # Detect if endpoint has request body
      has_body <- if (identical(schema_version$type, "swagger")) {
        # Swagger 2.0: check for body parameter in parameters array
        any(purrr::map_lgl(op$parameters %||% list(), ~ identical(.x[["in"]], "body")))
      } else {
        # OpenAPI 3.0: check for requestBody object
        !is.null(op$requestBody)
      }
      operationId <- op$operationId %||% paste(method, route)
      summary <- op$summary %||% ""
      
      # Extract deprecated status
      deprecated <- op$deprecated %||% FALSE
      
      # Extract description for enhanced documentation
      description <- op$description %||% ""

      # Detect if the request body uses the Chemical schema (needs resolver)
      needs_resolver <- if (method %in% c("post", "put", "patch") && has_body) {
        if (identical(schema_version$type, "swagger")) {
          # Swagger 2.0: check body parameter schema for Chemical patterns
          # For now, return FALSE - chemi schemas don't use Chemical resolver pattern
          FALSE
        } else {
          uses_chemical_schema(op$requestBody, openapi)
        }
      } else {
        FALSE
      }

      # Get body schema type for more specific code generation
      body_schema_type <- if (method %in% c("post", "put", "patch") && has_body) {
        if (identical(schema_version$type, "swagger")) {
          # Use the type from body_props which was already extracted
          body_props$type %||% "unknown"
        } else {
          get_body_schema_type(op$requestBody, openapi)
        }
      } else {
        "unknown"
      }
      
      # Detect response schema type for enhanced documentation
      response_schema_type <- get_response_schema_type(op$responses, openapi)

      # Extract response content types
      response_content_types <- character(0)
      if (!is.null(op$responses)) {
        # Look for successful responses (200, 201, etc.)
        success_codes <- intersect(names(op$responses), c("200", "201", "202", "204", "default"))
        for (code in success_codes) {
          resp <- op$responses[[code]]
          if (!is.null(resp$content) && is.list(resp$content)) {
            response_content_types <- c(response_content_types, names(resp$content))
          }
        }
      }
      response_content_types <- unique(response_content_types)
      content_type <- if (length(response_content_types) > 0) {
        paste(response_content_types, collapse = ", ")
      } else {
        ""
      }

      fn <- if (name_strategy == "operationId") sanitize_name(operationId) else sanitize_name(method_path_name(route, method))

      tibble::tibble(
        route = route,
        method = toupper(method),
        summary = summary,
        has_body = has_body,
        params = if (length(combined) > 0) paste(combined, collapse = ",") else "",
        # Separate path and query parameters for flexible stub generation
        path_params = if (length(path_names) > 0) paste(path_names, collapse = ",") else "",
        query_params = if (length(query_names) > 0) paste(query_names, collapse = ",") else "",
        body_params = if (length(body_names) > 0) paste(body_names, collapse = ",") else "",
        num_path_params = length(path_names),
        num_body_params = length(body_names),
        # Parameter metadata with examples and descriptions
        path_param_metadata = list(path_meta),
        query_param_metadata = list(query_meta),
        body_param_metadata = list(body_meta),
        # Response content type(s)
        content_type = content_type,
        # Chemical schema detection for resolver wrapping
        needs_resolver = needs_resolver,
        body_schema_type = body_schema_type,
        # Deprecated status and description
        deprecated = deprecated,
        description = description,
        # Response schema type for enhanced documentation
        response_schema_type = response_schema_type,
        # NEW: Schema type classification
        # - "json": POST/PUT/PATCH with request body
        # - "path": GET with path parameters (appends to URL)
        # - "query_only": GET without path parameters (static endpoint, params via query string)
        # NOTE: method is already uppercased at this point, so compare with uppercase
        request_type = if (toupper(method) %in% c("POST", "PUT", "PATCH") && has_body) {
          "json"
        } else if (length(path_names) > 0) {
          "path"
        } else {
          "query_only"
        },
        # NEW: Body schema full information
        body_schema_full = list(body_props),
        # NEW: Body item type for array schemas
        body_item_type = if (!is.null(body_props$item_type)) {
          body_props$item_type
        } else if (!is.null(body_props$item_schema)) {
          body_props$item_schema$ref_type
        } else {
          NA
        }
      )
    })
  })
}

#' Parse and merge chemi schema files into a unified super schema
#'
#' Reads all chemi-*.json schema files from the specified directory, selects the
#' best available version for each endpoint domain (prioritizing prod > staging > dev),
#' parses each selected schema using `openapi_to_spec()`, and merges them into a
#' single tibble.
#'
#' @param schema_dir Path to the directory containing schema files. Defaults to
#'   the 'schema' directory at the project root (using `here::here('schema')`).
#' @param pattern Regex pattern for matching schema files. Defaults to "^chemi-.*\\.json$".
#' @param exclude_pattern Regex pattern for excluding schema files (e.g., UI schemas).
#'   Defaults to "ui" (case-insensitive).
#' @param stage_order Character vector specifying the priority order for stages.
#'   Defaults to c("prod", "staging", "dev").
#' @return A tibble containing all parsed endpoint specifications from the selected
#'   schema files, with columns from `openapi_to_spec()` plus a `source_file` column
#'   indicating which schema file each row came from.
#'
#' @details
#' The function works by:
#' 1. Listing all files matching the pattern in the schema directory
#' 2. Filtering out files matching the exclude pattern
#' 3. Parsing filenames to extract origin, domain, and stage
#' 4. For each domain, selecting the first available stage based on stage_order
#' 5. Parsing each selected schema file with `openapi_to_spec()`
#' 6. Combining all parsed schemas into a single tibble
#'
#' @examples
#' \dontrun{
#' # Parse all chemi schemas using defaults
#' super_schema <- parse_chemi_schemas()
#'
#' # Parse with custom schema directory
#' super_schema <- parse_chemi_schemas(schema_dir = "my/schema/path")
#'
#' # View domains represented in the super schema
#' table(super_schema$source_file)
#' }
#' @export
parse_chemi_schemas <- function(
  schema_dir = NULL,
  pattern = "^chemi-.*\\.json$",
  exclude_pattern = "ui",
  stage_order = c("prod", "staging", "dev")
) {
  if (!requireNamespace("here", quietly = TRUE)) stop("Package 'here' is required.")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Package 'jsonlite' is required.")
  if (!requireNamespace("purrr", quietly = TRUE)) stop("Package 'purrr' is required.")
  if (!requireNamespace("dplyr", quietly = TRUE)) stop("Package 'dplyr' is required.")
  if (!requireNamespace("tidyr", quietly = TRUE)) stop("Package 'tidyr' is required.")
  if (!requireNamespace("stringr", quietly = TRUE)) stop("Package 'stringr' is required.")
  if (!requireNamespace("tibble", quietly = TRUE)) stop("Package 'tibble' is required.")

  # Default to here::here('schema') if not specified
  if (is.null(schema_dir)) {
    schema_dir <- here::here("schema")
  }

  # Verify schema directory exists
  if (!dir.exists(schema_dir)) {
    stop("Schema directory does not exist: ", schema_dir)
  }

  # List all matching schema files
  all_files <- list.files(
    path = schema_dir,
    pattern = pattern,
    full.names = FALSE
  )

  if (length(all_files) == 0) {
    warning("No schema files found matching pattern '", pattern, "' in ", schema_dir)
    return(tibble::tibble())
  }

  # Filter out excluded files (e.g., UI schemas)
  if (!is.null(exclude_pattern) && nzchar(exclude_pattern)) {
    files_filtered <- all_files[!grepl(exclude_pattern, all_files, ignore.case = TRUE)]
  } else {
    files_filtered <- all_files
  }

  if (length(files_filtered) == 0) {
    warning("All schema files were excluded by pattern '", exclude_pattern, "'")
    return(tibble::tibble())
  }

  # Parse filenames to extract origin, domain, and stage
  # Expected format: chemi-{domain}-{stage}.json
  schema_meta <- tibble::tibble(file = files_filtered) %>%
    tidyr::separate_wider_delim(
      cols = file,
      delim = "-",
      names = c("origin", "domain", "stage"),
      cols_remove = FALSE
    ) %>%
    dplyr::mutate(
      # Remove .json extension from stage
      stage = stringr::str_remove(stage, pattern = "\\.json$"),
      # Convert stage to factor with specified priority order
      stage = factor(stage, levels = stage_order)
    )

  # For each domain, select the best available stage (first in order)
  selected_files <- schema_meta %>%
    dplyr::group_by(domain) %>%
    dplyr::arrange(stage, .by_group = TRUE) %>%
    dplyr::slice(1) %>%
    dplyr::ungroup() %>%
    dplyr::pull(file)

  if (length(selected_files) == 0) {
    warning("No schema files selected after filtering by stage")
    return(tibble::tibble())
  }

  # Parse each selected schema file and combine
  super_schema <- purrr::map(
    selected_files,
    function(schema_file) {
      schema_path <- file.path(schema_dir, schema_file)
      openapi <- jsonlite::fromJSON(schema_path, simplifyVector = FALSE)
      spec <- openapi_to_spec(openapi)
      # Add source file column for traceability
      spec$source_file <- schema_file
      spec
    }
  ) %>%
    purrr::list_rbind()

  super_schema
}
