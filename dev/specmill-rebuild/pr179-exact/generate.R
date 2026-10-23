folder <- 'dev/specmill-rebuild/pr179-exact'
cache <- Sys.getenv('PR179_CACHE', path.expand('~/.cache/comptoxr-pr179'))
.libPaths(c(file.path(cache, 'library'), .libPaths()))
stopifnot(as.character(packageVersion('specmill')) == '0.1.41')
work <- file.path(cache, 'project')
unlink(work, recursive = TRUE); dir.create(work, recursive = TRUE)
file.copy(c('R', 'schema', 'DESCRIPTION', 'NAMESPACE'), work, recursive = TRUE)
file.copy(file.path(folder, 'policy.R'), file.path(work, 'R/proof_policy.R'))
dir.create(file.path(work, '.specmill/helpers'), recursive = TRUE)
scaffold <- specmill:::request_helper_scaffold('.ct_request', 'https://example.invalid', NULL,
  'COMPTOXR_NATIVE_DRY_RUN', companions = c('batching', 'pagination'))
writeLines(scaffold$code, file.path(work, 'R/z_specmill_request.R'))
writeLines(scaffold$provenance, file.path(work, '.specmill/helpers/.ct_request.json'))
callbacks <- new.env(parent = baseenv()); sys.source('dev/specmill_callbacks.R', callbacks)
callbacks$proof_paging <- function(operation) quote(params[['all_pages']]())
callbacks$proof_pubchem_paging <- function(operation) quote(params[['all_pages']])
callbacks$proof_pubchem_max <- function(operation) quote(params[['max_pages']])
callbacks$proof_pubchem_body <- function(operation) quote(local({
  chemicals <- params[['chemicals']]
  if (!is.list(chemicals) || !length(chemicals)) {
    query <- unique(as.vector(params[['query']]))
    query <- query[!is.na(query) & query != '']
    if (!length(query)) cli::cli_abort('Either query or chemicals parameter must be provided.')
    chemicals <- lapply(query, function(id) list(sid = id))
  }
  options <- structure(list(), names = character())
  if (!is.null(params[['section']])) options$section <- params[['section']]
  list(chemicals = chemicals, options = options)
}))
ref <- function(...) list(from = list(...))
value <- function(x) list(value = x)
search <- yaml::read_yaml('apis/search-pilot.yml', handlers = list(seq = function(x) x))
op <- search$operations[[1]]
op$implementation <- 'generated'; op$helper <- '.ct_request'; op$specialization <- NULL
op$defer_inputs <- list('all_pages'); op$pre_params <- as.list(setdiff(names(op$inputs), 'all_pages'))
op$post_response_scope <- 'combined'; op$result_formatter <- 'proof_search_result'
args <- list(method = value('POST'), path = value('/search'), path_params = value(list()),
 query = value(list()), body = ref('hook_state', 'request', 'body'), body_media = value('application/json'),
 headers = value(list(Accept = 'application/json')), server = value(list(url = 'http://127.0.0.1:9')),
 server_resolver = value(list(name = '.ct_server_url', key = 'chemi_burl', relative = '/')),
 auth = value(list()), response_policy = value('proof_page_response'),
 request_controls = value(list(preserve_errors = TRUE)))
paging <- list(mode = 'offset', when = list(callback = 'proof_paging'), parameter = list('body', 'offset'),
 size_parameter = list('body', 'params', 'limit'), page_size = ref('hook_state', 'request', 'options', 'limit'),
 start = value(0), max_pages = 100, items = 'proof_page_items', completed = 'proof_page_done',
 advance = 'proof_page_advance', metadata = FALSE, error_policy = 'partial', warn_limits = FALSE,
 warn_errors = FALSE, stop_on_empty = FALSE)
op$request <- list(arguments = args, pagination = paging)
search$operations[[1]] <- op; search$helper <- '.ct_request'; search$contracts_file <- NULL
search$documentation <- FALSE; search$hook_config <- NULL
search$hooks <- list(chemi_search = list(pre_request = list('chemi_search_pre_request'), post_response = list('chemi_search_post_response')))
pub <- list(id = 'proof-pubchem', schemas = list(files = list('schema/chemi-resolver-prod.json')),
 selection = list(include = list('POST /api/resolver/getpubchemlist')), helper = '.ct_request', documentation = FALSE)
inputs <- list(query = list(type = 'any'), idType = list(type = 'any', default = 'AnyId'),
 section = list(type = 'any', default = NULL), all_pages = list(type = 'any', default = TRUE),
 max_pages = list(type = 'any', default = 100))
a <- args; a$path <- value('/resolver/getpubchemlist'); a$body <- list(callback = 'proof_pubchem_body')
p <- paging; p$when <- list(callback = 'proof_pubchem_paging'); p$max_pages <- list(callback = 'proof_pubchem_max')
p$size_parameter <- list('body', 'options', 'limit'); p$page_size <- value(100)
pub$operations <- setNames(list(list(name = 'chemi_resolver_getpubchemlist', file = 'R/chemi_resolver_getpubchemlist.R',
 implementation = 'generated', exclude_parameters = list('page','itemsPerPage','search','linkBy','report'),
 inputs = inputs, private_params = list(chemicals = NULL), request = list(arguments = a, pagination = p),
 result_formatter = 'proof_pubchem_result')), 'POST /api/resolver/getpubchemlist')
pub$hooks <- list(chemi_resolver_getpubchemlist = list(pre_request = list('resolve_query_to_chemical_records')))
yaml::write_yaml(search, file.path(work, 'search.yml')); yaml::write_yaml(pub, file.path(work, 'pubchem.yml'))
yaml::write_yaml(list(config_version = 1L, package = 'ComptoxR', services = list('search.yml','pubchem.yml')), file.path(work,'specmill.yml'))
unlink(file.path(work, c('R/chemi_search.R','R/chemi_resolver_getpubchemlist.R')))
run <- function(mode) specmill::generate_client(work, config = 'specmill.yml', callbacks = callbacks,
 mode = mode, artifacts = 'wrappers', validation = TRUE)
pub_error <- tryCatch(run('plan'), error = identity)
saveRDS(pub_error, file.path(folder, 'pubchem-dynamic-max-pages.rds'))
if (inherits(pub_error, 'error')) {
  message('PubChem exact contract rejected: ', conditionMessage(pub_error))
  pub$operations[[1]]$request$pagination$max_pages <- 100
  yaml::write_yaml(pub, file.path(work,'pubchem.yml'))
}
plan <- run('apply'); saveRDS(plan, file.path(folder,'generation.rds'))
print(plan)
fresh <- run('check'); saveRDS(fresh,file.path(folder,'freshness.rds')); print(fresh)
manifest <- jsonlite::read_json(file.path(work,'.specmill/manifest.json'))
stopifnot(all(vapply(names(manifest$files), function(path) identical(specmill:::output_hash(file.path(work,path)), manifest$files[[path]]$hash), logical(1))))
for (file in c('search.yml','pubchem.yml','specmill.yml','R/chemi_search.R','R/chemi_resolver_getpubchemlist.R'))
 file.copy(file.path(work,file), file.path(folder,basename(file)), overwrite = TRUE)
saveRDS(list(owners = length(manifest$files), helper = digest::digest(file = file.path(work,'R/z_specmill_request.R'), algo = 'sha256'),
 provenance = scaffold$provenance), file.path(folder,'ownership.rds'))
