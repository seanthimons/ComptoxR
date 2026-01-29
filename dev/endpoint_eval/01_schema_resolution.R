# ==============================================================================
# Schema Preprocessing & Resolution
# ==============================================================================

# Track circular references during resolution
resolve_stack <- new.env(hash = TRUE)

# Extract all schema references from paths
extract_referenced_schemas <- function(paths) {
  refs <- character(0)
  
  for (route in names(paths)) {
    path_item <- paths[[route]]
    
    for (method in intersect(names(path_item), c("get", "post", "put", "patch", "delete", "head", "options", "trace"))) {
      op <- path_item[[method]]
      
      # Extract from requestBody
      if (!is.null(op$requestBody) && is.list(op$requestBody)) {
        content <- op$requestBody[["content"]] %||% list()
        json_schema <- content[["application/json"]][["schema"]] %||% list()
        if (!is.null(json_schema[["$ref"]])) {
          ref <- json_schema[["$ref"]]
          schema_name <- stringr::str_replace(ref, "#/components/schemas/", "")
          refs <- c(refs, schema_name)
        }
      }
    }
  }
  
  unique(refs)
}

# Filter components to keep only referenced schemas
filter_components_by_refs <- function(components, refs) {
  schemas <- components[["schemas"]] %||% list()
  
  # Keep only schemas that match refs
  keep_schemas <- intersect(names(schemas), refs)
  
  # Update components
  components$schemas <- schemas[keep_schemas]
  components
}

# Preprocess OpenAPI schema
preprocess_schema <- function(schema_file, exclude_endpoints = ENDPOINT_PATTERNS_TO_EXCLUDE) {
  # Load schema
  openapi <- jsonlite::fromJSON(schema_file, simplifyVector = FALSE)
  
  # Filter out unwanted endpoints
  paths <- openapi$paths
  if (!is.null(paths) && length(paths) > 0) {
    keep_paths <- names(paths)[!stringr::str_detect(names(paths), exclude_endpoints)]
    openapi$paths <- paths[keep_paths]
  }
  
  # Extract all referenced schemas
  refs <- extract_referenced_schemas(openapi$paths)
  
  # Filter components to keep only referenced schemas
  components <- openapi[["components"]] %||% list()
  if (length(components) > 0) {
    openapi$components <- filter_components_by_refs(components, refs)
  }
  
  openapi
}

# Resolve schema reference to actual schema definition
resolve_schema_ref <- function(schema_ref, components, max_depth = 5, depth = 0) {
  # Check depth limit
  if (depth > max_depth) {
    stop("Schema reference depth exceeded max_depth = ", max_depth, ". Possible circular reference or overly complex schema.")
  }
  
  # Handle circular reference detection
  ref_key <- if (is.character(schema_ref)) schema_ref else "inline"
  if (exists(ref_key, envir = resolve_stack)) {
    stop("Circular reference detected for schema: ", ref_key)
  }
  
  # If schema_ref is actual schema (not a reference), just return it
  if (!is.character(schema_ref)) {
    return(schema_ref)
  }
  
  # Parse reference
  ref_parts <- strsplit(schema_ref, "/", fixed = TRUE)[[1]]
  if (length(ref_parts) < 4 || ref_parts[2] != "components" || ref_parts[3] != "schemas") {
    return(list(type = "unknown"))
  }
  
  schema_name <- ref_parts[4]
  
  # Sanitize ref_key for use as variable name in R environment
  # Replace problematic characters with underscores
  sanitized_key <- gsub("[^a-zA-Z0-9]", "_", ref_key)
  
  # Check for circular reference - only error if we're going DEEPER
  # (same reference at same depth is OK - just multiple references)
  if (exists(sanitized_key, envir = resolve_stack)) {
    existing_depth <- get(sanitized_key, envir = resolve_stack)
    if (depth > existing_depth) {
      stop("Circular reference detected for schema: ", ref_key, ". Current depth: ", depth, ", Previous depth: ", existing_depth)
    }
  }
  
  # Track reference for cleanup on exit (overwrite with new depth if exists)
  assign(sanitized_key, depth, envir = resolve_stack)
  on.exit({
    if (exists(sanitized_key, envir = resolve_stack)) {
      rm(sanitized_key, envir = resolve_stack)
    }
  }, add = TRUE)
   
  # Look up schema
  schemas <- components[["schemas"]] %||% list()
  schema_def <- schemas[[schema_name]]
  
  if (is.null(schema_def) || !is.list(schema_def)) {
    return(list(type = "unknown"))
  }
  
  # Handle schema composition (allOf, oneOf, anyOf)
  if (!is.null(schema_def[["allOf"]])) {
    return(resolve_schema_ref(schema_def[["allOf"]][[1]], components, max_depth, depth + 1))
  }
  
  # Return resolved schema
  schema_def
}

# Detect OpenAPI/Swagger version from schema root
# Returns list with: version (string), type ("swagger"|"openapi"|"unknown")
detect_schema_version <- function(schema) {
  # Check swagger field first (Swagger 2.0)
  if (!is.null(schema$swagger) && grepl("^2\\.", as.character(schema$swagger))) {
    return(list(version = as.character(schema$swagger), type = "swagger"))
  }
  # Check openapi field (OpenAPI 3.x)
  if (!is.null(schema$openapi) && grepl("^3\\.", as.character(schema$openapi))) {
    return(list(version = as.character(schema$openapi), type = "openapi"))
  }
  # Unknown version
  return(list(version = "unknown", type = "unknown"))
}

# Extract body schema from Swagger 2.0 parameters array
# Swagger 2.0 uses parameters[].in="body" with schema property
# Returns: list with type, properties (matching extract_body_properties output format)
extract_swagger2_body_schema <- function(parameters, definitions) {
  if (is.null(parameters) || !is.list(parameters) || length(parameters) == 0) {
    return(list(type = "unknown", properties = list()))
  }

  # Find body parameters (in="body")
  body_params <- purrr::keep(parameters, ~ identical(.x[["in"]], "body"))

  # Find formData parameters for mutual exclusivity check
  formData_params <- purrr::keep(parameters, ~ identical(.x[["in"]], "formData"))

  # BODY-06: Validate body/formData mutual exclusivity
  if (length(body_params) > 0 && length(formData_params) > 0) {
    cli::cli_alert_warning("Swagger 2.0 spec violation: both body and formData parameters present. Using body parameter.")
  }

  # BODY-05: Validate single body parameter constraint
  if (length(body_params) > 1) {
    cli::cli_alert_warning("Swagger 2.0 spec violation: multiple body parameters found ({length(body_params)}). Using first body parameter.")
  }

  if (length(body_params) == 0) {
    return(list(type = "unknown", properties = list()))
  }

  # Use first body parameter
  body_param <- body_params[[1]]
  body_schema <- body_param[["schema"]] %||% list()

  if (length(body_schema) == 0) {
    return(list(type = "unknown", properties = list()))
  }

  # Check for $ref to #/definitions/
  if (!is.null(body_schema[["$ref"]])) {
    ref <- body_schema[["$ref"]]
    # BODY-03: Resolve $ref to #/definitions/{SchemaName}
    resolved <- resolve_swagger2_definition_ref(ref, definitions)
    if (!is.null(resolved)) {
      body_schema <- resolved
    }
  }

  # Now extract properties from resolved schema (same logic as OpenAPI 3.0)
  schema_type <- body_schema[["type"]] %||% NA

  # BODY-04: Handle object schemas with properties
  # In Swagger 2.0, schemas with properties often omit the explicit type="object"
  has_properties <- !is.null(body_schema[["properties"]]) && length(body_schema[["properties"]]) > 0
  is_object <- (!is.na(schema_type) && schema_type == "object") || (is.na(schema_type) && has_properties)

  if (is_object && has_properties) {
    required_fields <- body_schema[["required"]] %||% character(0)
    metadata <- purrr::imap(body_schema[["properties"]], function(prop, prop_name) {
      list(
        name = prop_name,
        type = prop[["type"]] %||% NA,
        format = prop[["format"]] %||% NA,
        description = prop[["description"]] %||% "",
        enum = prop[["enum"]] %||% NULL,
        default = prop[["default"]] %||% NA,
        required = prop_name %in% required_fields,
        example = prop[["example"]] %||% prop[["default"]] %||% NA
      )
    })
    names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
    return(list(type = "object", properties = metadata))
  }

  # Handle array type
  if (!is.na(schema_type) && schema_type == "array" && !is.null(body_schema[["items"]])) {
    items <- body_schema[["items"]]

    # Resolve items $ref if present
    if (!is.null(items[["$ref"]])) {
      resolved_items <- resolve_swagger2_definition_ref(items[["$ref"]], definitions)
      if (!is.null(resolved_items) && !is.null(resolved_items[["properties"]])) {
        required_fields <- resolved_items[["required"]] %||% character(0)
        metadata <- purrr::imap(resolved_items[["properties"]], function(prop, prop_name) {
          list(
            name = prop_name,
            type = prop[["type"]] %||% NA,
            format = prop[["format"]] %||% NA,
            description = prop[["description"]] %||% "",
            enum = prop[["enum"]] %||% NULL,
            default = prop[["default"]] %||% NA,
            required = prop_name %in% required_fields,
            example = prop[["example"]] %||% prop[["default"]] %||% NA
          )
        })
        names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
        ref_type <- stringr::str_replace(items[["$ref"]], "#/definitions/", "")
        return(list(
          type = "array",
          item_schema = list(ref_type = ref_type, properties = metadata)
        ))
      }
    }

    # Inline array items
    item_type <- items[["type"]] %||% NA
    if (!is.na(item_type) && item_type == "string") {
      metadata <- list(
        query = list(
          name = "query",
          type = "array",
          item_type = "string",
          format = NA,
          description = body_schema[["description"]] %||% "Array of strings",
          enum = NULL,
          default = NA,
          required = TRUE,
          example = items[["example"]] %||% NA
        )
      )
      return(list(type = "string_array", item_type = "string", properties = metadata))
    }
  }

  # Handle simple string type
  if (!is.na(schema_type) && schema_type == "string") {
    metadata <- list(
      query = list(
        name = "query",
        type = "string",
        format = body_schema[["format"]] %||% NA,
        description = body_schema[["description"]] %||% "Query string",
        enum = body_schema[["enum"]] %||% NULL,
        default = body_schema[["default"]] %||% NA,
        required = TRUE,
        example = body_schema[["example"]] %||% NA
      )
    )
    return(list(type = "string", properties = metadata))
  }

  list(type = "unknown", properties = list())
}

# Resolve Swagger 2.0 definition reference
# Swagger 2.0 uses #/definitions/{SchemaName} (not #/components/schemas/)
resolve_swagger2_definition_ref <- function(ref, definitions) {
  if (is.null(ref) || !nzchar(ref)) return(NULL)

  # Parse #/definitions/{SchemaName}
  if (!grepl("^#/definitions/", ref)) {
    return(NULL)
  }

  schema_name <- stringr::str_replace(ref, "#/definitions/", "")

  if (is.null(definitions) || !is.list(definitions)) return(NULL)

  schema_def <- definitions[[schema_name]]
  if (is.null(schema_def) || !is.list(schema_def)) return(NULL)

  schema_def
}

# Extract body properties from request body
extract_body_properties <- function(request_body, components, schema_version = NULL) {
  if (is.null(request_body) || !is.list(request_body)) return(list())

  # If schema_version indicates Swagger 2.0 and request_body is parameters array,
  # delegate to Swagger 2.0 extraction and return early
  if (!is.null(schema_version) && identical(schema_version$type, "swagger")) {
    # For Swagger 2.0: request_body is actually parameters, components is definitions
    return(extract_swagger2_body_schema(request_body, components))
  }
  
  # Navigate: requestBody -> content -> application/json -> schema
  content <- request_body[["content"]] %||% list()
  json_schema <- content[["application/json"]][["schema"]] %||% list()
  
  if (length(json_schema) == 0) return(list())
  
  # Resolve reference if present
  if (!is.null(json_schema[["$ref"]])) {
    json_schema <- resolve_schema_ref(json_schema[["$ref"]], components, max_depth = 5)
  }
  
  # Check schema type
  type <- json_schema[["type"]] %||% NA

  # Handle simple string type
  if (!is.na(type) && type == "string") {
    # Create synthetic parameter metadata for the string body
    metadata <- list(
      query = list(
        name = "query",
        type = "string",
        format = json_schema[["format"]] %||% NA,
        description = json_schema[["description"]] %||% "Query string to search for",
        enum = json_schema[["enum"]] %||% NULL,
        default = json_schema[["default"]] %||% NA,
        required = TRUE,
        example = json_schema[["example"]] %||% NA
      )
    )

    return(list(
      type = "string",
      properties = metadata
    ))
  }

  # If array, extract item type
  if (type == "array" && !is.null(json_schema[["items"]])) {
    items <- json_schema[["items"]]
    
    # If items is a reference, resolve it
    if (!is.null(items[["$ref"]])) {
      resolved <- resolve_schema_ref(items[["$ref"]], components, max_depth = 5)
      
      # If resolved is object with properties, extract them
      if (!is.null(resolved[["properties"]])) {
        required_fields <- resolved[["required"]] %||% character(0)
        metadata <- purrr::imap(resolved[["properties"]], function(prop, prop_name) {
          list(
            name = prop_name,
            type = prop[["type"]] %||% NA,
            format = prop[["format"]] %||% NA,
            description = prop[["description"]] %||% "",
            enum = prop[["enum"]] %||% NULL,
            default = prop[["default"]] %||% NA,
            required = prop_name %in% required_fields,
            example = prop[["example"]] %||% prop[["default"]] %||% NA
          )
        })
        names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
        return(list(
          type = "array",
          item_schema = list(
            ref_type = stringr::str_replace(items[["$ref"]], "#/components/schemas/", ""),
            properties = metadata
          )
        ))
      }
    }

    # Array with inline object items (no $ref, but has type: object with properties)
    item_type <- items[["type"]] %||% NA
    if (!is.na(item_type) && item_type == "object" && !is.null(items[["properties"]])) {
      required_fields <- items[["required"]] %||% character(0)
      metadata <- purrr::imap(items[["properties"]], function(prop, prop_name) {
        list(
          name = prop_name,
          type = prop[["type"]] %||% NA,
          format = prop[["format"]] %||% NA,
          description = prop[["description"]] %||% "",
          enum = prop[["enum"]] %||% NULL,
          default = prop[["default"]] %||% NA,
          required = prop_name %in% required_fields,
          example = prop[["example"]] %||% prop[["default"]] %||% NA
        )
      })
      names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
      return(list(
        type = "object_array",
        item_schema = list(
          inline = TRUE,
          properties = metadata
        )
      ))
    }

    # Simple array (e.g., string array)
    if (!is.na(item_type) && item_type == "string") {
      # String array - create query parameter metadata
      metadata <- list(
        query = list(
          name = "query",
          type = "array",
          item_type = "string",
          format = json_schema[["format"]] %||% NA,
          description = json_schema[["description"]] %||% "Array of strings to search for",
          enum = json_schema[["enum"]] %||% NULL,
          default = json_schema[["default"]] %||% NA,
          required = TRUE,
          example = json_schema[["example"]] %||% items[["example"]] %||% NA
        )
      )

      return(list(
        type = "string_array",
        item_type = "string",
        properties = metadata
      ))
    }

    # Non-string arrays without object items
    return(list(
      type = "array",
      item_type = item_type,
      properties = list()
    ))
  }
  
  # If object, extract properties
  if (type == "object" && !is.null(json_schema[["properties"]])) {
    required_fields <- json_schema[["required"]] %||% character(0)
    
    metadata <- purrr::imap(json_schema[["properties"]], function(prop, prop_name) {
      list(
        name = prop_name,
        type = prop[["type"]] %||% NA,
        format = prop[["format"]] %||% NA,
        description = prop[["description"]] %||% "",
        enum = prop[["enum"]] %||% NULL,
        default = prop[["default"]] %||% NA,
        required = prop_name %in% required_fields,
        example = prop[["example"]] %||% prop[["default"]] %||% NA
      )
    })
    
    names(metadata) <- purrr::map_chr(metadata, ~ .x$name)
    return(list(
      type = "object",
      properties = metadata
    ))
  }
  
  # Unknown schema type
  list(type = "unknown", properties = list())
}

# Extract query parameters with schema reference resolution
# Flattens referenced schemas into individual query parameters
extract_query_params_with_refs <- function(parameters, components, max_depth = 5) {
  result_names <- character(0)
  result_metadata <- list()
  
  for (param in parameters) {
    if (is.null(param) || !is.list(param)) next
    
    param_name <- param[["name"]] %||% ""
    param_in <- param[["in"]] %||% ""
    
    # Only process query parameters
    if (param_in != "query") next
    
    schema <- param[["schema"]] %||% list()
    
    # Check if parameter has $ref
    schema_ref <- schema[["$ref"]]
    
    if (!is.null(schema_ref) && nzchar(schema_ref)) {
      # Resolve the schema reference
      resolved <- resolve_schema_ref(schema_ref, components, max_depth, depth = 0)
      
      # Check if resolved schema has properties (object)
      properties <- resolved[["properties"]] %||% list()
      required_fields <- resolved[["required"]] %||% character(0)
      
      if (length(properties) == 0) {
        # Simple type (string, integer, boolean, etc.)
        result_names <- c(result_names, param_name)
        result_metadata[[param_name]] <- list(
          name = param_name,
          type = schema[["type"]] %||% resolved[["type"]] %||% NA,
          format = schema[["format"]] %||% resolved[["format"]] %||% NA,
          description = param[["description"]] %||% resolved[["description"]] %||% "",
          enum = schema[["enum"]] %||% resolved[["enum"]] %||% NULL,
          default = schema[["default"]] %||% resolved[["default"]] %||% NA,
          required = param[["required"]] %||% FALSE,
          example = param[["example"]] %||% schema[["default"]] %||% NA
        )
      } else {
        # Object with properties - flatten into individual params
        # Use dot notation for nested properties
        for (prop_name in names(properties)) {
          prop <- properties[[prop_name]]
          
          # Check if property has $ref and resolve it
          prop_ref <- prop[["$ref"]]
          if (!is.null(prop_ref) && nzchar(prop_ref)) {
            # Resolve the nested $ref
            prop <- resolve_schema_ref(prop_ref, components, max_depth, 1)
          }
          
          # Extract property metadata first
          prop_type <- prop[["type"]] %||% NA
          prop_format <- prop[["format"]] %||% NA
          prop_desc <- prop[["description"]] %||% ""
          prop_enum <- prop[["enum"]] %||% NULL
          prop_default <- prop[["default"]] %||% NA
          prop_required <- prop_name %in% required_fields
          prop_example <- prop[["example"]] %||% prop_default %||% NA
          
          # Handle nested objects with dot notation
          if (!is.na(prop_type) && prop_type == "object" && !is.null(prop[["properties"]])) {
            # This is a nested object - recurse with dot notation
            # DON'T add the parent object to result_names, only the nested properties
            nested_props <- prop[["properties"]]
            nested_required <- prop[["required"]] %||% character(0)
            
            for (nested_name in names(nested_props)) {
              nested_prop <- nested_props[[nested_name]]
              nested_flat_name <- paste0(param_name, ".", prop_name, ".", nested_name)
              result_names <- c(result_names, nested_flat_name)
              
              result_metadata[[nested_flat_name]] <- list(
                name = nested_flat_name,
                type = nested_prop[["type"]] %||% NA,
                format = nested_prop[["format"]] %||% NA,
                description = nested_prop[["description"]] %||% "",
                enum = nested_prop[["enum"]] %||% NULL,
                default = nested_prop[["default"]] %||% NA,
                required = nested_name %in% nested_required,
                example = nested_prop[["example"]] %||% nested_prop[["default"]] %||% NA
              )
            }
          } else {
            # Simple property or array (not an object with nested properties)
            flat_name <- paste0(param_name, ".", prop_name)
            
            # Check if array type and reject binary arrays
            if (!is.na(prop_type) && prop_type == "array") {
              items <- prop[["items"]] %||% list()
              items_type <- items[["type"]] %||% NA
              items_format <- items[["format"]] %||% NA
              
              # REJECT binary arrays (e.g., files[])
              if (!is.na(items_format) && items_format == "binary") {
                # Skip binary arrays - don't include in query params
                next
              }
              
              # Support non-binary arrays
              result_names <- c(result_names, flat_name)
              result_metadata[[flat_name]] <- list(
                name = flat_name,
                type = "array",
                item_type = items_type,
                format = prop_format,
                description = prop_desc,
                enum = prop_enum,
                default = prop_default,
                required = prop_required,
                example = prop_example
              )
            } else {
              # Simple property
              result_names <- c(result_names, flat_name)
              result_metadata[[flat_name]] <- list(
                name = flat_name,
                type = prop_type,
                format = prop_format,
                description = prop_desc,
                enum = prop_enum,
                default = prop_default,
                required = prop_required,
                example = prop_example
              )
            }
          }
        }
      }
    } else {
      # No $ref - simple parameter with inline schema
      # REJECT binary arrays (e.g., files[])
      schema_type <- schema[["type"]] %||% NA
      schema_format <- schema[["format"]] %||% NA
      if (!is.na(schema_type) && schema_type == "array") {
        items <- schema[["items"]] %||% list()
        items_format <- items[["format"]] %||% NA
        if (!is.na(items_format) && items_format == "binary") {
          # Skip binary arrays - don't include in query params
          next
        }
      }
      
      result_names <- c(result_names, param_name)
      result_metadata[[param_name]] <- list(
        name = param_name,
        type = schema_type,
        format = schema_format,
        description = param[["description"]] %||% "",
        enum = schema[["enum"]] %||% NULL,
        default = schema[["default"]] %||% NA,
        required = param[["required"]] %||% FALSE,
        example = param[["example"]] %||% schema[["default"]] %||% NA
      )
    }
  }
  
  list(names = result_names, metadata = result_metadata)
}
