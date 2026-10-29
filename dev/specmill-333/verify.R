# Issue 333: opt-out adoption with no names, mappings or includes. A compliant endpoint is
# discovered, an excluded one stays excluded across schema changes, and a deferred failure
# recovers into a generated wrapper once its contract is repaired. Runs offline.
source('dev/install_specmill.R')
verify_specmill()
op <- function(id, ok = TRUE, params = list()) {
  list(operationId = id, summary = id, parameters = params,
    responses = list(`200` = if (ok) list(description = 'ok') else setNames(list(), character())))
}
schema <- function(paths) {
  jsonlite::toJSON(list(swagger = '2.0', info = list(title = 'demo', version = '1'),
    host = 'example.test', schemes = list('https'), paths = paths), auto_unbox = TRUE, null = 'null')
}
write_schema <- function(root, paths) writeLines(schema(paths), file.path(root, 'schema/demo.json'))
generate <- function(root, mode, deferrals = NULL) {
  specmill::generate_client(root, config = 'specmill.yml', mode = mode, deferrals = deferrals,
    artifacts = 'wrappers')
}
state <- function(plan, id) plan$deferrals[[id]]$state
hash <- function(root, file) digest::digest(file = file.path(root, file), algo = 'sha256')

root <- tempfile('opt-out-')
for (d in c('R', 'apis', 'schema')) dir.create(file.path(root, d), recursive = TRUE)
writeLines(c('Package: demo', 'Version: 0.0.1', 'Title: Demo', 'Description: Demo.', 'License: MIT'),
  file.path(root, 'DESCRIPTION'))
writeLines('demo_request <- function(...) NULL', file.path(root, 'R/demo_request.R'))
# Opt-out: no selection.include, no names, no operation mappings.
writeLines(c('config_version: 1', 'package: demo', 'selection:', '  methods: [GET, POST]',
  "  exclude: ['^/api/admin/']", 'services: [apis/demo.yml]'), file.path(root, 'specmill.yml'))
writeLines(c('id: demo', 'schemas:', '  files: [schema/demo.json]', 'helper: demo_request'),
  file.path(root, 'apis/demo.yml'))
bad <- 'demo GET /api/bad'

# 1. First discovery: a compliant endpoint is generated, an excluded one is not, and a
#    broken contract blocks until it is enrolled with a reviewed reason.
write_schema(root, list(
  `/api/ok` = list(get = op('getOk')),
  `/api/admin/secret` = list(get = op('getSecret')),
  `/api/bad` = list(get = op('getBad', ok = FALSE))))
blocked <- generate(root, 'plan')
stopifnot(length(blocked$diagnostics) > 0L)
reason <- c('demo GET /api/bad' = 'Response lacks a description')
generate(root, 'apply', list(enroll = reason))
stopifnot(file.exists(file.path(root, 'R/getOk.R')), !file.exists(file.path(root, 'R/getSecret.R')),
  !file.exists(file.path(root, 'R/getBad.R')))
kept <- hash(root, 'R/getOk.R')

# 2. Unchanged contract: the failure stays deferred and a repeat apply is a no-op.
again <- generate(root, 'plan')
stopifnot(identical(state(again, bad), 'deferred'), !length(again$diagnostics),
  all(vapply(again$files, `[[`, '', 'action') %in% c('unchanged', 'retained')))
generate(root, 'apply')
generate(root, 'check')

# 3. Schema update: the endpoint is repaired, the excluded one changes (still excluded) and a new
#    compliant endpoint appears. Both are generated or retried without any name or mapping.
write_schema(root, list(
  `/api/ok` = list(get = op('getOk')),
  `/api/admin/secret` = list(get = op('getSecret', params = list(list(name = 'q', `in` = 'query', type = 'string')))),
  `/api/bad` = list(get = op('getBad')),
  `/api/new` = list(get = op('getNew'))))
recovered <- generate(root, 'plan')
stopifnot(identical(state(recovered, bad), 'retry_recovered'))
generate(root, 'apply')
stopifnot(file.exists(file.path(root, 'R/getBad.R')), file.exists(file.path(root, 'R/getNew.R')),
  !file.exists(file.path(root, 'R/getSecret.R')), identical(kept, hash(root, 'R/getOk.R')))
manifest <- jsonlite::read_json(file.path(root, '.specmill/manifest.json'))
stopifnot(!length(manifest$deferrals))

# 4. Freshness and idempotence.
generate(root, 'check')
before <- vapply(list.files(file.path(root, 'R'), full.names = TRUE), digest::digest, '', file = TRUE)
generate(root, 'apply')
stopifnot(identical(before, vapply(list.files(file.path(root, 'R'), full.names = TRUE), digest::digest, '', file = TRUE)))
cat('Opt-out discovery, permanent exclusion, deferral recovery and idempotence pass.\n')
unlink(root, recursive = TRUE)
