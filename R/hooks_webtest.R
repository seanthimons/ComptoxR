# WebTEST Prediction Hook Primitives

webtest_prediction_abort <- function(
  data,
  hook_name,
  stage,
  message,
  parent = NULL
) {
  function_name <- data$fn_name %||% "<unknown>"
  stage_label <- gsub("_", "-", stage, fixed = TRUE)

  cli::cli_abort(
    c(
      "{.fn {function_name}} failed in WebTEST {stage_label} hook {.fn {hook_name}}.",
      "x" = message
    ),
    class = c(
      paste0("comptoxr_", stage, "_hook_error"),
      paste0("comptoxr_webtest_", stage, "_error"),
      "comptoxr_webtest_error"
    ),
    parent = parent,
    function_name = function_name,
    hook_name = hook_name,
    stage = stage
  )
}

webtest_prediction_input_name <- function(function_name) {
  if (identical(function_name, "chemi_webtest_predict")) {
    "smiles"
  } else if (identical(function_name, "chemi_webtest_predict_bulk")) {
    "structures"
  } else {
    stop("Unsupported WebTEST prediction function.", call. = FALSE)
  }
}

webtest_prediction_methods <- function() {
  c("consensus", "hc", "sm", "gc", "nn")
}

#' Validate a WebTEST prediction request
#'
#' @param data Hook data with prediction request parameters.
#' @return Hook data with normalized JSON format.
#' @noRd
validate_webtest_prediction_request <- function(data) {
  hook_name <- "validate_webtest_prediction_request"
  params <- data$params
  input_name <- webtest_prediction_input_name(data$fn_name)
  inputs <- params[[input_name]]
  is_bulk <- identical(data$fn_name, "chemi_webtest_predict_bulk")

  if (is.null(inputs) || length(inputs) == 0) {
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      paste0(input_name, " must contain at least one input.")
    )
  }
  if (!is_bulk && length(inputs) != 1) {
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      "smiles must contain exactly one input."
    )
  }

  endpoints <- if (is_bulk) params$endpoints else params$endpoint
  endpoint_name <- if (is_bulk) "endpoints" else "endpoint"
  invalid_endpoints <- !is.character(endpoints) ||
    length(endpoints) == 0 ||
    any(is.na(endpoints) | !nzchar(trimws(endpoints)))
  if (invalid_endpoints || (!is_bulk && length(endpoints) != 1)) {
    requirement <- if (is_bulk) {
      "must contain at least one non-empty string."
    } else {
      "must be one non-empty string."
    }
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      paste(endpoint_name, requirement)
    )
  }

  methods <- if (is_bulk) params$methods else params$method
  if (!is_bulk && (is.null(methods) || length(methods) != 1)) {
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      "method must be one supported WebTEST prediction method."
    )
  }
  if (!is.null(methods)) {
    invalid_methods <- !is.character(methods) ||
      any(is.na(methods) | !nzchar(trimws(methods))) ||
      !all(tolower(methods) %in% webtest_prediction_methods())
    if (invalid_methods) {
      webtest_prediction_abort(
        data,
        hook_name,
        "pre_request",
        paste0(
          "method must use consensus, hc, sm, gc, or nn; received ",
          paste(methods, collapse = ", "),
          "."
        )
      )
    }
  }

  format <- params$format
  if (
    !is.character(format) ||
      length(format) != 1 ||
      is.na(format) ||
      !identical(toupper(trimws(format)), "JSON")
  ) {
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      "format must be JSON."
    )
  }

  output <- params$output %||% c("wide", "raw")
  if (
    !is.character(output) ||
      length(output) == 0 ||
      anyNA(output) ||
      !output[[1]] %in% c("wide", "raw")
  ) {
    webtest_prediction_abort(
      data,
      hook_name,
      "pre_request",
      "output must be wide or raw."
    )
  }

  params$format <- "JSON"
  params$output <- match.arg(output, c("wide", "raw"))
  params$.inputs <- as.character(inputs)
  data$params <- params
  data
}

webtest_prediction_resolver_item <- function(resolved, identifier, index) {
  if (
    is.list(resolved) &&
      !is.null(names(resolved)) &&
      identifier %in% names(resolved)
  ) {
    return(resolved[[identifier]])
  }
  if (is.list(resolved) && length(resolved) >= index) {
    return(resolved[[index]])
  }
  NULL
}

#' Resolve identifier-like WebTEST prediction inputs
#'
#' @param data Hook data with scalar `smiles` or bulk `structures`.
#' @return Hook data with identifiers replaced by canonical SMILES.
#' @noRd
resolve_webtest_prediction_inputs <- function(data) {
  params <- data$params
  inputs <- params$.inputs
  input_map <- lapply(seq_along(inputs), function(index) {
    value <- inputs[[index]]
    missing <- is.na(value) || !nzchar(trimws(value))
    list(
      query = value,
      input_index = as.integer(index),
      request_value = if (missing) NA_character_ else value,
      sid = NA_character_,
      status = if (missing) "error" else "pending",
      error = if (missing) "Input is missing or empty." else NA_character_,
      resolved = FALSE
    )
  })
  resolve_index <- which(vapply(
    input_map,
    function(item) !is.na(item$query) && looks_like_smiles_identifier(item$query),
    logical(1)
  ))

  if (length(resolve_index) > 0) {
    identifiers <- unique(vapply(input_map[resolve_index], `[[`, character(1), "query"))
    resolved <- tryCatch(
      chemi_resolver_lookup_bulk(ids = identifiers, idsType = "AnyId", tidy = FALSE),
      error = function(error) error
    )
    unresolved <- character()

    for (index in resolve_index) {
      identifier <- input_map[[index]]$query
      item <- if (inherits(resolved, "error")) {
        NULL
      } else {
        webtest_prediction_resolver_item(resolved, identifier, match(identifier, identifiers))
      }
      smiles <- descriptor_resolved_smiles(item)
      if (is.na(smiles) || !nzchar(smiles)) {
        input_map[[index]]$request_value <- NA_character_
        input_map[[index]]$status <- "error"
        input_map[[index]]$error <- if (inherits(resolved, "error")) {
          paste0("Identifier resolution failed: ", conditionMessage(resolved))
        } else {
          paste0("Unable to resolve chemical identifier ", identifier, " to canonical SMILES.")
        }
        unresolved <- c(unresolved, identifier)
      } else {
        input_map[[index]]$request_value <- smiles
        input_map[[index]]$sid <- descriptor_resolved_sid(item)
        input_map[[index]]$resolved <- TRUE
      }
    }

    unresolved <- unique(unresolved)
    if (length(unresolved) > 0) {
      cli::cli_warn(
        c(
          "Unresolved WebTEST identifiers retained as error rows.",
          "!" = "{paste(unresolved, collapse = ', ')}"
        ),
        class = "comptoxr_webtest_resolution_warning",
        identifiers = unresolved
      )
    }
  }

  params$.input_map <- input_map
  params$.eligible_index <- which(vapply(
    input_map,
    function(item) identical(item$status, "pending"),
    logical(1)
  ))
  data$params <- params
  if (length(params$.eligible_index) == 0) {
    data$skip_request <- TRUE
    data$result <- list()
  }
  data
}

prepare_webtest_prediction_request <- function(data) {
  params <- data$params
  eligible <- params$.input_map[params$.eligible_index]
  structures <- vapply(eligible, `[[`, character(1), "request_value")
  endpoints <- params$endpoint %||% params$endpoints
  methods <- if (identical(data$fn_name, "chemi_webtest_predict")) {
    params$method
  } else {
    params$methods
  }
  data$request <- list(
    endpoint = "webtest/predict",
    server = descriptor_selected_server(),
    options = list(
      smiles = if (length(structures) > 0) structures[[1]] else NA_character_,
      endpoint = endpoints,
      method = methods,
      format = "JSON"
    ),
    body = list(
      structures = I(structures),
      endpoints = I(endpoints),
      methods = if (is.null(methods)) NULL else I(methods),
      format = "JSON"
    )
  )
  data
}

webtest_prediction_result_location <- function(result) {
  if (
    is.list(result) &&
      !is.null(names(result)) &&
      "chemicals" %in% names(result)
  ) {
    return(list(result = result, wrapped = FALSE))
  }

  if (
    is.list(result) &&
      length(result) == 1 &&
      is.list(result[[1]]) &&
      !is.null(names(result[[1]])) &&
      "chemicals" %in% names(result[[1]])
  ) {
    return(list(result = result[[1]], wrapped = TRUE))
  }

  stop("Response is not a WebTEST PredictionResult.", call. = FALSE)
}

webtest_prediction_raw <- function(data, prediction_result) {
  attr(prediction_result, "source_server") <- data$request$server
  attr(prediction_result, "source_endpoint") <- data$request$endpoint
  attr(prediction_result, "input_map") <- data$params$.input_map
  prediction_result
}

webtest_prediction_record_keys <- function(chemical) {
  if (!is.list(chemical)) {
    return(character())
  }
  values <- c(
    descriptor_scalar_chr(chemical$chemicalId),
    if (is.list(chemical$chemical)) descriptor_scalar_chr(chemical$chemical$sid) else NA_character_,
    if (is.list(chemical$chemical)) descriptor_scalar_chr(chemical$chemical$smiles) else NA_character_
  )
  unique(values[!is.na(values) & nzchar(values)])
}

webtest_prediction_map_chemicals <- function(chemicals, params) {
  eligible <- params$.eligible_index
  mapped <- stats::setNames(rep(list(NULL), length(params$.input_map)), as.character(seq_along(params$.input_map)))
  if (length(eligible) == 0) {
    return(mapped)
  }

  key_index <- list()
  for (record_index in seq_along(chemicals)) {
    for (key in webtest_prediction_record_keys(chemicals[[record_index]])) {
      if (is.null(key_index[[key]])) {
        key_index[[key]] <- record_index
      }
    }
  }
  equal_counts <- length(chemicals) == length(eligible)
  for (position in seq_along(eligible)) {
    input_index <- eligible[[position]]
    input <- params$.input_map[[input_index]]
    candidates <- unlist(
      key_index[unique(c(input$query, input$request_value, input$sid))],
      use.names = FALSE
    )
    record_index <- if (length(candidates) > 0) {
      candidates[[1]]
    } else if (equal_counts) {
      position
    } else {
      NA_integer_
    }
    if (!is.na(record_index) && record_index <= length(chemicals)) {
      mapped[[as.character(input_index)]] <- chemicals[[record_index]]
    }
  }
  mapped
}

webtest_prediction_row <- function(
  data,
  input,
  chemical = NULL,
  endpoint = NULL,
  prediction = NULL,
  error = NA_character_
) {
  resolved <- if (is.list(chemical$chemical)) chemical$chemical else list()
  metadata <- if (is.list(endpoint$endpoint)) endpoint$endpoint else list()
  list(
    query = input$query,
    input_index = input$input_index,
    status = if (is.na(error)) "ok" else "error",
    error = error,
    chemical_id = descriptor_scalar_chr(chemical$chemicalId, input$sid),
    sid = descriptor_scalar_chr(resolved$sid, input$sid),
    smiles = descriptor_scalar_chr(resolved$smiles, if (isTRUE(input$resolved)) input$request_value else NA_character_),
    inchi = descriptor_scalar_chr(resolved$inchi),
    inchi_key = descriptor_scalar_chr(resolved$inchiKey),
    endpoint_id = descriptor_scalar_chr(metadata$id),
    endpoint_name = descriptor_scalar_chr(metadata$name),
    units = descriptor_scalar_chr(metadata$units),
    log_units = descriptor_scalar_chr(metadata$logUnits),
    method = descriptor_scalar_chr(prediction$method),
    value = descriptor_scalar_num(prediction$value),
    log_value = descriptor_scalar_num(prediction$logValue),
    source_server = data$request$server,
    source_endpoint = data$request$endpoint
  )
}

webtest_prediction_wide <- function(data, prediction_result) {
  chemicals <- prediction_result$chemicals
  if (!is.list(chemicals)) {
    stop("PredictionResult chemicals must be a list.", call. = FALSE)
  }
  mapped <- webtest_prediction_map_chemicals(chemicals, data$params)
  requested_endpoints <- tolower(as.character(data$params$endpoint %||% data$params$endpoints))
  methods <- if (identical(data$fn_name, "chemi_webtest_predict_bulk")) {
    data$params$methods
  } else {
    data$params$method
  }
  requested_methods <- if (is.null(methods)) NULL else tolower(as.character(methods))
  rows <- list()

  for (index in seq_along(data$params$.input_map)) {
    input <- data$params$.input_map[[index]]
    chemical <- mapped[[as.character(index)]]
    if (!identical(input$status, "pending")) {
      rows[[length(rows) + 1L]] <- webtest_prediction_row(data, input, error = input$error)
      next
    }
    if (is.null(chemical)) {
      rows[[length(rows) + 1L]] <- webtest_prediction_row(
        data,
        input,
        error = "No WebTEST prediction result was returned for this input."
      )
      next
    }
    embedded_error <- descriptor_error_text(chemical[c("error", "errorCode", "message")])
    if (!is.na(embedded_error)) {
      rows[[length(rows) + 1L]] <- webtest_prediction_row(data, input, chemical, error = embedded_error)
      next
    }
    if (!is.list(chemical$endpoints)) {
      stop("PredictionResult chemical endpoints must be a list.", call. = FALSE)
    }

    matched <- 0L
    for (endpoint in chemical$endpoints) {
      endpoint_id <- if (is.list(endpoint$endpoint)) descriptor_scalar_chr(endpoint$endpoint$id) else NA_character_
      if (is.na(endpoint_id)) {
        stop("PredictionResult endpoint is missing its endpoint id.", call. = FALSE)
      }
      if (!tolower(endpoint_id) %in% requested_endpoints) {
        next
      }
      if (!is.list(endpoint$predicted)) {
        stop("PredictionResult predicted values must be a list.", call. = FALSE)
      }
      for (prediction in endpoint$predicted) {
        method <- descriptor_scalar_chr(prediction$method)
        if (is.na(method)) {
          stop("PredictionResult predicted value is missing its method.", call. = FALSE)
        }
        if (!is.null(requested_methods) && !tolower(method) %in% requested_methods) {
          next
        }
        error <- descriptor_error_text(prediction[c("error", "errorCode", "message")])
        rows[[length(rows) + 1L]] <- webtest_prediction_row(
          data,
          input,
          chemical,
          endpoint,
          prediction,
          error
        )
        matched <- matched + 1L
      }
    }
    if (matched == 0L) {
      rows[[length(rows) + 1L]] <- webtest_prediction_row(
        data,
        input,
        chemical,
        error = "No requested WebTEST prediction was returned for this input."
      )
    }
  }

  tibble::as_tibble(do.call(rbind.data.frame, c(rows, list(stringsAsFactors = FALSE))))
}

#' Format a WebTEST PredictionResult
#'
#' @param data Hook data with a generic-helper result and complete request state.
#' @return A wide prediction tibble or the raw PredictionResult with provenance.
#' @noRd
filter_webtest_prediction_result <- function(data) {
  hook_name <- "filter_webtest_prediction_result"

  tryCatch(
    {
      if (isTRUE(data$skip_request)) {
        prediction_result <- list(chemicals = list())
      } else {
        prediction_result <- webtest_prediction_result_location(data$result)$result
      }
      if (identical(data$params$output, "raw")) {
        return(webtest_prediction_raw(data, prediction_result))
      }
      webtest_prediction_wide(data, prediction_result)
    },
    error = function(parent) {
      webtest_prediction_abort(
        data,
        hook_name,
        "post_response",
        "The WebTEST prediction response is malformed.",
        parent = parent
      )
    }
  )
}
