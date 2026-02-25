#' Safe list-to-tibble binding with type recovery
#'
#' Converts a list of named lists (API records) into a tibble, handling
#' type mismatches across records by coercing to character first, then
#' recovering types column-wise.
#'
#' @param body_list A list of named lists (each element = one record).
#' @param type_convert Logical; apply column-wise type recovery via
#'   `utils::type.convert()`. Default TRUE.
#' @param names_to Passed to `purrr::list_rbind()` for named outer lists.
#'   Creates a column from the names of `body_list`.
#' @return A tibble.
#' @noRd
safe_tidy_bind <- function(body_list, type_convert = TRUE, names_to = NULL) {
  if (length(body_list) == 0) return(tibble::tibble())

  # Phase 1: Coerce each record to a single-row all-character tibble

  # Pre-scan: identify fields that ever contain a list or multi-element vector.

  # These must be list-columns in ALL rows to avoid type conflicts during binding.
  list_fields <- character(0)
  for (x in body_list) {
    if (is.list(x)) {
      for (nm in names(x)) {
        val <- x[[nm]]
        if (!is.null(val) && (is.list(val) || length(val) > 1)) {
          list_fields <- c(list_fields, nm)
        }
      }
    }
  }
  list_fields <- unique(list_fields)

  rows <- purrr::map(body_list, function(x) {
    # Preserve query attribute
    q_attr <- attr(x, "query")

    if (is.null(x) || length(x) == 0) return(NULL)

    # Primitive (non-list) value
    if (!is.list(x)) {
      row <- tibble::tibble(value = as.character(x))
      if (!is.null(q_attr)) row <- dplyr::bind_cols(query = q_attr, row)
      return(row)
    }

    # Named list (typical API record)
    row <- purrr::imap(x, function(val, nm) {
      if (is.null(val)) {
        # Fields that are list-columns elsewhere need NA wrapped in list()
        if (nm %in% list_fields) list(NULL) else NA_character_
      } else if (is.list(val) || length(val) > 1) {
        # Nested list or multi-element vector -> list-column
        list(val)
      } else if (nm %in% list_fields) {
        # Scalar, but this field is a list-column in other rows — wrap to match
        list(val)
      } else {
        as.character(val)
      }
    })
    row <- tibble::as_tibble(row)
    if (!is.null(q_attr)) row <- dplyr::bind_cols(query = q_attr, row)
    row
  })

  res <- purrr::list_rbind(rows, names_to = names_to)

  if (nrow(res) == 0) return(tibble::tibble())

  # Phase 2: Collapse list-columns into semicolon-separated strings
  list_cols <- names(res)[purrr::map_lgl(res, is.list)]
  if (length(list_cols) > 0) {
    res <- dplyr::mutate(res, dplyr::across(
      dplyr::all_of(list_cols),
      ~ purrr::map_chr(.x, function(val) {
        if (is.null(val) || length(val) == 0) return(NA_character_)
        paste(as.character(unlist(val)), collapse = "; ")
      })
    ))
  }

  # Phase 3: Type recovery on character columns
  if (type_convert) {
    res <- dplyr::mutate(res, dplyr::across(
      dplyr::where(is.character),
      ~ utils::type.convert(.x, as.is = TRUE)
    ))
  }

  res
}

#' Generic API Request Function
#'
#' This is a centralized template function used by nearly all `ct_*` functions
#' to perform API requests. it handles normalization, batching, authentication,
#' error handling, and data tidying.
#'
#' @param query A character vector or list of items to be queried (e.g., DTXSIDs, CASRNs).
#'        For static endpoints (batch_limit=0), pass NULL or a placeholder value.
#' @param endpoint The API endpoint path (e.g., "hazard", "chemical/fate").
#' @param method The HTTP method to use: "POST" (default for bulk searches) or "GET".
#' @param server Either a Global environment variable name (e.g., 'ctx_burl') or a direct URL string.
#' @param batch_limit The number of items to send per request. Bulk POSTs usually use 100-1000.
#'        If set to 1, GET requests will append the query item directly to the URL path.
#'        If set to 0, treats as static endpoint (no query appending).
#' @param auth Boolean; whether to include the API key header. Defaults to TRUE.
#' @param tidy Boolean; whether to convert the result to a tidy tibble. Defaults to TRUE.
#'        If FALSE, returns a cleaned list structure.
#' @param path_params Optional vector or list of additional path parameters to append to the endpoint URL.
#'        Used for endpoints with multiple path parameters (e.g., property range searches).
#'        These are appended after the primary query parameter in the order provided.
#'        Cannot be used with batching (batch_limit > 1).
#' @param content_type Expected response content type. Defaults to "application/json".
#'        Supported types:
#'        - "application/json": Parses response as JSON (default behavior)
#'        - "text/plain": Returns response as character string
#'        - "image/*" (e.g., "image/png", "image/svg+xml"): Returns raw bytes or magick image
#' @param body_type How to encode the request body for POST requests. Defaults to "json".
#'        Supported types:
#'        - "json": Send as JSON array via `httr2::req_body_json()` (default)
#'        - "raw_text": Send as newline-delimited plain text via `httr2::req_body_raw()`
#'          with content type "text/plain". Used for endpoints like /chemical/search/equal/.
#' @param paginate Boolean; whether to automatically fetch all pages for paginated endpoints.
#'        Defaults to FALSE. When TRUE, uses httr2::req_perform_iterative() to loop through
#'        pages until exhausted or max_pages is reached. Requires pagination_strategy to be set.
#' @param max_pages Maximum number of pages to fetch when paginate=TRUE. Defaults to 100.
#'        Acts as a safety limit to prevent runaway pagination loops.
#' @param pagination_strategy The pagination strategy to use. One of: "offset_limit", "page_number",
#'        "page_size", "cursor", or NULL. When NULL, paginate is ignored.
#'        Usually set by generated stubs from Phase 19 metadata.
#' @param ... Additional parameters:
#'        - If method is "POST": Added as query parameters to the URL.
#'        - If method is "GET" and batch_limit is 1: Named arguments are added as query parameters.
#'        - If method is "GET" and batch_limit > 1: Added as query parameters to the URL.
#'
#' @return Depends on content_type:
#'         - JSON: A tidy tibble (if tidy=TRUE) or a cleaned list (if tidy=FALSE).
#'         - text/plain: A character string.
#'         - image/*: Raw bytes, or a magick image object if the magick package is available.
#'         If no results are found, returns an empty tibble, empty list, or NULL.
#' @export
generic_request <- function(query = NULL, endpoint, method = "POST", server = 'ctx_burl', batch_limit = NULL, auth = TRUE, tidy = TRUE, path_params = NULL, content_type = "application/json", body_type = "json", paginate = FALSE, max_pages = 100, pagination_strategy = NULL, ...) {

  # --- 1. Base URL Resolution ---
  # We check if 'server' refers to an environment variable (like 'ctx_burl').
  # If it doesn't exist, we assume 'server' is the literal URL.
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server

  # --- 2. Input Normalization ---
  # Ensure the query is a unique character vector without NAs or empty strings.
  # Special case: if batch_limit is 0, this is a static endpoint (no query needed)
  if (is.null(batch_limit)|| batch_limit == "NA") {
    batch_limit <- as.numeric(Sys.getenv("batch_limit", "1000"))
  }

  if (batch_limit == 0) {
    # Static endpoint: no query validation needed
    # Save original query value before overwriting (for adding to query string)
    original_query <- query
    query <- c("_static_")
    query_list <- list(query)
    mult_count <- 1
  } else {
    original_query <- NULL
    # Standard query handling
    if(purrr::is_list(query) && !is.data.frame(query)) {
      query <- as.character(unlist(query, use.names = FALSE))
    }
    query <- unique(as.vector(query))
    query <- query[!is.na(query) & query != ""]

    if (length(query) == 0) cli::cli_abort("Query must be a character vector.")

    # --- 3. Batching Preparation ---
    # API endpoints often have limits (e.g., 200 or 1000 items per POST).
    # We split the query into chunks based on the batch_limit.
    mult_count <- ceiling(length(query) / batch_limit)

    if (length(query) > batch_limit) {
      query_list <- split(
        query,
        rep(1:mult_count, each = batch_limit, length.out = length(query))
      )
    } else {
      query_list <- list(query)
    }
  }

  # --- 3.5. Validate path_params Usage ---
  # Path parameters cannot be used with batching
  if (!is.null(path_params) && length(path_params) > 0) {
    if (batch_limit > 1 || (length(query) > 1 && batch_limit != 0)) {
      cli::cli_abort(
        "Cannot use path_params with batching. Path parameter endpoints do not support batch queries."
      )
    }
  }

  # Check environment flags for logging/debugging
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = paste('Generic Request:', endpoint))
    cli::cli_dl(
      c(
        'Number of items' = '{length(query)}',
        'Number of batches' = '{mult_count}',
        'Method' = '{method}'
      )
    )
    cli::cli_rule()
    cli::cli_end()
  }

  # --- 4. Request Construction ---
  # Capture ellipsis arguments before purrr::map to preserve them in the function scope
  ellipsis_args <- list(...)

  # Flatten 'options' list if present (common pattern in chemi wrappers generated code)
  if ("options" %in% names(ellipsis_args) && is.list(ellipsis_args$options)) {
    opts <- ellipsis_args$options
    ellipsis_args$options <- NULL
    ellipsis_args <- c(ellipsis_args, opts)
  }

  # Create a list of httr2 request objects, one for each batch.
  req_list <- purrr::map(
    query_list,
    function(query_part) {
      req <- httr2::request(base_url) %>%
        httr2::req_url_path_append(endpoint) %>%
        httr2::req_headers(
          Accept = content_type
        )

      if (auth) {
        req <- req %>% httr2::req_headers(`x-api-key` = ct_api_key())
      }

      # Implementation for POST requests (Typically bulk searches)
      if (toupper(method) == "POST") {
        req <- req %>%
          httr2::req_method("POST")

        # Set request body based on body_type
        if (body_type == "raw_text") {
          # Send as newline-delimited plain text (e.g., /chemical/search/equal/)
          body_text <- paste(query_part, collapse = "\n")
          req <- req %>% httr2::req_body_raw(body_text, type = "text/plain")
        } else {
          # Default: Send as JSON array
          req <- req %>% httr2::req_body_json(query_part, auto_unbox = FALSE)
        }

        # Append additional path parameters if provided
        if (!is.null(path_params) && length(path_params) > 0) {
          for (pp in path_params) {
            req <- req %>% httr2::req_url_path_append(as.character(pp))
          }
        }

        # Add ellipsis arguments as query params (e.g., projection="all")
        req <- req %>% httr2::req_url_query(!!!ellipsis_args)
      }
      # Implementation for GET requests
      else {
        req <- req %>% httr2::req_method("GET")

        # Scenario A: Static endpoint (no query appending)
        if (batch_limit == 0) {
          # Add original query value to query parameters if provided
          if (!is.null(original_query) && query_part == "_static_") {
            ellipsis_args <- c(list(query = original_query), ellipsis_args)
          }
          # Only add named arguments as query parameters
          req <- req %>% httr2::req_url_query(!!!ellipsis_args)
        }
        # Scenario B: Path-based GET (one item at a time, e.g., /assay/ID)
        else if (batch_limit == 1) {
          req <- req %>% httr2::req_url_path_append(as.character(query_part))

          # Append additional path parameters if provided
          if (!is.null(path_params) && length(path_params) > 0) {
            for (pp in path_params) {
              req <- req %>% httr2::req_url_path_append(as.character(pp))
            }
          }

          # Separate named vs unnamed ellipsis arguments
          # nzchar() vectorizes properly, unlike != ""
          named_indices <- if (!is.null(names(ellipsis_args)) && length(names(ellipsis_args)) > 0) {
            nzchar(names(ellipsis_args))
          } else {
            rep(FALSE, length(ellipsis_args))
          }

          # Append unnamed args to the URL path (e.g., /assay/ID/similarity)
          if (any(!named_indices)) {
            for (val in ellipsis_args[!named_indices]) {
              req <- req %>% httr2::req_url_path_append(as.character(val))
            }
          }
          # Add named args as query parameters (e.g., ?top=500)
          if (any(named_indices)) {
            req <- req %>% httr2::req_url_query(!!!ellipsis_args[named_indices])
          }
        }
        # Scenario C: Parameter-based GET (bulk fetch via query string)
        else {
          req <- req %>% httr2::req_url_query(search = paste(query_part, collapse = ","), !!!ellipsis_args)
        }
      }

      return(req)
    }
  )

  # --- 5. Debugging Hook ---
  # If 'run_debug' is TRUE, we return a dry run of the first request instead of executing.
  if (run_debug) {
    return(req_list %>% purrr::pluck(1) %>% httr2::req_dry_run())
  }

  # --- 5.5. Pagination ---
  # When paginate=TRUE, use httr2::req_perform_iterative() instead of normal execution
  if (paginate && !is.null(pagination_strategy) && pagination_strategy != "none") {
    first_req <- req_list[[1]]

    # Build strategy-specific next_req callback for httr2::req_perform_iterative()
    if (pagination_strategy == "offset_limit" && !is.null(path_params)) {
      # AMOS-style: limit in path (query), offset in path_params
      # iterate_with_offset doesn't support path params, so use custom next_req
      page_limit <- as.numeric(query[1])
      initial_offset <- as.numeric(path_params[["offset"]] %||% path_params[[1]] %||% 0)

      next_req <- function(resp, req) {
        body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
        # Unwrap if response is wrapped in a named container (e.g., {"results": [...]})
        records <- if (is.list(body) && !is.null(names(body))) {
          body[["results"]] %||% body[["records"]] %||% body[["data"]] %||% body
        } else {
          body
        }
        # Done if fewer records than limit returned
        if (length(records) < page_limit || length(records) == 0) return(NULL)

        # Calculate new offset
        prev_url <- httr2::url_parse(req$url)
        path_parts <- strsplit(prev_url$path, "/")[[1]]
        current_offset <- as.numeric(path_parts[length(path_parts)])
        new_offset <- current_offset + page_limit

        # Rebuild URL with new offset in path
        path_parts[length(path_parts)] <- as.character(new_offset)
        new_path <- paste(path_parts, collapse = "/")
        req$url <- httr2::url_modify(req$url, path = new_path)
        req
      }

    } else if (pagination_strategy == "page_number") {
      # CTX-style: pageNumber as query parameter, starts at 1
      next_req <- httr2::iterate_with_offset(
        "pageNumber",
        start = as.numeric(ellipsis_args[["pageNumber"]] %||% 1),
        offset = 1,
        resp_complete = function(resp) {
          body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
          length(body) == 0
        }
      )

    } else if (pagination_strategy == "page_size") {
      # Spring Boot Pageable: page + size as query params, 0-indexed
      start_page <- as.numeric(ellipsis_args[["page"]] %||% 0)
      next_req <- httr2::iterate_with_offset(
        "page",
        start = start_page,
        offset = 1,
        resp_pages = function(resp) {
          httr2::resp_body_json(resp, simplifyVector = FALSE)[["totalPages"]]
        },
        resp_complete = function(resp) {
          isTRUE(httr2::resp_body_json(resp, simplifyVector = FALSE)[["last"]])
        }
      )

    } else if (pagination_strategy == "offset_limit" && is.null(path_params)) {
      # Offset/limit via query params (e.g., Common Chemistry offset+size)
      offset_name <- "offset"
      size_name <- if ("size" %in% names(ellipsis_args)) "size" else "limit"
      initial_offset <- as.numeric(ellipsis_args[[offset_name]] %||% 0)
      page_size <- as.numeric(ellipsis_args[[size_name]] %||% 100)

      next_req <- httr2::iterate_with_offset(
        offset_name,
        start = initial_offset,
        offset = page_size,
        resp_complete = function(resp) {
          body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
          # Check various response shapes for exhaustion
          records <- body[["results"]] %||% body[["data"]] %||%
            (if (is.list(body) && is.null(names(body))) body else NULL)
          if (is.null(records)) return(TRUE)
          # Done if fewer records than page size
          length(records) < page_size || length(records) == 0
        }
      )

    } else if (pagination_strategy == "cursor") {
      # Cursor/keyset: cursor value in query param
      next_req <- httr2::iterate_with_cursor(
        "cursor",
        resp_param_value = function(resp) {
          body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
          body[["cursor"]] %||% body[["nextCursor"]] %||% body[["next"]]
        }
      )

    } else {
      cli::cli_abort("Unknown pagination_strategy: {.val {pagination_strategy}}")
    }

    # Execute iterative pagination
    resps <- httr2::req_perform_iterative(
      first_req,
      next_req = next_req,
      max_reqs = max_pages,
      on_error = "return",
      progress = run_verbose
    )

    # Filter to successful responses only
    resps <- httr2::resps_successes(resps)

    # Warn if pagination may have been truncated
    if (length(resps) >= max_pages) {
      cli::cli_warn(c(
        "Pagination stopped at {.val {max_pages}} page{?s} (the {.arg max_pages} limit).",
        "i" = "More data may be available. Increase {.arg max_pages} to fetch additional pages."
      ))
    }

    if (length(resps) == 0) {
      cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
      if (tidy) return(tibble::tibble()) else return(list())
    }

    if (run_verbose) {
      cli::cli_alert_success("Pagination complete: {length(resps)} pages fetched.")
    }

    # Extract records from all responses based on strategy
    body_list <- purrr::map(resps, function(resp) {
      body <- httr2::resp_body_json(resp, simplifyVector = FALSE)

      # Strategy-specific record extraction
      records <- if (pagination_strategy == "page_size") {
        # Spring Boot wraps in "content"
        body[["content"]] %||% list()
      } else if (!is.null(body[["results"]])) {
        # Common Chemistry wraps in "results"
        body[["results"]]
      } else if (!is.null(body[["records"]])) {
        # Chemi Search wraps in "records"
        body[["records"]]
      } else if (is.list(body) && is.null(names(body))) {
        # Top-level array (AMOS, CTX pageNumber)
        body
      } else {
        list(body)
      }

      records
    }) |> purrr::list_flatten()

    if (length(body_list) == 0) {
      cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
      if (tidy) return(tibble::tibble()) else return(list())
    }

    # Apply same output formatting as non-paginated path
    if (!tidy) {
      return(body_list |>
        purrr::map(function(x) {
          if (is.list(x) && length(x) > 0) x[purrr::map_lgl(x, is.null)] <- NA
          x
        }))
    }

    return(safe_tidy_bind(body_list))
  }

  # --- 6. Execution ---
  # Perform requests. Use sequential execution for batches to avoid hitting rate limits too hard.
  if (length(req_list) > 1) {
    resp_list <- req_list %>%
      httr2::req_perform_sequential(on_error = 'continue', progress = run_verbose)
  } else {
    resp_list <- list(httr2::req_perform(req_list[[1]]))
  }

  # --- 7. Response Processing ---

  # Determine response type from content_type parameter

  is_image <- grepl("^image/", content_type)
  is_text <- grepl("^text/plain", content_type)
  is_json <- !is_image && !is_text

  # For non-JSON content types, we handle responses differently

  if (is_image) {
    # Image responses: return raw bytes or magick image
    body_list <- resp_list %>%
      purrr::map2(query_list, function(r, qp) {
        if (inherits(r, "httr2_error")) r <- r$resp
        if (!inherits(r, "httr2_response")) return(NULL)

        status <- httr2::resp_status(r)
        if (status < 200 || status >= 300) {
          cli::cli_warn("API request to {.val {endpoint}} failed for {.val {qp[1]}} with status {status}")
          return(NULL)
        }

        raw_bytes <- httr2::resp_body_raw(r)

        # Try to convert to magick image if package is available
        if (requireNamespace("magick", quietly = TRUE)) {
          tryCatch(
            magick::image_read(raw_bytes),
            error = function(e) raw_bytes
          )
        } else {
          raw_bytes
        }
      })

    # For single query, return the image directly (not as a list)
    if (length(body_list) == 1) {
      return(body_list[[1]])
    }
    return(body_list)
  }

  if (is_text) {
    # Text responses: return as character string
    body_list <- resp_list %>%
      purrr::map2(query_list, function(r, qp) {
        if (inherits(r, "httr2_error")) r <- r$resp
        if (!inherits(r, "httr2_response")) return(NULL)

        status <- httr2::resp_status(r)
        if (status < 200 || status >= 300) {
          cli::cli_warn("API request to {.val {endpoint}} failed for {.val {qp[1]}} with status {status}")
          return(NULL)
        }

        httr2::resp_body_string(r)
      })

    # For single query, return the string directly
    if (length(body_list) == 1) {
      return(body_list[[1]])
    }
    return(body_list)
  }

  # JSON responses (default): Extract JSON bodies and handle HTTP errors gracefully.
  body_list <- resp_list %>%
    purrr::map2(query_list, function(r, qp) {
      # Handle potential httr2 error objects
      if (inherits(r, "httr2_error")) r <- r$resp
      if (!inherits(r, "httr2_response")) return(NULL)

      status <- httr2::resp_status(r)
      if (status < 200 || status >= 300) {
        cli::cli_warn("API request to {.val {endpoint}} failed for {.val {qp[1]}} with status {status}")
        return(NULL)
      }

      body <- httr2::resp_body_json(r)

      # If we are in path-based GET (batch_limit=1), we want to preserve the query ID
      if (length(qp) == 1 && is.list(body)) {
         # We add the query as a named attribute so it can be picked up during flattening
         attr(body, "query") <- qp[1]
      }

      return(body)
    }) %>%
    # Flatten the list of responses (one list of data per batch) into one single list
    purrr::list_flatten()

  if (length(body_list) == 0) {
    cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
    if (tidy) {
      return(tibble::tibble())
    } else {
      return(list())
    }
  }

  # --- 8. Output Formatting ---
  # Return as-is if tidy=FALSE (cleaned list structure)
  if (!tidy) {
    # Basic cleanup: replace NULLs with NA in list elements
    res <- body_list %>%
      purrr::map(function(x) {
        if (is.list(x) && length(x) > 0) {
          x[purrr::map_lgl(x, is.null)] <- NA
        }
        return(x)
      })
    return(res)
  }

  # --- 9. Tidy Conversion ---
  res <- safe_tidy_bind(body_list)

  return(res)
}

#' Generic Cheminformatics API Request Function
#'
#' This specialized template handles the nested payload structure common to the
#' EPA cheminformatics microservices: `{"chemicals": [{"sid": "ID1"}], "options": {...}}`
#'
#' @param query A character vector of identifiers (DTXSIDs, etc.). If NULL and chemicals is
#'        provided, the chemicals parameter is used instead.
#' @param endpoint The specific sub-path (e.g., "toxprints/calculate")
#' @param options A named list of parameters to be placed in the 'options' JSON field.
#' @param sid_label The key used for identifiers in the JSON body (usually "sid").
#' @param server Global environment variable name for the base URL (default: 'chemi_burl').
#' @param auth Boolean; whether to include the API key header. Defaults to FALSE.
#' @param pluck_res Optional character; the name of the field to extract from the JSON response.
#' @param wrap Boolean; whether to wrap the query in a `{"chemicals": [...], "options": ...}` structure.
#'        Defaults to TRUE. If FALSE, sends a JSON array of objects like `[{"sid": "ID1"}, ...]`.
#'        Ignored if array_payload is TRUE.
#' @param array_payload Boolean; if TRUE, creates a flat structure with identifiers as an array:
#'        `{"ids": ["ID1", "ID2"], "option1": "value1", ...}`. When TRUE, sid_label is used as the
#'        array key name and options are merged at the top level. Takes precedence over wrap parameter.
#'        Defaults to FALSE.
#' @param tidy Boolean; whether to convert the result to a tidy tibble. Defaults to TRUE.
#' @param chemicals Optional list of pre-resolved Chemical objects. Each element should be a
#'        list with fields like sid, smiles, casrn, inchi, inchiKey, name, mol. When provided,
#'        this takes precedence over the query parameter for building the chemicals payload.
#' @param paginate Boolean; whether to automatically fetch all pages. Defaults to FALSE.
#'        When TRUE, uses httr2::req_perform_iterative() to loop through pages.
#' @param max_pages Maximum pages to fetch when paginate=TRUE. Defaults to 100.
#' @param pagination_strategy Pagination strategy. For chemi search, usually "offset_limit" (body).
#' @param ... Additional arguments passed to httr2.
#'
#' @return A tidy tibble (if tidy=TRUE) or a raw list.
#' @export
generic_chemi_request <- function(query = NULL, endpoint, options = list(), sid_label = "sid",
                                  server = "chemi_burl", auth = FALSE, pluck_res = NULL,
                                  wrap = TRUE, array_payload = FALSE, tidy = TRUE,
                                  chemicals = NULL, paginate = FALSE, max_pages = 100,
                                  pagination_strategy = NULL, ...) {
  
  # 1. Base URL Resolution
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server

  # 2. Input Normalization
  # If pre-resolved chemicals are provided, use them directly
  if (!is.null(chemicals) && is.list(chemicals) && length(chemicals) > 0) {
    # Use pre-resolved chemicals directly
    resolved_chemicals <- chemicals
  } else {
    # Standard query handling
    query <- unique(as.vector(query))
    query <- query[!is.na(query) & query != ""]
    if (length(query) == 0) cli::cli_abort("Either query or chemicals parameter must be provided.")
    resolved_chemicals <- NULL
  }

  # 3. Payload Construction
  if (!is.null(resolved_chemicals)) {
    # Pre-resolved chemicals provided - use them directly
    if (wrap) {
      payload <- list(
        chemicals = resolved_chemicals,
        options = options
      )
    } else {
      payload <- resolved_chemicals
    }
  } else if (array_payload) {
    # Array format: {"ids": ["ID1", "ID2"], "option1": "value1", ...}
    # Put identifiers directly as an array, merge options at top level
    payload <- c(set_names(list(query), sid_label), options)
  } else {
    # Standard format with wrap parameter
    chemicals_list <- purrr::map(query, ~ set_names(list(.x), sid_label))
    
    if (wrap) {
      payload <- list(
        chemicals = chemicals_list,
        options = options
      )
    } else {
      payload <- chemicals_list
    }
  }

  # Check environment flags
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    # Determine count based on whether chemicals or query was provided
    item_count <- if (!is.null(resolved_chemicals)) length(resolved_chemicals) else length(query)
    cli::cli_rule(left = paste('Generic Chemi Request:', endpoint))
    cli::cli_dl(c('Number of items' = '{item_count}'))
    cli::cli_rule()
    cli::cli_end()
  }

  # 4. Request building
  req <- httr2::request(base_url) %>%
    httr2::req_url_path_append(endpoint) %>%
    httr2::req_method("POST") %>%
    httr2::req_body_json(payload) %>%
    httr2::req_headers(Accept = "application/json")

  if (auth) {
    req <- req %>% httr2::req_headers(`x-api-key` = ct_api_key())
  }

  # 5. Debugging
  if (run_debug) {
    return(httr2::req_dry_run(req))
  }

  # 5.5. Pagination
  if (paginate && !is.null(pagination_strategy) && pagination_strategy != "none") {
    # Chemi Search: offset + limit in request body
    # Response: {totalRecordsCount, recordsCount, records, offset, limit, ...}
    # Use custom next_req since iterate_with_offset only handles query params
    page_limit <- as.numeric(options[["limit"]] %||% 100)

    next_req <- function(resp, req) {
      body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
      total <- body[["totalRecordsCount"]] %||% 0
      current_offset <- body[["offset"]] %||% 0
      records_count <- body[["recordsCount"]] %||% length(body[["records"]] %||% list())

      # Done if we've fetched all records or got an empty page
      if (records_count == 0 || (current_offset + records_count) >= total) return(NULL)

      new_offset <- current_offset + records_count
      req %>% httr2::req_body_json_modify(offset = new_offset)
    }

    resps <- httr2::req_perform_iterative(
      req,
      next_req = next_req,
      max_reqs = max_pages,
      on_error = "return",
      progress = run_verbose
    )

    resps <- httr2::resps_successes(resps)

    if (length(resps) == 0) {
      if (tidy) return(tibble::tibble()) else return(list())
    }

    if (run_verbose) {
      cli::cli_alert_success("Chemi pagination complete: {length(resps)} pages fetched.")
    }

    # Extract records from each page
    body_list <- purrr::map(resps, function(resp) {
      body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
      records <- body[["records"]] %||% list()
      if (!is.null(pluck_res)) {
        records <- purrr::map(records, ~ purrr::pluck(.x, pluck_res))
      }
      records
    }) %>% purrr::list_flatten()

    if (length(body_list) == 0) {
      if (tidy) return(tibble::tibble()) else return(list())
    }

    if (!tidy) return(body_list)

    return(safe_tidy_bind(body_list))
  }

  # 6. Execution
  resp <- httr2::req_perform(req)

  # 7. Response Processing
  if (httr2::resp_status(resp) < 200 || httr2::resp_status(resp) >= 300) {
    cli::cli_abort("Chemi API request to {.val {endpoint}} failed with status {httr2::resp_status(resp)}")
  }

  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  
  if (!is.null(pluck_res)) {
    body <- purrr::pluck(body, pluck_res)
  }

  if (length(body) == 0) {
    if (tidy) return(tibble::tibble()) else return(list())
  }

  if (!tidy) return(body)

  # 8. Tidy Conversion
  # Handle cases where body is a named list of results (keyed by query)
  if (!is.null(names(body)) && !is.data.frame(body)) {
    res <- safe_tidy_bind(body, names_to = "query_id")
  } else {
    res <- safe_tidy_bind(body)

    # If the results match the query length, add the query column
    # Only do this when query (not chemicals) was provided
    if (!is.null(query) && length(query) > 0 && nrow(res) == length(query) && !"dtxsid" %in% colnames(res)) {
       res <- dplyr::bind_cols(dtxsid = query, res)
    }
  }

  return(res)
}

#' Generic Search API Request Function
#'
#' Specialized template for the cheminformatics search endpoint which uses a
#' different payload structure: `inputType`, `searchType`, `params`, `query`
#'
#' @param search_type The search type (e.g., "EXACT", "SIMILAR", "MASS", "HAZARD", "FEATURES").
#' @param input_type The input format type. Defaults to "MOL".
#' @param query The query string (typically a MOL file string). Can be NULL for mass searches.
#' @param params A named list of additional search parameters.
#' @param endpoint The API endpoint path. Defaults to "search".
#' @param server Environment variable name for base URL. Defaults to "chemi_burl".
#' @param tidy Boolean; whether to return raw response body or just pass through. Defaults to TRUE.
#'
#' @return The parsed JSON response body (list structure).
#' @keywords internal
generic_search_request <- function(
    search_type,
    input_type = "MOL",
    query = NULL,
    params = list(),
    endpoint = "search",
    server = "chemi_burl",
    tidy = TRUE
) {
  # 1. Base URL Resolution
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server

  # 2. Payload Construction
  payload <- list(
    inputType = input_type,
    searchType = search_type,
    params = params
  )

  # Only include query if not NULL
  if (!is.null(query)) {
    payload$query <- query
  }

  # Remove NULL params
  payload$params <- purrr::compact(payload$params)

  # Check environment flags
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = paste("Generic Search Request:", search_type))
    cli::cli_dl(c(
      "Input type" = input_type,
      "Search type" = search_type,
      "Params count" = length(payload$params)
    ))
    cli::cli_rule()
  }

  # 3. Request building
  req <- httr2::request(base_url) %>%
    httr2::req_url_path_append(endpoint) %>%
    httr2::req_method("POST") %>%
    httr2::req_body_json(payload) %>%
    httr2::req_headers(
      Accept = "application/json",
      `Content-Type` = "application/json"
    )

  # 4. Debugging
  if (run_debug) {
    return(httr2::req_dry_run(req))
  }

  # 5. Execution
  resp <- httr2::req_perform(req)

  # 6. Response Processing
  status <- httr2::resp_status(resp)
  if (status < 200 || status >= 300) {
    cli::cli_abort("Search API request failed with status {status}")
  }

  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)

  return(body)
}

#' Generic CAS Common Chemistry API Request Function
#'
#' This is a specialized wrapper for CAS Common Chemistry API requests.
#' It handles the specific authentication (cc_api_key) and server configuration
#' for the Common Chemistry API endpoints.
#'
#' @param endpoint The API endpoint path (e.g., "detail", "search", "export").
#' @param method The HTTP method to use: "GET" (default) or "POST".
#' @param server Environment variable name for the base URL. Defaults to "cc_burl".
#' @param auth Boolean; whether to include the API key header. Defaults to TRUE.
#' @param tidy Boolean; whether to convert the result to a tidy tibble. Defaults to TRUE.
#'        If FALSE, returns a cleaned list structure.
#' @param content_type Expected response content type. Defaults to "application/json".
#' @param paginate Boolean; whether to automatically fetch all pages. Defaults to FALSE.
#' @param max_pages Maximum pages to fetch when paginate=TRUE. Defaults to 100.
#' @param pagination_strategy Pagination strategy (usually "offset_limit" for CC). Defaults to NULL.
#' @param ... Additional parameters passed as query parameters to the API.
#'
#' @return Depends on content_type and tidy parameter:
#'         - JSON with tidy=TRUE: A tidy tibble.
#'         - JSON with tidy=FALSE: A cleaned list structure.
#'         - text/plain: A character string.
#'         If no results are found, returns an empty tibble or list.
#' @export
generic_cc_request <- function(endpoint, method = "GET", server = "cc_burl",
                               auth = TRUE, tidy = TRUE, content_type = "application/json",
                               paginate = FALSE, max_pages = 100, pagination_strategy = NULL, ...) {
  
  # --- 1. Base URL Resolution ---
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server
  
  # Check environment flags for logging/debugging
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))
  
  if (run_verbose) {
    cli::cli_rule(left = paste('Generic CC Request:', endpoint))
    cli::cli_dl(c('Method' = '{method}'))
    cli::cli_rule()
    cli::cli_end()
  }
  
  # --- 2. Capture ellipsis arguments ---
  ellipsis_args <- list(...)
  
  # --- 3. Request Construction ---
  req <- httr2::request(base_url) %>%
    httr2::req_url_path_append(endpoint) %>%
    httr2::req_method(toupper(method)) %>%
    httr2::req_headers(Accept = content_type)
  
  # Add CC API key authentication
  if (auth) {
    req <- req %>% httr2::req_headers(`x-api-key` = cc_api_key())
  }
  
  # Add query parameters
  if (length(ellipsis_args) > 0) {
    req <- req %>% httr2::req_url_query(!!!ellipsis_args)
  }
  
  # --- 4. Debugging Hook ---
  if (run_debug) {
    return(httr2::req_dry_run(req))
  }

  # --- 4.5. Pagination ---
  if (paginate && !is.null(pagination_strategy) && pagination_strategy != "none") {
    # Common Chemistry uses offset/size query params
    # Response: {count: "N", results: [...]}
    offset_val <- as.numeric(ellipsis_args[["offset"]] %||% 0)
    size_val <- as.numeric(ellipsis_args[["size"]] %||% 100)

    next_req <- httr2::iterate_with_offset(
      "offset",
      start = offset_val,
      offset = size_val,
      resp_complete = function(resp) {
        body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
        total <- as.numeric(body[["count"]] %||% 0)
        results <- body[["results"]] %||% list()
        length(results) == 0 || length(results) < size_val
      }
    )

    resps <- httr2::req_perform_iterative(
      req,
      next_req = next_req,
      max_reqs = max_pages,
      on_error = "return",
      progress = run_verbose
    )

    resps <- httr2::resps_successes(resps)

    if (length(resps) == 0) {
      cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
      if (tidy) return(tibble::tibble()) else return(list())
    }

    if (run_verbose) {
      cli::cli_alert_success("CC pagination complete: {length(resps)} pages fetched.")
    }

    # Extract records from "results" field of each page
    body_list <- purrr::map(resps, function(resp) {
      body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
      body[["results"]] %||% list()
    }) |> purrr::list_flatten()

    if (length(body_list) == 0) {
      cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
      if (tidy) return(tibble::tibble()) else return(list())
    }

    if (!tidy) {
      return(body_list |> purrr::map(function(x) {
        if (is.list(x) && length(x) > 0) x[purrr::map_lgl(x, is.null)] <- NA
        x
      }))
    }

    res <- body_list |>
      purrr::map(function(x) {
        if (is.list(x) && length(x) > 0) {
          x[purrr::map_lgl(x, is.null)] <- NA
          tryCatch(tibble::as_tibble(x), error = function(e) tibble::tibble(data = list(x)))
        } else if (is.null(x) || length(x) == 0) {
          NULL
        } else {
          tibble::tibble(value = x)
        }
      }) |>
      purrr::list_rbind()

    return(res)
  }

  # --- 5. Execution ---
  resp <- httr2::req_perform(req)

  # --- 6. Response Processing ---
  status <- httr2::resp_status(resp)
  if (status < 200 || status >= 300) {
    cli::cli_abort("CAS Common Chemistry API request to {.val {endpoint}} failed with status {status}")
  }
  
  # Handle different content types
  is_text <- grepl("^text/plain", content_type)
  is_json <- !is_text
  
  if (is_text) {
    return(httr2::resp_body_string(resp))
  }
  
  # JSON response handling
  body <- httr2::resp_body_json(resp, simplifyVector = FALSE)
  
  if (length(body) == 0) {
    cli::cli_warn("No results found for the given query in {.val {endpoint}}.")
    if (tidy) {
      return(tibble::tibble())
    } else {
      return(list())
    }
  }
  
  # --- 7. Output Formatting ---
  if (!tidy) {
    # Basic cleanup: replace NULLs with NA in list elements
    if (is.list(body) && length(body) > 0) {
      body[purrr::map_lgl(body, is.null)] <- NA
    }
    return(body)
  }
  
  # --- 8. Tidy Conversion ---
  if (is.list(body) && !is.null(names(body))) {
    # Single object response — wrap in list for safe_tidy_bind
    res <- safe_tidy_bind(list(body))
  } else if (is.list(body)) {
    # Array of objects
    res <- safe_tidy_bind(body)
  } else {
    # Primitive value
    res <- tibble::tibble(value = body)
  }

  return(res)
}
