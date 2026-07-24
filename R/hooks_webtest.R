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

  params$format <- "JSON"
  data$params <- params
  data
}

webtest_prediction_resolved_smiles <- function(item) {
  if (
    !is.list(item) ||
      !identical(toupper(as.character(item$result %||% "")), "FOUND") ||
      !is.list(item$chemical)
  ) {
    return(NULL)
  }

  canonical <- item$chemical$canonicalSmiles %||% item$chemical$smiles
  if (
    is.null(canonical) ||
      length(canonical) == 0 ||
      is.na(canonical[[1]]) ||
      !nzchar(canonical[[1]])
  ) {
    return(NULL)
  }

  as.character(canonical[[1]])
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
  input_name <- webtest_prediction_input_name(data$fn_name)
  inputs <- as.character(data$params[[input_name]])
  identifier_index <- which(vapply(inputs, looks_like_smiles_identifier, logical(1)))

  if (length(identifier_index) == 0) {
    return(data)
  }

  identifiers <- unique(inputs[identifier_index])
  resolved <- tryCatch(
    chemi_resolver_lookup_bulk(
      ids = identifiers,
      idsType = "AnyId",
      tidy = FALSE
    ),
    error = function(error) list()
  )

  resolved_smiles <- stats::setNames(
    lapply(seq_along(identifiers), function(index) {
      item <- webtest_prediction_resolver_item(
        resolved,
        identifiers[[index]],
        index
      )
      webtest_prediction_resolved_smiles(item)
    }),
    identifiers
  )
  unresolved <- identifiers[vapply(resolved_smiles, is.null, logical(1))]

  if (length(unresolved) > 0) {
    cli::cli_warn(
      c(
        "Unresolved WebTEST identifiers omitted.",
        "!" = "{paste(unresolved, collapse = ', ')}"
      ),
      class = "comptoxr_webtest_resolution_warning",
      identifiers = unresolved
    )
  }

  keep <- rep(TRUE, length(inputs))
  for (index in identifier_index) {
    canonical <- resolved_smiles[[inputs[[index]]]]
    if (is.null(canonical)) {
      keep[[index]] <- FALSE
    } else {
      inputs[[index]] <- canonical
    }
  }

  data$params[[input_name]] <- inputs[keep]
  if (!any(keep)) {
    data$skip_request <- TRUE
    data$result <- list()
  }
  data
}

webtest_prediction_has_error <- function(value) {
  is.list(value) &&
    any(c("error", "errorCode", "message") %in% names(value))
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

webtest_filter_prediction_methods <- function(predictions, requested_methods) {
  if (is.null(predictions) || is.null(requested_methods)) {
    return(predictions)
  }
  if (!is.list(predictions)) {
    stop("PredictionResult predicted values must be a list.", call. = FALSE)
  }

  keep <- vapply(
    predictions,
    function(prediction) {
      if (!is.list(prediction)) {
        stop("PredictionResult predicted values must contain lists.", call. = FALSE)
      }
      method <- prediction$method
      if (is.null(method) || length(method) != 1 || is.na(method)) {
        if (webtest_prediction_has_error(prediction)) {
          return(TRUE)
        }
        stop("PredictionResult predicted value is missing its method.", call. = FALSE)
      }
      tolower(as.character(method)) %in% requested_methods
    },
    logical(1)
  )

  predictions[keep]
}

webtest_filter_prediction_endpoint <- function(
  endpoint,
  requested_methods
) {
  if (!is.list(endpoint)) {
    stop("PredictionResult endpoints must contain lists.", call. = FALSE)
  }
  endpoint$predicted <- webtest_filter_prediction_methods(
    endpoint$predicted,
    requested_methods
  )
  endpoint
}

webtest_filter_prediction_chemical <- function(
  chemical,
  requested_endpoints,
  requested_methods
) {
  if (!is.list(chemical)) {
    stop("PredictionResult chemicals must contain lists.", call. = FALSE)
  }
  if (is.null(chemical$endpoints)) {
    if (webtest_prediction_has_error(chemical)) {
      return(chemical)
    }
    stop("PredictionResult chemical is missing endpoints.", call. = FALSE)
  }
  if (!is.list(chemical$endpoints)) {
    stop("PredictionResult chemical endpoints must be a list.", call. = FALSE)
  }

  keep <- vapply(
    chemical$endpoints,
    function(endpoint) {
      if (
        !is.list(endpoint) ||
          !is.list(endpoint$endpoint) ||
          is.null(endpoint$endpoint$id) ||
          length(endpoint$endpoint$id) != 1 ||
          is.na(endpoint$endpoint$id)
      ) {
        stop("PredictionResult endpoint is missing its endpoint id.", call. = FALSE)
      }
      tolower(as.character(endpoint$endpoint$id)) %in% requested_endpoints
    },
    logical(1)
  )

  chemical$endpoints <- lapply(
    chemical$endpoints[keep],
    webtest_filter_prediction_endpoint,
    requested_methods = requested_methods
  )
  chemical
}

#' Filter a WebTEST PredictionResult without reshaping it
#'
#' @param data Hook data with a generic-helper result and request parameters.
#' @return The filtered upstream result.
#' @noRd
filter_webtest_prediction_result <- function(data) {
  hook_name <- "filter_webtest_prediction_result"

  tryCatch(
    {
      located <- webtest_prediction_result_location(data$result)
      prediction_result <- located$result
      if (!is.list(prediction_result$chemicals)) {
        stop("PredictionResult chemicals must be a list.", call. = FALSE)
      }

      endpoints <- data$params$endpoint %||% data$params$endpoints
      methods <- data$params$method
      if (identical(data$fn_name, "chemi_webtest_predict_bulk")) {
        methods <- data$params$methods
      }
      requested_endpoints <- tolower(as.character(endpoints))
      requested_methods <- if (is.null(methods)) {
        NULL
      } else {
        tolower(as.character(methods))
      }

      prediction_result$chemicals <- lapply(
        prediction_result$chemicals,
        webtest_filter_prediction_chemical,
        requested_endpoints = requested_endpoints,
        requested_methods = requested_methods
      )

      if (isTRUE(located$wrapped)) {
        result <- data$result
        result[[1]] <- prediction_result
        result
      } else {
        prediction_result
      }
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
