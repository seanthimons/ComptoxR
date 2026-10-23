ComptoxR PR345 https://github.com/seanthimons/ComptoxR/pull/345, exact released Specmill v0.1.41 `05862bee1804806cea157ff1962300d741516301`, git-archive SHA256 `70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.

Independent protocol gap for `pubchem_search`, `pubchem_properties`, `pubchem_synonyms` in their existing R files. These call GET/POST PUG REST cids, property, synonyms operations under `https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound`. No prior PubChem schema; separately reviewed six-operation source is `dev/specmill-pubchem/pubchem-reviewed.json`, derived from the verbatim official https://pubchem.ncbi.nlm.nih.gov/pcfe/docs/markdown/pug-rest.md. Requests are public reads/calculations, without credentials.

The existing `generic_pubchem_request` always installs `httr2::req_throttle(capacity = 4, fill_time_s = 1)` before performing each request. Released native scaffold never calls req_throttle. The released mapping's `request_controls` accepts only timeout, max_retries, retry_writes, retry_policy, preserve_errors. No supported throttle setting or request transformation preserves this behavior. PubChem requires clients to limit request rate. Cache support #174 alone is insufficient.

Minimal reproduction with the released emitter:
```r
specmill:::validate_settings(
  list(request_controls = list(throttle = list(capacity = 4L, fill_time_s = 1))),
  "PubChem")
# PubChem request_controls: unknown field throttle

s <- specmill:::request_helper_scaffold(".ct_request", "https://example.invalid", NULL,
  "COMPTOXR_NATIVE_DRY_RUN", companions = c("batching", "pagination"))
e <- new.env(parent = baseenv()); eval(parse(text = s$code), e)
r <- withr::with_options(list(comptoxr_native.dry_run = TRUE),
  e$.ct_request("GET", "/compound/name/{query}/cids/JSON", list(query = "aspirin"), list(), NULL,
    server = list(url = "https://pubchem.ncbi.nlm.nih.gov/rest/pug"),
    request_controls = list(timeout = Inf, max_retries = 3L, retry_writes = TRUE)))
names(r$policies) # retry policy present, no throttle_realm
```

The original request captured at httr2::req_perform has `throttle_realm` plus retry/error policy; the emitted native request has no throttle realm. Passing a throttle field directly to the native helper does not implement it either. Successful-response capture mocks apply the actual request error predicate; the separate retained contract suite uses real localhost HTTP and no execution mock. Seven independent live GET/form-POST controls succeeded against PubChem with positive envelopes.

Please add a declarative native throttle configuration that emits the real httr2 policy with preserved realm/capacity/fill time across requests and batches. Do not insert sleeps in client projections or require a patched helper/executor. Retaining the original wrappers until an official release supports this, alongside #174. No handwritten wrapper/helper or fake hook workaround.
