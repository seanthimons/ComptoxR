#' Retrieves compound physio-chem properties by DTXSID
#'
#' Returns both experimental and predicted results.
#'
#' @details
#' For a full list of properties that can be searched for, load the data set `property_ids` and use the `propertyId` field for the `query` field.
#'
#' @param search_param Search for `compound` or `property` to look for.
#' @param query A list of DTXSIDs or a property to be queries against. See details for full list of properties available.
#' @param range A lower and upper range of values to search for if a property was specified for.
#' @param coerce Boolean to coerce data to a list of data frames
#'
#' @return A list or dataframe
#' @export

ct_properties <- function(
  search_param,
  query,
  range,
  coerce = TRUE
) {
  if (missing(search_param)) {
    cli::cli_abort("Missing search type!")
  }

  query <- unique(as.vector(query))

  if (length(query) == 0) {
    cli::cli_abort("Query must be a character vector.")
  }

  run_debug <- as.logical(Sys.getenv("run_debug", "FALSE"))
  run_verbose <- as.logical(Sys.getenv("run_verbose", "FALSE"))

  if (search_param == "compound") {
    if (run_verbose) {
      cli::cli_rule(left = "Phys-chem properties payload options")
      cli::cli_dl(
        c(
          "Search type" = "{search_param}",
          "Number of compounds" = "{length(query)}",
          "Coerce" = "{coerce}"
        )
      )
      cli::cli_rule()
      cli::cli_end()
    }

    batch_limit <- 200
    mult_count <- ceiling(length(query) / batch_limit)

    if (length(query) > batch_limit) {
      query_list <- split(
        query,
        rep(1:mult_count, each = batch_limit, length.out = length(query))
      )
    } else {
      query_list <- list(query)
    }

    # Build requests
    req_list <- map(
      query_list,
      function(query_part) {
        request(Sys.getenv('ctx_burl')) %>%
          req_method("POST") %>%
          req_url_path_append("chemical/property/search/by-dtxsid/") %>%
          req_headers(
            Accept = "application/json, text/plain, */*",
            `Content-Type` = "application/json",
            `x-api-key` = ct_api_key()
          ) %>%
          req_body_json(
            as.list(query_part),
            auto_unbox = FALSE
          )
      }
    )

    if (run_debug) {
      return(req_list %>% pluck(., 1) %>% req_dry_run())
    }

    # Perform requests
    if (length(req_list) > 1) {
      resp_list <- req_perform_sequential(req_list, on_error = 'continue', progress = TRUE)
    } else {
      resp_list <- list(req_perform(req_list[[1]]))
    }

    # Process responses
    body_list <- map(
      resp_list,
      function(r) {
        if (inherits(r, "httr2_error")) {
          r <- r$resp
        }

        if (!inherits(r, "httr2_response")) {
          cli::cli_warn("Request failed")
          return(tibble())
        }

        if (resp_status(r) < 200 || resp_status(r) >= 300) {
          cli::cli_warn("API request failed with status {resp_status(r)}")
          return(tibble())
        }

        body <- resp_body_json(r)

        if (length(body) == 0) {
          return(tibble())
        }

        body %>%
          map(~ map_if(.x, is.null, ~NA_character_)) %>%
          as_tibble()
      }
    ) %>%
      list_rbind()

    df <- body_list

    if (coerce == TRUE) {
      df <- df %>%
        split(.$propertyId)
    }

    return(df)
  }

  if (search_param == "property") {
    if (missing(range) || length(range) != 2) {
      cli::cli_abort("Missing range for property search! Range must be a vector of length 2.")
    }

    range <- as.numeric(range)

    if (run_verbose) {
      cli::cli_rule(left = "Phys-chem properties payload options")
      cli::cli_dl(
        c(
          "Search type" = "{search_param}",
          "Property" = "{query}",
          "Range" = "{paste(range, collapse = '-')}",
          "Coerce" = "{coerce}"
        )
      )
      cli::cli_rule()
      cli::cli_end()
    }

    # Build request
    req <- request(Sys.getenv('ctx_burl')) %>%
      req_method("GET") %>%
      req_url_path_append("chemical/property/search/by-range/") %>%
      req_url_path_append(query) %>%
      req_url_path_append(as.character(range[1])) %>%
      req_url_path_append(as.character(range[2])) %>%
      req_headers(
        Accept = "application/json",
        `x-api-key` = ct_api_key()
      )

    if (run_debug) {
      return(req_dry_run(req))
    }

    resp <- req_perform(req)

    if (resp_status(resp) < 200 || resp_status(resp) >= 300) {
      cli::cli_abort("API request failed with status {resp_status(resp)}")
    }

    body <- resp_body_json(resp)

    if (length(body) == 0) {
      return(tibble())
    }

    df <- body %>%
      map(~ map_if(.x, is.null, ~NA_character_)) %>%
      as_tibble()

    return(df)
  }

  cli::cli_abort("search_param must be either 'compound' or 'property'")
}

#' Get property IDs for property searching
#'
#' @return A list of IDs

.prop_ids <- function() {
  # Predicted properties
  req_pred <- request("https://api-ccte.epa.gov") %>%
    req_method("GET") %>%
    req_url_path_append("chemical/property/predicted/name") %>%
    req_headers(
      Accept = "application/json",
      `x-api-key` = ct_api_key()
    )

  resp_pred <- req_perform(req_pred)

  if (resp_status(resp_pred) < 200 || resp_status(resp_pred) >= 300) {
    cli::cli_abort("Failed to fetch predicted property names")
  }

  pred <- resp_body_json(resp_pred) %>%
    map(~ map_if(.x, is.null, ~NA_character_)) %>%
    as_tibble()

  # Experimental properties
  req_exp <- request("https://api-ccte.epa.gov") %>%
    req_method("GET") %>%
    req_url_path_append("chemical/property/experimental/name") %>%
    req_headers(
      Accept = "application/json",
      `x-api-key` = ct_api_key()
    )

  resp_exp <- req_perform(req_exp)

  if (resp_status(resp_exp) < 200 || resp_status(resp_exp) >= 300) {
    cli::cli_abort("Failed to fetch experimental property names")
  }

  exp <- resp_body_json(resp_exp) %>%
    map(~ map_if(.x, is.null, ~NA_character_)) %>%
    as_tibble()

  df <- bind_rows(pred, exp) %>% distinct(name, propertyId)

  return(df)
}
