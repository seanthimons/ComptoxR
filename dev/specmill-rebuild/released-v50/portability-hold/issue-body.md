ComptoxR PR345 is blocked by a generator-provenance portability defect introduced with reviewed duplicate response ownership in PR184, now released in official Specmill 0.1.50. This is a follow-up to merged PR184, not a request to duplicate its implementation.

Affected wrapper: `chemi_alerts_render`, GET `/api/alerts/render`, declared by `schema/chemi-alerts-prod.json` and `schema/chemi-safety-prod.json`. The request is shared; the reviewed response owner selects the alerts PNG/SVG declaration while preserving both source contracts. `duplicate_response: {source: chemi-alerts-prod.json, reason: ...}` generates correct wrapper bytes, but `.specmill/manifest.json` stores absolute checkout paths under `files[['R/chemi_alerts_render.R']]$response_sources`. Moving a pristine generated checkout to a different directory makes validated freshness fail on that manifest alone. This prevents committing a reproducible generated ownership manifest for CI or other developers.

Verified official source/tag 064478735580b54a732e3859b066b317e72d53a1, archive SHA256 cb8e970df29086405206a21b8b591b848f434fbc0e78984233b0fc532c1f9deb, all 77 R/inst bytes match. This report uses the actual official installed package, unchanged schemas/runtime/helper and validation=TRUE. No HTTP calls are needed.

Minimal reproduction, based on the released `tests/duplicate-responses.R` fixture:

```r
base <- tempfile('ownership-relocation-')
dir.create(base)
a <- file.path(base, 'a'); b <- file.path(base, 'b')
dir.create(a)
fixture <- system.file('catalogue', package='specmill', mustWork=TRUE)
stopifnot(all(file.copy(list.files(fixture, full.names=TRUE), a, recursive=TRUE)))
write_schema <- function(name, media) {
  response <- setNames(list(list(schema=list(type='string'))), media)
  schema <- list(openapi='3.0.3', info=list(title='Render', version='1'),
    servers=list(list(url='https://render.invalid')),
    paths=list('/render'=list(get=list(operationId='render',
      responses=list('200'=list(description='OK', content=response))))))
  jsonlite::write_json(schema, file.path(a,name), auto_unbox=TRUE)
}
write_schema('alerts.json', 'image/png')
write_schema('safety.json', '*/*')
writeLines('api_request <- function(...) NULL', file.path(a,'R/request.R'))
writeLines(c('config_version: 1', 'services: [service.yml]'), file.path(a,'specmill.yml'))
writeLines(c('id: render',
  'schemas: {files: [safety.json, alerts.json]}',
  'helper: api_request', 'selection: {include: [GET /render]}',
  'operations:', '  GET /render:', '    duplicate_response:',
  '      source: alerts.json',
  '      reason: Reviewed response declaration for identical request'), file.path(a,'service.yml'))
specmill::generate_client(a, config='specmill.yml', mode='apply', validation=TRUE)
specmill::generate_client(a, config='specmill.yml', mode='check', validation=TRUE) # passes

dir.create(b)
stopifnot(all(file.copy(list.files(a, all.files=TRUE, no..=TRUE, full.names=TRUE), b, recursive=TRUE)))
specmill::generate_client(b, config='specmill.yml', mode='check', validation=TRUE)
# Error: Generated output is stale or protected; inspect plan: .specmill/manifest.json
```

The original manifest records `a/alerts.json` and `a/safety.json`; a plan/apply in `b` changes these to `b/alerts.json` and `b/safety.json`. The wrapper, source hashes, selection reason, response contracts and other ownership metadata are unchanged. The only desired write is `.specmill/manifest.json`. Removing only `response_sources` from before/after manifests makes the full manifests identical.

Expected: persist stable project-relative source identities in generated provenance, while retaining sufficient source hashes/response contracts and reviewed selection evidence. The public generation/check path must remain fresh after an unchanged checkout is copied or checked out elsewhere. Do not require a client manifest edit or validation bypass. Please add a cross-root regeneration regression, since same-root generation/check already passes.

ComptoxR cannot close its reproducible-adoption proof while this remains. Existing root runtime/schema data has not been patched.
