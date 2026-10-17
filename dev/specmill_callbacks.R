# Development callbacks only. Client helpers retain runtime policy.
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
