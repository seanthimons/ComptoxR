# The corrected recursive route retains the old endpoint label in diagnostics.
recursive_facade_response <- function(operation) quote(function(response, context, decode) {
  .ct_collect_response(response, context, decode, length(id), 'stdizer/groups/recursive')
})

# Preserve existing facade payloads; repairing their schema mismatch is separate work.
legacy_chemi_facade_body <- function(operation) {
  primary <- switch(operation$name,
    chemi_resolver_resolve = 'mol', chemi_toxprints_assays_bulk = 'acl',
    chemi_toxprints_chemicals_categories = 'chemicals',
    chemi_toxprints_toxprints_categories = 'chemical', chemi_stdizer_records = 'full')
  fields <- setdiff(vapply(operation$parameters, `[[`, '', 'name'), primary)
  options <- as.call(c(list(quote(base::list)), stats::setNames(lapply(fields, function(field)
    call('[[', as.name('params'), field)), fields)))
  wrap <- !grepl('_categories$', operation$name)
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
