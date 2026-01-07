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
generic_request <- function(query, endpoint, method = "POST", server = 'ctx_burl', batch_limit = NULL, auth = TRUE, tidy = TRUE, path_params = NULL, content_type = "application/json", ...) {

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
    query <- c("_static_")
    query_list <- list(query)
    mult_count <- 1
  } else {
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
          httr2::req_method("POST") %>%
          httr2::req_body_json(query_part, auto_unbox = FALSE)

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
          named_indices <- !is.null(names(ellipsis_args)) && length(names(ellipsis_args)) > 0 && names(ellipsis_args) != ""

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
  # Convert the parsed JSON (list of lists) into a tidy tibble.
  res <- body_list %>%
    purrr::map(function(x) {
      q_attr <- attr(x, "query")
      if (is.list(x) && length(x) > 0) {
        # Replace NULLs with NA so they don't disappear during tibble conversion
        x[purrr::map_lgl(x, is.null)] <- NA
        row <- tibble::as_tibble(x)
        if (!is.null(q_attr)) row <- dplyr::bind_cols(query = q_attr, row)
        return(row)
      } else if (is.null(x) || length(x) == 0) {
        return(NULL)
      } else {
        # Primitive values (strings/numbers) are wrapped into a 'value' column
        row <- tibble::tibble(value = x)
        if (!is.null(q_attr)) row <- dplyr::bind_cols(query = q_attr, row)
        return(row)
      }
    }) %>%
    purrr::list_rbind()

  return(res)
}

#' Generic Cheminformatics API Request Function
#'
#' This specialized template handles the nested payload structure common to the
#' EPA cheminformatics microservices: {"chemicals": [{"sid": "ID1"}], "options": {...}}
#'
#' @param query A character vector of identifiers (DTXSIDs, etc.)
#' @param endpoint The specific sub-path (e.g., "toxprints/calculate")
#' @param options A named list of parameters to be placed in the 'options' JSON field.
#' @param sid_label The key used for identifiers in the JSON body (usually "sid").
#' @param server Global environment variable name for the base URL (default: 'chemi_burl').
#' @param auth Boolean; whether to include the API key header. Defaults to FALSE.
#' @param pluck_res Optional character; the name of the field to extract from the JSON response.
#' @param wrap Boolean; whether to wrap the query in a {"chemicals": [...], "options": ...} structure.
#'        Defaults to TRUE. If FALSE, sends a JSON array of objects like [{"sid": "ID1"}, ...].
#' @param tidy Boolean; whether to convert the result to a tidy tibble. Defaults to TRUE.
#' @param ... Additional arguments passed to httr2.
#'
#' @return A tidy tibble (if tidy=TRUE) or a raw list.
#' @export
generic_chemi_request <- function(query, endpoint, options = list(), sid_label = "sid", 
                                  server = "chemi_burl", auth = FALSE, pluck_res = NULL, 
                                  wrap = TRUE, tidy = TRUE, ...) {
  
  # 1. Base URL Resolution
  base_url <- Sys.getenv(server, unset = server)
  if (base_url == "") base_url <- server

  # 2. Input Normalization
  query <- unique(as.vector(query))
  query <- query[!is.na(query) & query != ""]
  if (length(query) == 0) cli::cli_abort("Query must be a character vector.")

  # 3. Payload Construction
  chemicals <- purrr::map(query, ~ set_names(list(.x), sid_label))
  
  if (wrap) {
    payload <- list(
      chemicals = chemicals,
      options = options
    )
  } else {
    payload <- chemicals
  }

  # Check environment flags
  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (run_verbose) {
    cli::cli_rule(left = paste('Generic Chemi Request:', endpoint))
    cli::cli_dl(c('Number of items' = '{length(query)}'))
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
  if (!tidy) return(body)

  # Handle cases where body is a named list of results (keyed by query)
  if (!is.null(names(body)) && !is.data.frame(body)) {
      res <- body %>%
        purrr::map(function(x) {
          if (is.list(x) && length(x) > 0) {
            x[purrr::map_lgl(x, is.null)] <- NA
            return(tibble::as_tibble(x))
          } else {
            return(tibble::tibble(value = x))
          }
        }) %>%
        purrr::list_rbind(names_to = "query_id")
  } else {
      # If body is an unnamed list, we attempt to match it back to the query 
      # if the counts match exactly, otherwise we just bind.
      res <- body %>%
        purrr::map(function(x) {
          if (is.list(x) && length(x) > 0) {
            # Check for name collisions or nested lists
            x[purrr::map_lgl(x, is.null)] <- NA
            # We use try as some deeply nested chemi-results might fail direct as_tibble
            t_res <- try(tibble::as_tibble(x), silent = TRUE)
            if (inherits(t_res, "try-error")) return(tibble::tibble(data = list(x)))
            return(t_res)
          } else if (is.null(x) || length(x) == 0) {
            return(NULL)
          } else {
            return(tibble::tibble(value = x))
          }
        }) %>%
        purrr::list_rbind()
      
      # If the results match the query length, add the query column
      if (nrow(res) == length(query) && !"dtxsid" %in% colnames(res)) {
         res <- dplyr::bind_cols(dtxsid = query, res)
      }
  }

  return(res)
}
