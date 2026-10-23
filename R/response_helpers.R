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
  if (length(body_list) == 0) {
    return(tibble::tibble())
  }

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

    if (is.null(x) || length(x) == 0) {
      return(NULL)
    }

    # Primitive (non-list) value
    if (!is.list(x)) {
      row <- tibble::tibble(value = as.character(x))
      if (!is.null(q_attr)) {
        row <- dplyr::bind_cols(query = q_attr, row)
      }
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
    if (!is.null(q_attr)) {
      row <- dplyr::bind_cols(query = q_attr, row)
    }
    row
  })

  res <- purrr::list_rbind(rows, names_to = names_to)

  if (nrow(res) == 0) {
    return(tibble::tibble())
  }

  # Phase 2: Collapse list-columns into semicolon-separated strings
  list_cols <- names(res)[purrr::map_lgl(res, is.list)]
  if (length(list_cols) > 0) {
    res <- dplyr::mutate(
      res,
      dplyr::across(
        dplyr::all_of(list_cols),
        ~ purrr::map_chr(.x, function(val) {
          if (is.null(val) || length(val) == 0) {
            return(NA_character_)
          }
          paste(as.character(unlist(val)), collapse = "; ")
        })
      )
    )
  }

  # Phase 3: Type recovery on character columns
  if (type_convert) {
    res <- dplyr::mutate(
      res,
      dplyr::across(
        dplyr::where(is.character),
        ~ utils::type.convert(.x, as.is = TRUE)
      )
    )
  }

  res
}

# Check if an HTTP response represents a transient error worth retrying.
# Returns TRUE for 429 (rate-limited) and all 5xx (server errors).
# Used as the `is_transient` predicate for `httr2::req_retry()`.
# @noRd
is_transient_error <- function(resp) {
  status <- httr2::resp_status(resp)
  status == 429 || status >= 500
}

parse_delimited_response <- function(text, content_type) {
  if (!nzchar(text)) {
    return(data.frame())
  }
  separator <- if (
    grepl(
      "^(text/tab-separated-values|text/tsv)",
      content_type,
      ignore.case = TRUE
    )
  ) {
    "\t"
  } else {
    ","
  }
  utils::read.table(
    text = text,
    header = TRUE,
    sep = separator,
    quote = "\"",
    comment.char = "",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    fill = FALSE
  )
}

unwrap_collection_envelope <- function(body) {
  collection_fields <- c("results", "records", "data", "content")
  if (
    is.list(body) &&
      length(body) == 1L &&
      !is.null(names(body)) &&
      names(body)[[1]] %in% collection_fields &&
      is.list(body[[1]])
  ) {
    return(body[[1]])
  }
  body
}

# Preserve httr2 JSON errors and explicitly requested JSON when a server mislabels it.
.ct_response_json <- function(response) {
  .ct_request_decode(response, response_policy = function(response, context, decode) {
    if (grepl("(/json|\\+json)$", context$media) && httr2::resp_has_body(response)) {
      tryCatch(decode(check_status = FALSE), error = function(e) {
        httr2::resp_body_json(response, simplifyVector = FALSE)
      })
    } else {
      httr2::resp_body_json(response, simplifyVector = FALSE)
    }
  })
}

# Native strict CSV decoding is preferred; preserve legacy malformed-table errors.
.ct_response_delimited <- function(response, context, decode) {
  tryCatch(decode(format = "delimited", check_status = FALSE), error = function(e) {
    if (context$media %in% c("text/csv", "application/csv", "text/tab-separated-values", "text/tsv")) {
      parse_delimited_response(httr2::resp_body_string(response), context$media)
    } else {
      stop(e)
    }
  })
}
