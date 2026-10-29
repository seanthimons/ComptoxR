# Development callbacks only. Client helpers retain runtime policy.
epi_batch_array <- function(operation) {
  substitute(.api_validation$body_value(
    base::list(base::Filter(base::Negate(base::is.null), params)), SCHEMA
  ), list(SCHEMA = operation$schema_body))
}

primary_query_response <- function(operation) {
  name <- regmatches(operation$path, regexpr("\\{[^}]+\\}", operation$path))
  name <- substring(name, 2L, nchar(name) - 1L)
  parameter <- Filter(function(parameter) identical(parameter$name, name), operation$parameters)
  stopifnot(length(parameter) == 1L)
  if (!is.null(parameter[[1L]]$public_name)) name <- parameter[[1L]]$public_name
  substitute(function(response, context, decode) {
    context$query <- params[[NAME]]
    POLICY(response, context, decode)
  }, list(NAME = name, POLICY = as.name(operation$response_policy)))
}

detail_batch_limit <- function(operation) {
  quote(as.numeric(Sys.getenv("batch_limit", "100")))
}

# Exact-value bulk searches use a larger fallback than detail requests.
search_equal_batch_limit <- function(operation) {
  quote(as.numeric(Sys.getenv("batch_limit", "1000")))
}

# Preserve the literal c(...) formals of retained match.arg interfaces.
# The toolkit's data-literal renderer otherwise wraps vectors in base::evalq().
preserve_choice_defaults <- function(operation) {
  operation$parameters <- lapply(operation$parameters, function(parameter) {
    value <- parameter$public_default
    if (is.atomic(value) && length(value) > 1L) {
      parameter$public_default <- as.call(c(list(as.name("c")), as.list(value)))
    }
    parameter
  })
  operation
}

descriptor_get_response <- function(operation) quote(function(response, context, decode) {
  .ct_static_json_result(response, context, decode, state$request$endpoint)
})

descriptor_post_response <- function(operation) quote(function(response, context, decode) {
  if (context$status >= 400L) decode()
  context$endpoint <- state$request$endpoint
  .ct_chemi_result(response, context, decode, tidy = FALSE)
})

# Preserve the client's non-NULL body-shape selection without adding schema type checks.
prediction_body <- function(operation) {
  shapes <- operation$schema_body$oneOf
  stopifnot(length(shapes) == 2L)
  present <- lapply(shapes, function(shape) {
    fields <- lapply(unlist(shape$required), function(name) call('[[', as.name('params'), name))
    call('all', call('!', call('vapply', as.call(c(list(as.name('list')), fields)),
      as.name('is.null'), quote(logical(1)))))
  })
  fields <- unique(unlist(lapply(shapes, function(shape) names(shape$properties))))
  # Public input order is also the original JSON field order.
  fields <- intersect(vapply(operation$parameters, `[[`, '', 'name'), fields)
  payload <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(name) {
    call('[[', as.name('params'), name)
  }), fields)))
  substitute(base::local({
    if (sum(c(A, B)) != 1L) cli::cli_abort('Supply exactly one supported request-body shape.')
    base::Filter(base::Negate(base::is.null), BODY)
  }), list(A = present[[1L]], B = present[[2L]], BODY = payload))
}

# Keep the GET mass-range sibling's optional end and vector coercion.
mass_range_path_params <- function(operation) {
  quote(c(end = params[["end"]]))
}

# Project classifier identifiers and nullable options into the reviewed chemical payload.
classifier_body <- function(operation) {
  fields <- intersect(vapply(operation$parameters, `[[`, '', 'name'), c('model', 'smiles'))
  options <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(name) {
    call('[[', as.name('params'), name)
  }), fields)))
  substitute(base::local({
    ids <- unique(as.vector(params[['chemicals']]))
    ids <- ids[!is.na(ids) & ids != '']
    if (!length(ids)) cli::cli_abort('Either query or chemicals parameter must be provided.')
    chemicals <- lapply(ids, function(id) base::list(sid = id))
    options <- Filter(Negate(is.null), OPTIONS)
    if (!length(options)) options <- structure(list(), names = character())
    if (WRAP) base::list(chemicals = chemicals, options = options) else chemicals
  }), list(OPTIONS = options, WRAP = !grepl('/ncc_cats$', operation$key)))
}

 amos_read_body <- function(operation) {
    primary <- operation$parameters[[1L]]$public_name
    if (is.null(primary))
        primary <- operation$parameters[[1L]]$name
    substitute(base::local({
        value <- params[[PRIMARY]]
        if (base::is.null(value) || !base::length(value)) cli::cli_abort("Either query or chemicals parameter must be provided.")
        if (base::is.atomic(value) && base::all(base::is.na(value) | value == "")) cli::cli_abort("Either query or chemicals parameter must be provided.")
        body <- base::Filter(base::Negate(base::is.null), params)
        .api_validation$body_value(body, SCHEMA)
    }), list(PRIMARY = primary, SCHEMA = operation$schema_body))
}
amos_read_response <- function(operation) {
    substitute(function(response, context, decode) {
        context$endpoint <- ENDPOINT
        .ct_amos_read_json(response, context, decode)
    }, list(ENDPOINT = sub("^/api/", "", operation$path)))
}

 amos_dtxsids_body <- function(operation) quote(base::local({
    ids <- unique(as.vector(params[["dtxsids"]]))
    ids <- ids[!is.na(ids) & ids != ""]
    if (!length(ids)) cli::cli_abort("Supply at least one DTXSID.")
    base::list(dtxsids = base::I(ids))
}))

amos_identifier_body <- function(operation) {
  field <- operation$parameters[[1L]]$public_name
  if (is.null(field)) field <- operation$parameters[[1L]]$name
  substitute(.api_validation$body_value(
    stats::setNames(base::list(params[[FIELD]]), FIELD), SCHEMA),
    list(FIELD = field, SCHEMA = operation$schema_body))
}

toxprint_response <- function(operation) quote(function(response, context, decode) {
    context$query <- params[["query"]]
    .ct_chemi_tidy(response, context, decode)
})

 reviewed_batch_response <- function(operation) quote(function(response, context, decode) {
    context$query <- params[["query"]]
    .ct_http_policy_ct_chemical_search_equal_bulk(response, context, decode)
})

 lookup_body <- function(operation) {
    quote(.ct_lookup_body(params))
}

 lookup_response <- function(operation) {
    quote(function(response, context, decode) {
        context$query <- params[["ids"]]
        context$endpoint <- "resolver/lookup"
        .ct_chemi_result(response, context, decode, tidy = params[["tidy"]]())
    })
}

 page_response_policy <- function(operation) {
    endpoint <- if (grepl("chet", operation$service))
        paste0("chet", operation$path)
    else sub("^/api/", "", operation$path)
    substitute(function(response, context, decode) {
        context$endpoint <- ENDPOINT
        if (all_pages) return(.ct_chemi_page(response, context, decode))
        context$query <- "_static_"
        .ct_keyset_manual(response, context, decode)
    }, list(ENDPOINT = endpoint))
}

 keyset_response <- function(operation) {
    manual_query <- if (operation$method == "GET")
        quote(params[["limit"]])
    else quote(NULL)
    substitute(function(response, context, decode) {
        context$endpoint <- ENDPOINT
        context$query <- QUERY
        if (all_pages) return(.ct_keyset_page(response, context, decode))
        .ct_keyset_manual(response, context, decode)
    }, list(QUERY = manual_query, ENDPOINT = sub("^/api/", "", sub("/{limit}", "/", operation$path, fixed = TRUE))))
}

 keyset_body <- function(operation) {
    quote(base::Filter(base::Negate(base::is.null), params[base::setdiff(base::names(params), "limit")]))
}

collected_response <- function(operation) {
    name <- regmatches(operation$path, regexpr("\\{[^}]+\\}", operation$path))
    name <- substring(name, 2L, nchar(name) - 1L)
    parameter <- Filter(function(parameter) identical(parameter$name, name), operation$parameters)
    stopifnot(length(parameter) == 1L)
    public <- if (is.null(parameter[[1L]]$public_name))
        name
    else parameter[[1L]]$public_name
    endpoint <- sub(paste0("{", name, "}"), "", sub("^/", "", sub("^/api/", "", operation$path)), fixed = TRUE)
    substitute(function(response, context, decode) {
        .ct_collect_response(response, context, decode, length(INPUT), ENDPOINT)
    }, list(INPUT = as.name(public), ENDPOINT = endpoint))
}

static_collected_response <- function(operation) {
    substitute(function(response, context, decode) {
        .ct_static_json_result(response, context, decode, ENDPOINT)
    }, list(ENDPOINT = sub("^/api/", "", operation$path)))
}

chet_image_response <- function(operation) quote(function(response, context, decode) {
    context$query <- params[["chemical_id"]]
    .ct_chet_image_result(response, context, decode)
})

chet_batch_body <- function(operation) quote(base::local({
    level <- params[["search_level"]]()
    ids <- .ct_toxprint_query(params[["dtxsids"]]())
    c(list(dtxsids = I(ids)), Filter(Negate(is.null), list(search_level = level)))
}))

chet_batch_response <- function(operation) quote(function(response, context, decode) {
    if (context$status >= 400L) decode()
    context$endpoint <- "chet/reaction/batchsearch"
    .ct_chemi_result(response, context, decode, tidy = FALSE)
})

amos_remaining_body <- function (operation)
{
    primary <- if (grepl("batch_search$", operation$path))
        "ids"
    else if (grepl("substances_for_ids", operation$path))
        "internal_id_list"
    else if (grepl("retrieve_", operation$path))
        "internal_ids"
    else NULL
    check <- if (is.null(primary))
        quote(NULL)
    else substitute(if (!length(params[[PRIMARY]])) cli::cli_abort("Supply at least one identifier."),
        list(PRIMARY = primary))
    validation <- if (is.null(operation$schema_body))
        quote(body)
    else substitute(.api_validation$body_value(body, SCHEMA), list(SCHEMA = operation$schema_body))
    substitute(base::local({
        CHECK
        body <- Filter(Negate(is.null), params[setdiff(names(params), "record_type")])
        for (field in intersect(names(body), c("ids", "internal_ids", "internal_id_list", "record_info_fields", "table_fields"))) body[[field]] <- as.list(body[[field]])
        body <- VALIDATE
        for (field in intersect(names(body), c("ids", "internal_ids", "internal_id_list", "record_info_fields",
            "table_fields"))) body[[field]] <- I(body[[field]])
        body
    }), list(CHECK = check, VALIDATE = validation))
}

amos_remaining_response <- function (operation)
substitute(function(response, context, decode) {
    if (context$status >= 400L) decode()
    context$endpoint <- ENDPOINT
    if (context$status < 200L || context$status >= 300L || grepl("(/json|\\+json)$", context$media)) return(.ct_chemi_result(response,
        context, decode, tidy = FALSE))
    observe_api_responses(list(response))
    decode()
}, list(ENDPOINT = sub("^/api/", "", operation$path)))

resolved_chemical_body <- function(operation) {
    schema <- operation$schema_body
    kind <- attr(schema$properties$chemicals$items, "specmill_id")
    stopifnot(kind %in% c("#/components/schemas/Chemical", "#/components/schemas/ChemicalRecord", "#/components/schemas/ResolvedChemical"))
    flat <- identical(kind, "#/components/schemas/Chemical")
    fields <- intersect(names(schema$properties), vapply(operation$parameters, function(p) if (is.null(p$public_name))
        p$name
    else p$public_name, ""))
    fields <- setdiff(fields, "chemicals")
    extra <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(name) {
        value <- call("[[", as.name("params"), name)
        if (name != "options") return(value)
        substitute(base::local({
            options <- VALUE
            if (is.null(options)) options <- structure(list(), names = character())
            .api_validation$body_value(options, SCHEMA)
        }), list(VALUE = value, SCHEMA = schema$properties$options))
    }), fields)))
    chemicals <- if (flat)
        quote(lapply(chemicals, function(record) if (is.list(record) && !is.null(record$chemical)) record$chemical else record))
    else quote(chemicals)
    build <- if (flat)
        quote(function(id) list(sid = id))
    else quote(function(id) list(chemical = list(sid = id)))
    substitute(base::local({
        chemicals <- params[["chemicals"]]
        if (!is.list(chemicals) || !length(chemicals)) chemicals <- lapply(.ct_toxprint_query(params[["query"]]),
            BUILD)
        c(list(chemicals = CHEMICALS), Filter(Negate(is.null), EXTRA))
    }), list(CHEMICALS = chemicals, BUILD = build, EXTRA = extra))
}

resolved_chemical_response <- function(operation) {
    substitute(function(response, context, decode) {
        if (context$status >= 400L) decode()
        context$endpoint <- ENDPOINT
        .ct_chemi_result(response, context, decode, tidy = FALSE)
    }, list(ENDPOINT = sub("^/api/", "", operation$path)))
}

similaritymap_query <- function(operation) quote(list(sort = if (!is.null(params[["sort"]])) tolower(as.character(params[["sort"]])) else NULL))

# Pure body projection, with the exact source schema embedded by official generation.
services_body <- function(operation) {
  substitute(.ct_services_body(params, SCHEMA), list(SCHEMA = operation$schema_body))
}

search_paging <- function(operation) quote(params[["all_pages"]]())

# Canonical ToxPrint bulk body, validated after each client-side input chunk.
toxprints_canonical_body <- function(operation) {
  substitute(.api_validation$body_value(
    base::list(chemicals = base::as.list(params$query)), SCHEMA),
    list(SCHEMA = operation$schema_body))
}

# Keep descriptor vectors intact instead of the legacy semicolon flattening.
toxprints_bulk_response <- function(operation) quote(function(response, context, decode) {
  observe_api_responses(list(response))
  body <- decode()
  records <- .ct_request_records(body, collection = 'chemicals', null_to_na = TRUE)
  records <- lapply(records, function(record) {
    record$info <- body$info
    record
  })
  .ct_request_table(records, build = function(records, ...) {
    purrr::list_rbind(lapply(records, function(record) {
      record$descriptors <- list(unlist(record$descriptors, use.names = FALSE))
      record$info <- list(record$info)
      tibble::as_tibble(record)
    }))
  })
})

# Pure schema-body projections for the remaining legacy public signatures.
remaining_facade_body <- function(operation) {
  primary <- switch(operation$path,
    '/api/resolver/safety-flags' = 'additionalProps',
    '/api/stdizer/groups' = 'acl',
    '/api/alerts/groups' = 'description')
  array <- identical(operation$path, '/api/resolver/safety-flags')
  schema <- if (array) operation$schema_body$items else operation$schema_body
  fields <- intersect(names(schema$properties), vapply(operation$parameters, `[[`, '', 'name'))
  fields <- c(setdiff(fields, primary), primary)
  body <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(field) as.call(list(call('[[', as.name('params'), field)))), fields)))
  substitute(base::local({
    body <- BODY
    value <- unique(as.vector(body[[PRIMARY]]))
    value <- value[!is.na(value) & value != '']
    if (!length(value)) cli::cli_abort('Either query or chemicals parameter must be provided.')
    body <- base::Filter(base::Negate(base::is.null), body)
    body <- .api_validation$body_value(body, SCHEMA)
    if (ARRAY) list(body) else body
  }), list(PRIMARY=primary, BODY=body, SCHEMA=schema, ARRAY=array))
}

# CheT search/page routes: append secondary path segments and collect per input.
chet_search_path <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  secondary <- operation$parameters[[2L]]$name
  endpoint <- sub('/\\{.*$', '', operation$path)
  substitute(base::local({
    req <- httr2::request(paste0('https://projection.invalid/api/chet', ENDPOINT, '/{', NAME, '}'))
    for (pp in c(params[[SECONDARY]]))
      req <- httr2::req_url_path_append(req, as.character(pp))
    substring(req$url, nchar('https://projection.invalid') + 1L)
  }), list(NAME = primary, SECONDARY = secondary, ENDPOINT = endpoint))
}
chet_search_response <- function(operation) {
  primary <- operation$parameters[[1L]]$name
  endpoint <- paste0('chet', sub('/\\{.*$', '/', operation$path))
  substitute(function(response, context, decode) {
    .ct_collect_response(response, context, decode, length(PRIMARY), ENDPOINT)
  }, list(PRIMARY = as.name(primary), ENDPOINT = endpoint))
}

# Preserve existing facade payloads; repairing their schema mismatch is separate work.
legacy_chemi_facade_body <- function(operation) {
  primary <- switch(operation$path,
    '/api/resolver/resolve' = 'mol', '/api/toxprints/assays' = 'acl',
    '/api/toxprints/chemicals_categories' = 'chemicals',
    '/api/toxprints/toxprints_categories' = 'chemical', '/api/stdizer/records' = 'full')
  fields <- setdiff(vapply(operation$parameters, `[[`, '', 'name'), primary)
  options <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(field)
    call('[[', as.name('params'), field)), fields)))
  wrap <- !grepl('_categories$', operation$path)
  substitute(base::local({
    options <- base::Filter(base::Negate(base::is.null), OPTIONS)
    ids <- unique(as.vector(params[[PRIMARY]]))
    ids <- ids[!is.na(ids) & ids != '']
    if (!length(ids)) cli::cli_abort('Either query or chemicals parameter must be provided.')
    if (!length(options)) options <- stats::setNames(list(), character())
    chemicals <- purrr::map(ids, function(id) stats::setNames(list(id), 'sid'))
    if (WRAP) list(chemicals = chemicals, options = options) else chemicals
  }), list(OPTIONS = options, PRIMARY = primary, WRAP = wrap))
}

legacy_chemi_facade_response <- function(operation) {
  substitute(function(response, context, decode) {
    if (context$status >= 400L) decode()
    context$endpoint <- ENDPOINT
    .ct_chemi_result(response, context, decode, tidy = FALSE)
  }, list(ENDPOINT = sub('^/api/', '', operation$path)))
}
