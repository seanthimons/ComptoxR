# Descriptor and WebTEST request hooks
#
# These wrappers have incompatible aggregate and dedicated service contracts.
# The transform hook keeps those contracts out of generated wrappers while the
# pre- and post-request chains keep validation, routing, recovery, and formatting
# independently testable.

descriptor_server_urls <- function() {
  c(
    production = "https://hcd.rtpnc.epa.gov/api",
    staging = "https://cim.sciencedataexperts.com/api",
    development = "https://cim-dev.sciencedataexperts.com/api"
  )
}

descriptor_selected_server <- function() {
  selected <- Sys.getenv("chemi_burl", unset = "")
  if (!nzchar(selected)) {
    selected <- descriptor_server_urls()[["production"]]
  }
  sub("/+$", "", selected)
}

descriptor_server_name <- function(url) {
  urls <- descriptor_server_urls()
  match_index <- match(sub("/+$", "", url), urls)
  if (is.na(match_index)) "custom" else names(urls)[[match_index]]
}

descriptor_scalar_chr <- function(x, default = NA_character_) {
  if (is.null(x) || length(x) == 0 || is.na(x[[1]])) {
    return(default)
  }
  as.character(x[[1]])
}

descriptor_scalar_num <- function(x, default = NA_real_) {
  if (is.null(x) || length(x) == 0 || is.na(x[[1]])) {
    return(default)
  }
  as.numeric(x[[1]])
}

descriptor_scalar_lgl <- function(x, default = NA) {
  if (is.null(x) || length(x) == 0 || is.na(x[[1]])) {
    return(default)
  }
  isTRUE(as.logical(x[[1]]))
}

descriptor_error_text <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(NA_character_)
  }
  if (is.list(x) && !is.null(names(x))) {
    parts <- unlist(x[c("code", "errorCode", "error", "message")], recursive = TRUE, use.names = FALSE)
  } else {
    parts <- unlist(x, recursive = TRUE, use.names = FALSE)
  }
  parts <- unique(as.character(parts[!is.na(parts) & nzchar(as.character(parts))]))
  if (length(parts) == 0) NA_character_ else paste(parts, collapse = ": ")
}

descriptor_validate_choice <- function(value, choices, arg) {
  value <- descriptor_scalar_chr(value)
  if (is.na(value) || !nzchar(value)) {
    cli::cli_abort("{.arg {arg}} must be a non-empty string.")
  }
  match_index <- match(tolower(value), tolower(choices))
  if (is.na(match_index)) {
    cli::cli_abort(
      "{.arg {arg}} must be one of {paste(choices, collapse = ', ')}; received {.val {value}}."
    )
  }
  choices[[match_index]]
}

descriptor_validate_logical <- function(value, arg) {
  if (length(value) != 1 || is.na(value) || !is.logical(value)) {
    cli::cli_abort("{.arg {arg}} must be one TRUE or FALSE value.")
  }
  value
}

descriptor_input_param <- function(fn_name) {
  switch(
    fn_name,
    chemi_descriptors = "smiles",
    chemi_descriptors_bulk = "query",
    chemi_padel = "smiles",
    chemi_padel_bulk = "query",
    chemi_rdkit = "smiles",
    chemi_rdkit_bulk = "chemicals",
    chemi_mordred = "smiles",
    chemi_mordred_bulk = "chemicals",
    chemi_webtest = "smiles",
    chemi_webtest_bulk = "query",
    chemi_webtest_predict = "smiles",
    chemi_webtest_predict_bulk = "structures",
    cli::cli_abort("Unknown descriptor wrapper {.fn {fn_name}}.")
  )
}

descriptor_is_bulk <- function(fn_name) {
  grepl("_bulk$", fn_name)
}

descriptor_engine <- function(fn_name, params) {
  switch(
    fn_name,
    chemi_descriptors = tolower(params$type),
    chemi_descriptors_bulk = tolower(params$type),
    chemi_padel = "padel",
    chemi_padel_bulk = "padel",
    chemi_rdkit = "rdkit",
    chemi_rdkit_bulk = "rdkit",
    chemi_mordred = "mordred",
    chemi_mordred_bulk = "mordred",
    chemi_webtest = "webtest",
    chemi_webtest_bulk = "webtest",
    NA_character_
  )
}

descriptor_validate_common_request <- function(data) {
  params <- data$params
  fn_name <- data$fn_name
  input_param <- descriptor_input_param(fn_name)
  inputs <- params[[input_param]]

  if (is.null(inputs) || length(inputs) == 0) {
    cli::cli_abort("{.arg {input_param}} must contain at least one input.")
  }
  if (!descriptor_is_bulk(fn_name) && length(inputs) != 1) {
    cli::cli_abort("{.arg {input_param}} must contain exactly one input.")
  }

  params$output <- match.arg(params$output %||% c("wide", "raw"), c("wide", "raw"))
  params$.inputs <- as.character(inputs)
  params$.input_param <- input_param

  if (fn_name %in% c("chemi_descriptors", "chemi_descriptors_bulk")) {
    params$type <- descriptor_validate_choice(
      params$type,
      c("padel", "rdkit", "mordred", "webtest"),
      "type"
    )
  }

  format_wrappers <- c("chemi_descriptors", "chemi_descriptors_bulk", "chemi_webtest_bulk")
  if (fn_name %in% format_wrappers) {
    params$format <- descriptor_validate_choice(
      params$format %||% "JSON",
      c("JSON", "CSV", "TSV"),
      "format"
    )
  } else {
    params$format <- "JSON"
  }

  if ("headers" %in% names(params)) {
    params$headers <- descriptor_validate_logical(params$headers %||% FALSE, "headers")
  }
  params$.request_headers <- identical(params$output, "wide") || isTRUE(params$headers)

  if (fn_name %in% c("chemi_descriptors_bulk", "chemi_webtest_bulk")) {
    params$chemIdType <- descriptor_validate_choice(
      params$chemIdType %||% "AnyId",
      c(
        "DTXSID",
        "DTXCID",
        "SMILES",
        "MOL",
        "CAS",
        "Name",
        "InChI",
        "InChIKey",
        "InChIKey_1",
        "AnyId"
      ),
      "chemIdType"
    )
  } else {
    params$chemIdType <- "AnyId"
  }

  if (fn_name %in% c("chemi_padel", "chemi_padel_bulk")) {
    params$x2d <- descriptor_validate_logical(params$x2d %||% TRUE, "x2d")
    params$x3d <- descriptor_validate_logical(params$x3d %||% FALSE, "x3d")
    params$fp <- descriptor_validate_logical(params$fp %||% FALSE, "fp")
  }

  if (fn_name %in% c("chemi_rdkit", "chemi_rdkit_bulk")) {
    options <- params$options %||% list()
    if (!is.list(options) || (length(options) > 0 && is.null(names(options)))) {
      cli::cli_abort("{.arg options} must be a named list.")
    }
    params$type <- params$type %||% options$type %||% "ecfp"
    params$radius <- params$radius %||% options$radius %||% 3L
    params$bits <- params$bits %||% options$bits %||% 1024L
    params$type <- descriptor_scalar_chr(params$type)
    if (is.na(params$type) || !nzchar(params$type)) {
      cli::cli_abort("{.arg type} must be a non-empty RDKit fingerprint type.")
    }
    params$radius <- as.integer(params$radius)
    params$bits <- as.integer(params$bits)
    if (length(params$radius) != 1 || is.na(params$radius) || params$radius < 0) {
      cli::cli_abort("{.arg radius} must be one non-negative integer.")
    }
    if (length(params$bits) != 1 || is.na(params$bits) || params$bits < 1) {
      cli::cli_abort("{.arg bits} must be one positive integer.")
    }
    options[c("type", "radius", "bits")] <- NULL
    params$.engine_options <- c(
      options,
      list(type = params$type, radius = params$radius, bits = params$bits)
    )
  }

  if (fn_name %in% c("chemi_mordred", "chemi_mordred_bulk")) {
    options <- params$options %||% list()
    if (!is.list(options) || (length(options) > 0 && is.null(names(options)))) {
      cli::cli_abort("{.arg options} must be a named list.")
    }
    params$headers <- params$headers %||% options$headers %||% FALSE
    params$inchi <- params$inchi %||% options$inchi %||% TRUE
    params$headers <- descriptor_validate_logical(params$headers, "headers")
    params$inchi <- descriptor_validate_logical(params$inchi, "inchi")
    params$.request_headers <- identical(params$output, "wide") || isTRUE(params$headers)
    options[c("headers", "inchi")] <- NULL
    params$.engine_options <- c(
      options,
      list(headers = params$.request_headers, inchi = params$inchi)
    )
  }

  data$params <- params
  data
}

validate_descriptor_request <- function(data) {
  descriptor_validate_common_request(data)
}

validate_webtest_prediction_request <- function(data) {
  params <- data$params
  fn_name <- data$fn_name
  input_param <- descriptor_input_param(fn_name)
  inputs <- params[[input_param]]

  if (is.null(inputs) || length(inputs) == 0) {
    cli::cli_abort("{.arg {input_param}} must contain at least one input.")
  }
  if (!descriptor_is_bulk(fn_name) && length(inputs) != 1) {
    cli::cli_abort("{.arg {input_param}} must contain exactly one input.")
  }

  endpoints <- params$endpoint %||% params$endpoints
  if (is.null(endpoints) || length(endpoints) == 0 || any(is.na(endpoints) | !nzchar(trimws(endpoints)))) {
    cli::cli_abort("{.arg endpoint} must identify at least one WebTEST endpoint.")
  }

  methods <- params$method %||% params$methods %||% "consensus"
  methods <- as.character(methods)
  allowed_methods <- c("consensus", "hc", "sm", "gc", "nn")
  invalid_methods <- setdiff(tolower(methods), allowed_methods)
  if (length(invalid_methods) > 0) {
    cli::cli_abort(
      "{.arg method} must use consensus, hc, sm, gc, or nn; received {paste(invalid_methods, collapse = ', ')}."
    )
  }

  params$output <- match.arg(params$output %||% c("wide", "raw"), c("wide", "raw"))
  params$format <- descriptor_validate_choice(
    params$format %||% "JSON",
    c("JSON", "HTML", "PDF"),
    "format"
  )
  if (!identical(params$format, "JSON") && identical(params$output, "wide")) {
    cli::cli_abort("Non-JSON WebTEST reports require {.code output = \"raw\"}.")
  }

  params$.inputs <- as.character(inputs)
  params$.input_param <- input_param
  params$.requested_endpoints <- as.character(endpoints)
  params$.requested_methods <- tolower(methods)
  params$chemIdType <- "AnyId"
  data$params <- params
  data
}

descriptor_found_record <- function(item) {
  is.list(item) &&
    identical(toupper(descriptor_scalar_chr(item$result, "")), "FOUND") &&
    is.list(item$chemical)
}

descriptor_resolved_smiles <- function(item) {
  if (!descriptor_found_record(item)) {
    return(NA_character_)
  }
  descriptor_scalar_chr(item$chemical$canonicalSmiles, descriptor_scalar_chr(item$chemical$smiles))
}

descriptor_resolved_sid <- function(item) {
  if (!descriptor_found_record(item)) {
    return(NA_character_)
  }
  descriptor_scalar_chr(
    item$chemical$sid,
    descriptor_scalar_chr(item$chemical$chemId, descriptor_scalar_chr(item$chemical$id))
  )
}

descriptor_should_resolve <- function(value, chem_id_type) {
  if (is.na(value) || !nzchar(trimws(value))) {
    return(FALSE)
  }
  if (chem_id_type %in% c("DTXSID", "DTXCID", "CAS")) {
    return(TRUE)
  }
  looks_like_smiles_identifier(value)
}

resolve_descriptor_inputs <- function(data) {
  params <- data$params
  inputs <- params$.inputs
  chem_id_type <- params$chemIdType %||% "AnyId"

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
    function(item) descriptor_should_resolve(item$query, chem_id_type),
    logical(1)
  ))

  if (length(resolve_index) > 0) {
    identifiers <- vapply(input_map[resolve_index], `[[`, character(1), "query")
    unique_identifiers <- unique(identifiers)
    lookup_type <- if (chem_id_type %in% c("DTXSID", "DTXCID", "CAS")) chem_id_type else "AnyId"
    resolved <- tryCatch(
      chemi_resolver_lookup_bulk(ids = unique_identifiers, idsType = lookup_type, tidy = FALSE),
      error = function(e) e
    )

    if (inherits(resolved, "error")) {
      for (index in resolve_index) {
        input_map[[index]]$request_value <- NA_character_
        input_map[[index]]$status <- "error"
        input_map[[index]]$error <- paste0("Identifier resolution failed: ", conditionMessage(resolved))
      }
    } else {
      by_identifier <- stats::setNames(vector("list", length(unique_identifiers)), unique_identifiers)
      for (i in seq_along(unique_identifiers)) {
        item <- if (length(resolved) >= i) resolved[[i]] else NULL
        by_identifier[[unique_identifiers[[i]]]] <- item
      }
      if (!is.null(names(resolved)) && any(nzchar(names(resolved)))) {
        for (name in intersect(names(resolved), unique_identifiers)) {
          by_identifier[[name]] <- resolved[[name]]
        }
      }

      for (index in resolve_index) {
        identifier <- input_map[[index]]$query
        item <- by_identifier[[identifier]]
        smiles <- descriptor_resolved_smiles(item)
        if (is.na(smiles) || !nzchar(smiles)) {
          input_map[[index]]$request_value <- NA_character_
          input_map[[index]]$status <- "error"
          input_map[[index]]$error <- paste0(
            "Unable to resolve chemical identifier ",
            identifier,
            " to canonical SMILES."
          )
        } else {
          input_map[[index]]$request_value <- smiles
          input_map[[index]]$sid <- descriptor_resolved_sid(item)
          input_map[[index]]$resolved <- TRUE
        }
      }
    }
  }

  params$.input_map <- input_map
  params$.eligible_index <- which(vapply(
    input_map,
    function(item) identical(item$status, "pending"),
    logical(1)
  ))
  data$params <- params
  data
}

resolve_webtest_prediction_inputs <- function(data) {
  resolve_descriptor_inputs(data)
}

route_descriptor_request <- function(data) {
  params <- data$params
  fn_name <- data$fn_name
  engine <- descriptor_engine(fn_name, params)
  selected_server <- descriptor_selected_server()
  selected_name <- descriptor_server_name(selected_server)
  route <- list(
    server = selected_server,
    endpoint = engine,
    mode = "dedicated",
    fallback_used = FALSE,
    fallback_reason = NA_character_,
    format = params$format
  )

  if (fn_name %in% c("chemi_descriptors", "chemi_descriptors_bulk")) {
    route$endpoint <- "descriptors"
    route$mode <- "aggregate"

    needs_wide_headers <- identical(params$output, "wide") || isTRUE(params$.request_headers)
    if (identical(engine, "mordred") && identical(selected_name, "production") && needs_wide_headers) {
      route$server <- descriptor_server_urls()[["staging"]]
      route$endpoint <- "mordred"
      route$mode <- "dedicated"
      route$format <- "JSON"
      route$fallback_used <- TRUE
      route$fallback_reason <- paste(
        "Production aggregate Mordred cannot return validated headers;",
        "using the staging dedicated Mordred service."
      )
    } else if (
      identical(engine, "rdkit") &&
        (selected_name %in%
          c("staging", "development") ||
          (identical(selected_name, "production") && needs_wide_headers))
    ) {
      route$endpoint <- "rdkit"
      route$mode <- "dedicated"
      route$format <- "JSON"
      route$fallback_used <- TRUE
      route$fallback_reason <- paste(
        "The selected aggregate RDKit route cannot provide a validated 1,024-bit header-bearing response;",
        "using its dedicated RDKit service."
      )
      params$.engine_options <- list(type = "ecfp", radius = 3L, bits = 1024L)
    }
  } else if (fn_name %in% c("chemi_mordred", "chemi_mordred_bulk") && identical(selected_name, "production")) {
    route$server <- descriptor_server_urls()[["staging"]]
    route$fallback_used <- TRUE
    route$fallback_reason <- paste(
      "Production dedicated Mordred is unavailable;",
      "using the staging dedicated Mordred service."
    )
  }

  if (isTRUE(route$fallback_used)) {
    cli::cli_warn(route$fallback_reason)
  }

  params$.route <- route
  data$params <- params
  data
}

route_webtest_prediction_request <- function(data) {
  data$params$.route <- list(
    server = descriptor_selected_server(),
    endpoint = "webtest/predict",
    mode = "dedicated",
    fallback_used = FALSE,
    fallback_reason = NA_character_,
    format = data$params$format
  )
  data
}

descriptor_padel_options <- function(params, post = FALSE) {
  if (isTRUE(post)) {
    list(
      compute2D = params$x2d,
      compute3D = params$x3d,
      computeFingerprints = params$fp,
      headers = params$.request_headers,
      timeout = params$timeout
    )
  } else {
    list(
      `2d` = params$x2d,
      `3d` = params$x3d,
      fp = params$fp,
      headers = params$.request_headers,
      timeout = params$timeout
    )
  }
}

descriptor_engine_options <- function(engine, params, post = FALSE) {
  options <- switch(
    engine,
    padel = descriptor_padel_options(params, post = post),
    rdkit = params$.engine_options %||%
      list(
        type = params$type %||% "ecfp",
        radius = params$radius %||% 3L,
        bits = params$bits %||% 1024L
      ),
    mordred = params$.engine_options %||%
      list(
        headers = params$.request_headers,
        inchi = params$inchi %||% TRUE
      ),
    webtest = list(headers = params$.request_headers),
    list(headers = params$.request_headers, timeout = params$timeout)
  )
  options[!vapply(options, is.null, logical(1))]
}

descriptor_request_chem_id_type <- function(params) {
  input_map <- params$.input_map[params$.eligible_index]
  all_resolved <- length(input_map) > 0 &&
    all(vapply(input_map, function(item) isTRUE(item$resolved), logical(1)))
  if (isTRUE(all_resolved) || identical(params$chemIdType, "SMILES")) {
    "SMILES"
  } else {
    params$chemIdType %||% "AnyId"
  }
}

descriptor_request_spec <- function(fn_name, params) {
  route <- params$.route
  engine <- descriptor_engine(fn_name, params)
  eligible_values <- vapply(
    params$.input_map[params$.eligible_index],
    `[[`,
    character(1),
    "request_value"
  )
  is_bulk <- descriptor_is_bulk(fn_name)
  spec <- c(
    route,
    list(
      fn_name = fn_name,
      engine = engine,
      method = if (is_bulk) "POST" else "GET",
      query = list(),
      body = NULL,
      requested_format = params$format
    )
  )

  if (identical(route$mode, "aggregate")) {
    if (is_bulk) {
      spec$body <- list(
        chemicals = I(eligible_values),
        chemIdType = descriptor_request_chem_id_type(params),
        format = route$format,
        options = descriptor_engine_options(engine, params, post = TRUE),
        type = engine
      )
    } else {
      spec$query <- c(
        list(
          smiles = eligible_values[[1]],
          type = engine,
          headers = params$.request_headers,
          format = route$format,
          timeout = params$timeout
        )
      )
      spec$query <- spec$query[!vapply(spec$query, is.null, logical(1))]
    }
  } else if (is_bulk) {
    spec$body <- list(
      chemicals = I(eligible_values),
      options = descriptor_engine_options(engine, params, post = TRUE)
    )
    if (identical(engine, "webtest")) {
      spec$body$chemIdType <- descriptor_request_chem_id_type(params)
      spec$body$format <- route$format
    }
  } else {
    spec$query <- c(
      list(smiles = eligible_values[[1]]),
      descriptor_engine_options(engine, params, post = FALSE)
    )
  }

  spec
}

webtest_prediction_request_spec <- function(fn_name, params) {
  route <- params$.route
  eligible_values <- vapply(
    params$.input_map[params$.eligible_index],
    `[[`,
    character(1),
    "request_value"
  )
  is_bulk <- descriptor_is_bulk(fn_name)
  spec <- c(
    route,
    list(
      fn_name = fn_name,
      engine = "webtest_predict",
      method = if (is_bulk) "POST" else "GET",
      query = list(),
      body = NULL,
      requested_format = params$format
    )
  )

  if (is_bulk) {
    spec$body <- list(
      structures = I(eligible_values),
      endpoints = I(params$.requested_endpoints),
      methods = I(params$.requested_methods),
      format = params$format
    )
  } else {
    spec$query <- list(
      smiles = eligible_values[[1]],
      endpoint = params$.requested_endpoints[[1]],
      method = params$.requested_methods[[1]],
      format = params$format
    )
  }
  spec
}

descriptor_accept_type <- function(format) {
  switch(
    toupper(format),
    CSV = "text/csv",
    TSV = "text/tab-separated-values",
    PDF = "application/pdf",
    HTML = "text/html",
    "application/json"
  )
}

descriptor_perform_request <- function(spec) {
  req <- httr2::request(spec$server) |>
    httr2::req_url_path_append(spec$endpoint) |>
    httr2::req_method(spec$method) |>
    httr2::req_headers(Accept = descriptor_accept_type(spec$format)) |>
    httr2::req_retry(max_tries = 3, is_transient = is_transient_error)

  if (identical(spec$method, "POST")) {
    req <- httr2::req_body_json(req, spec$body, auto_unbox = TRUE)
  } else if (length(spec$query) > 0) {
    req <- do.call(httr2::req_url_query, c(list(req), spec$query))
  }

  resp <- httr2::req_perform(
    httr2::req_error(req, is_error = function(resp) FALSE)
  )
  status <- httr2::resp_status(resp)
  content_type <- httr2::resp_header(resp, "content-type") %||% ""
  is_json <- grepl("json", content_type, ignore.case = TRUE) ||
    identical(toupper(spec$format), "JSON")

  body <- if (is_json) {
    tryCatch(
      httr2::resp_body_json(resp, simplifyVector = FALSE),
      error = function(e) structure(list(), parse_error = conditionMessage(e))
    )
  } else if (identical(toupper(spec$format), "PDF")) {
    httr2::resp_body_raw(resp)
  } else {
    httr2::resp_body_string(resp)
  }

  list(status = status, content_type = content_type, body = body)
}

descriptor_transform_request <- function(data, prediction = FALSE) {
  fn_name <- data$fn_name
  pre <- run_hook(fn_name, "pre_request", list(params = data$params))
  eligible <- pre$params$.eligible_index

  if (length(eligible) == 0) {
    spec <- if (prediction) {
      webtest_prediction_request_spec(fn_name, pre$params)
    } else {
      descriptor_request_spec(fn_name, pre$params)
    }
    response <- list(status = 200L, content_type = "application/json", body = list())
  } else {
    spec <- if (prediction) {
      webtest_prediction_request_spec(fn_name, pre$params)
    } else {
      descriptor_request_spec(fn_name, pre$params)
    }
    response <- tryCatch(
      descriptor_perform_request(spec),
      error = function(e) {
        list(
          status = NA_integer_,
          content_type = "",
          body = list(),
          request_error = conditionMessage(e)
        )
      }
    )
  }

  post <- run_hook(
    fn_name,
    "post_response",
    list(result = response, params = pre$params, request = spec)
  )
  post$result
}

descriptor_request_transform <- function(data) {
  descriptor_transform_request(data, prediction = FALSE)
}

webtest_prediction_request_transform <- function(data) {
  descriptor_transform_request(data, prediction = TRUE)
}

validate_descriptor_response <- function(data) {
  response <- data$result
  status <- response$status
  body <- response$body
  error <- response$request_error %||% NA_character_

  if (is.na(error) && (is.na(status) || status < 200 || status >= 300)) {
    embedded <- if (is.list(body)) {
      descriptor_error_text(body[c("error", "message", "status")])
    } else {
      NA_character_
    }
    error <- paste0(
      "Descriptor request failed",
      if (!is.na(status)) paste0(" with HTTP ", status) else "",
      if (!is.na(embedded)) paste0(": ", embedded) else "."
    )
  }

  parse_error <- attr(body, "parse_error")
  if (is.na(error) && !is.null(parse_error)) {
    error <- paste0("Unable to parse descriptor response: ", parse_error)
  }
  if (
    is.na(error) &&
      (is.null(body) ||
        length(body) == 0 ||
        (is.character(body) && length(body) == 1 && !nzchar(body)))
  ) {
    error <- "Descriptor service returned an empty response."
  }
  if (is.na(error) && is.list(body)) {
    embedded <- descriptor_error_text(body[c("error", "errors", "message")])
    if (!is.na(embedded) && is.null(body$chemicals)) {
      error <- paste0("Descriptor service returned an error: ", embedded)
    }
  }

  data$response_error <- error
  data
}

validate_webtest_prediction_response <- function(data) {
  validate_descriptor_response(data)
}

descriptor_parse_delimited <- function(text, format) {
  separator <- if (identical(toupper(format), "TSV")) "\t" else ","
  tryCatch(
    utils::read.table(
      text = text,
      header = TRUE,
      sep = separator,
      quote = "\"",
      comment.char = "",
      check.names = FALSE,
      stringsAsFactors = FALSE,
      fill = FALSE
    ),
    error = function(e) structure(data.frame(), parse_error = conditionMessage(e))
  )
}

descriptor_json_records <- function(body) {
  records <- body$chemicals %||% list()
  if (is.data.frame(records)) {
    records <- lapply(seq_len(nrow(records)), function(i) as.list(records[i, , drop = FALSE]))
  }
  if (
    is.list(records) &&
      length(records) > 0 &&
      !is.null(names(records)) &&
      any(c("ordinal", "id", "smiles", "descriptors") %in% names(records))
  ) {
    records <- list(records)
  }
  records
}

descriptor_delimited_records <- function(body, format) {
  table <- descriptor_parse_delimited(body, format)
  if (!is.null(attr(table, "parse_error"))) {
    return(list(records = list(), headers = character(), parse_error = attr(table, "parse_error")))
  }

  metadata_names <- c("ordinal", "id", "smiles", "inchi", "inchikey")
  descriptor_columns <- names(table)[!tolower(names(table)) %in% metadata_names]
  records <- lapply(seq_len(nrow(table)), function(i) {
    row <- table[i, , drop = FALSE]
    get_column <- function(name) {
      index <- match(tolower(name), tolower(names(row)))
      if (is.na(index)) NULL else row[[index]][[1]]
    }
    list(
      ordinal = get_column("ordinal"),
      id = get_column("id"),
      smiles = get_column("smiles"),
      inchi = get_column("inchi"),
      inchiKey = get_column("inchikey"),
      descriptors = unname(as.list(row[descriptor_columns]))
    )
  })
  list(records = records, headers = descriptor_columns, parse_error = NULL)
}

descriptor_rdkit_headers <- function(params, records) {
  bits <- params$bits %||% params$.engine_options$bits
  if (is.null(bits) || length(bits) == 0 || is.na(bits)) {
    lengths <- vapply(records, function(record) length(record$descriptors %||% list()), integer(1))
    bits <- if (length(lengths) == 0) 0L else max(lengths)
  }
  if (bits < 1) {
    return(character())
  }
  width <- max(4L, nchar(as.character(bits)))
  prefix <- tolower(params$.engine_options$type %||% params$type %||% "rdkit")
  sprintf(paste0(prefix, "_%0", width, "d"), seq_len(bits))
}

descriptor_response_records <- function(data) {
  format <- toupper(data$request$format)
  body <- data$result$body
  if (format %in% c("CSV", "TSV") && is.character(body)) {
    parsed <- descriptor_delimited_records(body, format)
    return(parsed)
  }
  list(
    records = descriptor_json_records(body),
    headers = as.character(unlist(body$headers %||% character(), use.names = FALSE)),
    parse_error = NULL
  )
}

recover_descriptor_rows <- function(data) {
  if (identical(data$params$output, "raw")) {
    return(data)
  }

  parsed <- descriptor_response_records(data)
  if (!is.null(parsed$parse_error) && is.na(data$response_error)) {
    data$response_error <- paste0("Unable to parse descriptor response: ", parsed$parse_error)
  }
  headers <- parsed$headers
  if (length(headers) == 0 && identical(descriptor_engine(data$fn_name, data$params), "rdkit")) {
    headers <- descriptor_rdkit_headers(data$params, parsed$records)
  }

  input_map <- data$params$.input_map
  eligible <- data$params$.eligible_index
  records <- parsed$records
  equal_counts <- length(records) == length(eligible)
  mapped <- stats::setNames(rep(list(NULL), length(input_map)), as.character(seq_along(input_map)))

  if (is.na(data$response_error)) {
    for (eligible_position in seq_along(eligible)) {
      input_index <- eligible[[eligible_position]]
      input_item <- input_map[[input_index]]

      candidate_indices <- which(vapply(
        records,
        function(record) {
          ordinal <- suppressWarnings(as.integer(descriptor_scalar_num(record$ordinal)))
          if (!is.na(ordinal)) {
            return(identical(ordinal + 1L, eligible_position))
          }
          identical(descriptor_scalar_chr(record$id), input_item$request_value) ||
            identical(descriptor_scalar_chr(record$smiles), input_item$request_value)
        },
        logical(1)
      ))
      if (length(candidate_indices) == 0 && equal_counts) {
        candidate_indices <- eligible_position
      }
      if (length(candidate_indices) > 0 && candidate_indices[[1]] <= length(records)) {
        mapped[[as.character(input_index)]] <- records[[candidate_indices[[1]]]]
      }
    }
  }

  data$descriptor_headers <- headers
  data$descriptor_records <- mapped
  data
}

add_descriptor_provenance <- function(data) {
  route <- data$params$.route
  data$provenance <- list(
    source_server = route$server,
    source_endpoint = route$endpoint,
    fallback_used = isTRUE(route$fallback_used)
  )
  data
}

descriptor_raw_result <- function(data) {
  result <- data$result$body
  if (is.null(result)) {
    result <- list()
  }
  attr(result, "source_server") <- data$provenance$source_server
  attr(result, "source_endpoint") <- data$provenance$source_endpoint
  attr(result, "fallback_used") <- data$provenance$fallback_used
  attr(result, "input_map") <- data$params$.input_map
  if (!is.na(data$response_error)) {
    attr(result, "response_error") <- data$response_error
  }
  result
}

descriptor_record_error <- function(record, headers) {
  embedded <- descriptor_error_text(record[c("error", "errors", "message")])
  descriptors <- record$descriptors %||% list()
  if (!is.na(embedded)) {
    return(embedded)
  }
  if (length(descriptors) == 0) {
    return("No descriptor values were returned for this input.")
  }
  if (length(headers) == 0) {
    return("Descriptor headers are missing; values were not paired.")
  }
  if (length(descriptors) != length(headers)) {
    return(paste0(
      "Descriptor header/value count mismatch (",
      length(headers),
      " headers, ",
      length(descriptors),
      " values); values were not paired."
    ))
  }
  NA_character_
}

format_descriptor_result <- function(data) {
  if (identical(data$params$output, "raw")) {
    data$result <- descriptor_raw_result(data)
    return(data)
  }

  headers <- data$descriptor_headers %||% character()
  fixed <- list(
    query = character(),
    input_index = integer(),
    status = character(),
    error = character(),
    smiles = character(),
    inchi = character(),
    inchi_key = character(),
    source_server = character(),
    source_endpoint = character(),
    fallback_used = logical()
  )
  descriptor_columns <- stats::setNames(rep(list(vector("list", 0)), length(headers)), headers)
  columns <- c(fixed, descriptor_columns)

  for (i in seq_along(data$params$.input_map)) {
    input <- data$params$.input_map[[i]]
    record <- data$descriptor_records[[as.character(i)]]
    row_error <- input$error
    if (identical(input$status, "pending")) {
      if (!is.na(data$response_error)) {
        row_error <- data$response_error
      } else if (is.null(record)) {
        row_error <- "No descriptor result was returned for this input."
      } else {
        row_error <- descriptor_record_error(record, headers)
      }
    }

    status <- if (is.na(row_error)) "ok" else "error"
    columns$query <- c(columns$query, input$query)
    columns$input_index <- c(columns$input_index, input$input_index)
    columns$status <- c(columns$status, status)
    columns$error <- c(columns$error, row_error)
    columns$smiles <- c(
      columns$smiles,
      if (is.null(record)) {
        if (isTRUE(input$resolved)) input$request_value else NA_character_
      } else {
        descriptor_scalar_chr(record$smiles, input$request_value)
      }
    )
    columns$inchi <- c(columns$inchi, if (is.null(record)) NA_character_ else descriptor_scalar_chr(record$inchi))
    columns$inchi_key <- c(
      columns$inchi_key,
      if (is.null(record)) NA_character_ else descriptor_scalar_chr(record$inchiKey)
    )
    columns$source_server <- c(columns$source_server, data$provenance$source_server)
    columns$source_endpoint <- c(columns$source_endpoint, data$provenance$source_endpoint)
    columns$fallback_used <- c(columns$fallback_used, data$provenance$fallback_used)

    descriptors <- if (!is.null(record) && is.na(row_error)) record$descriptors else NULL
    for (j in seq_along(headers)) {
      value <- if (is.null(descriptors)) NA else descriptors[[j]]
      columns[[10L + j]] <- c(columns[[10L + j]], list(value))
    }
  }

  for (j in seq_along(headers)) {
    values <- columns[[10L + j]]
    atomic <- tryCatch(unlist(values, recursive = FALSE, use.names = FALSE), error = function(e) NULL)
    if (!is.null(atomic) && length(atomic) == length(values)) {
      columns[[10L + j]] <- atomic
    }
  }

  data$result <- tibble::as_tibble(columns, .name_repair = "minimal")
  data
}

recover_webtest_prediction_rows <- function(data) {
  if (identical(data$params$output, "raw")) {
    return(data)
  }

  body <- data$result$body
  chemicals <- if (is.list(body)) body$chemicals %||% list() else list()
  if (
    is.list(chemicals) &&
      length(chemicals) > 0 &&
      !is.null(names(chemicals)) &&
      any(c("chemicalId", "chemical", "endpoints", "error") %in% names(chemicals))
  ) {
    chemicals <- list(chemicals)
  }

  input_map <- data$params$.input_map
  eligible <- data$params$.eligible_index
  mapped <- stats::setNames(rep(list(NULL), length(input_map)), as.character(seq_along(input_map)))
  equal_counts <- length(chemicals) == length(eligible)

  if (is.na(data$response_error)) {
    for (eligible_position in seq_along(eligible)) {
      input_index <- eligible[[eligible_position]]
      input <- input_map[[input_index]]
      candidate <- which(vapply(
        chemicals,
        function(chemical) {
          chemical_record <- chemical$chemical %||% list()
          if (!is.list(chemical_record)) {
            chemical_record <- list()
          }
          response_ids <- c(
            descriptor_scalar_chr(chemical$chemicalId),
            descriptor_scalar_chr(chemical_record$sid),
            descriptor_scalar_chr(chemical_record$id)
          )
          response_smiles <- descriptor_scalar_chr(chemical_record$smiles)
          (!is.na(input$sid) && input$sid %in% response_ids) ||
            identical(input$request_value, response_smiles)
        },
        logical(1)
      ))
      if (length(candidate) == 0 && equal_counts) {
        candidate <- eligible_position
      }
      if (length(candidate) > 0 && candidate[[1]] <= length(chemicals)) {
        mapped[[as.character(input_index)]] <- chemicals[[candidate[[1]]]]
      }
    }
  }

  data$prediction_records <- mapped
  data
}

add_webtest_prediction_provenance <- function(data) {
  add_descriptor_provenance(data)
}

webtest_prediction_error <- function(value) {
  descriptor_error_text(value[c("errorCode", "error", "message")])
}

webtest_prediction_row <- function(
  input,
  chemical = NULL,
  endpoint = NULL,
  prediction = NULL,
  error = NA_character_,
  provenance
) {
  chemical_record <- chemical$chemical %||% list()
  if (!is.list(chemical_record)) {
    chemical_record <- list()
  }
  endpoint_info <- endpoint$endpoint %||% list()
  experimental <- endpoint$experimental %||% list()
  if (
    is.list(experimental) &&
      !is.null(names(experimental)) &&
      any(c("value", "logValue", "error") %in% names(experimental))
  ) {
    experimental <- list(experimental)
  }
  experimental <- if (length(experimental) > 0) experimental[[1]] else list()
  prediction_error <- if (is.null(prediction)) NA_character_ else webtest_prediction_error(prediction)
  combined_error <- c(error, prediction_error)
  combined_error <- combined_error[!is.na(combined_error) & nzchar(combined_error)]
  combined_error <- if (length(combined_error) == 0) NA_character_ else paste(unique(combined_error), collapse = ": ")

  list(
    query = input$query,
    input_index = input$input_index,
    status = if (is.na(combined_error)) "ok" else "error",
    error = combined_error,
    chemical_id = descriptor_scalar_chr(
      chemical$chemicalId,
      descriptor_scalar_chr(chemical_record$sid, input$sid)
    ),
    smiles = descriptor_scalar_chr(chemical_record$smiles, input$request_value),
    inchi = descriptor_scalar_chr(chemical_record$inchi),
    inchi_key = descriptor_scalar_chr(chemical_record$inchiKey),
    endpoint = descriptor_scalar_chr(endpoint_info$id),
    endpoint_name = descriptor_scalar_chr(endpoint_info$name),
    method = if (is.null(prediction)) NA_character_ else descriptor_scalar_chr(prediction$method),
    predicted_value = if (is.null(prediction)) NA_real_ else descriptor_scalar_num(prediction$value),
    predicted_log_value = if (is.null(prediction)) NA_real_ else descriptor_scalar_num(prediction$logValue),
    predicted_active = if (is.null(prediction)) NA else descriptor_scalar_lgl(prediction$active),
    experimental_value = descriptor_scalar_num(experimental$value),
    experimental_log_value = descriptor_scalar_num(experimental$logValue),
    units = descriptor_scalar_chr(endpoint_info$units),
    log_units = descriptor_scalar_chr(endpoint_info$logUnits),
    source_server = provenance$source_server,
    source_endpoint = provenance$source_endpoint,
    fallback_used = provenance$fallback_used
  )
}

format_webtest_prediction_result <- function(data) {
  if (identical(data$params$output, "raw")) {
    data$result <- descriptor_raw_result(data)
    return(data)
  }

  requested_endpoints <- tolower(data$params$.requested_endpoints)
  requested_methods <- tolower(data$params$.requested_methods)
  rows <- list()

  add_row <- function(row) {
    rows[[length(rows) + 1L]] <<- row
  }

  for (i in seq_along(data$params$.input_map)) {
    input <- data$params$.input_map[[i]]
    chemical <- data$prediction_records[[as.character(i)]]
    input_error <- input$error
    if (identical(input$status, "pending") && !is.na(data$response_error)) {
      input_error <- data$response_error
    }
    if (identical(input$status, "pending") && is.null(chemical) && is.na(input_error)) {
      input_error <- "No WebTEST prediction result was returned for this input."
    }
    if (!is.na(input_error)) {
      add_row(webtest_prediction_row(input, error = input_error, provenance = data$provenance))
      next
    }

    chemical_error <- descriptor_error_text(chemical$error)
    if (!is.na(chemical_error)) {
      add_row(webtest_prediction_row(
        input,
        chemical = chemical,
        error = chemical_error,
        provenance = data$provenance
      ))
      next
    }

    endpoints <- chemical$endpoints %||% list()
    if (
      is.list(endpoints) &&
        !is.null(names(endpoints)) &&
        any(c("endpoint", "predicted", "experimental") %in% names(endpoints))
    ) {
      endpoints <- list(endpoints)
    }

    for (requested_endpoint in requested_endpoints) {
      endpoint_matches <- Filter(
        function(endpoint) {
          identical(tolower(descriptor_scalar_chr(endpoint$endpoint$id, "")), requested_endpoint)
        },
        endpoints
      )
      if (length(endpoint_matches) == 0) {
        add_row(webtest_prediction_row(
          input,
          chemical = chemical,
          error = paste0("Requested endpoint ", requested_endpoint, " was not returned."),
          provenance = data$provenance
        ))
        next
      }

      endpoint <- endpoint_matches[[1]]
      predictions <- endpoint$predicted %||% list()
      if (
        is.list(predictions) &&
          !is.null(names(predictions)) &&
          any(c("method", "value", "error") %in% names(predictions))
      ) {
        predictions <- list(predictions)
      }

      for (requested_method in requested_methods) {
        method_matches <- Filter(
          function(prediction) {
            identical(tolower(descriptor_scalar_chr(prediction$method, "")), requested_method)
          },
          predictions
        )
        if (length(method_matches) == 0) {
          add_row(webtest_prediction_row(
            input,
            chemical = chemical,
            endpoint = endpoint,
            error = paste0("Requested prediction method ", requested_method, " was not returned."),
            provenance = data$provenance
          ))
        } else {
          add_row(webtest_prediction_row(
            input,
            chemical = chemical,
            endpoint = endpoint,
            prediction = method_matches[[1]],
            provenance = data$provenance
          ))
        }
      }
    }
  }

  data$result <- tibble::as_tibble(dplyr::bind_rows(rows))
  data
}
