While verifying ComptoxR PR345 with official Specmill 0.1.42, rebinding the grouped `R/chemi_toxprints_assays.R` file made the metadata test tooling discover the unchanged `chemi_toxprints_assays()` GET sibling. Its public mapping is GET `/api/toxprints/assays`, `schema/chemi-toxprints-prod.json`.

The supported native wrapper calls `.ct_request(method = 'GET', path = '/api/toxprints/assays', path_params = list(), query = list(category = NULL, label = NULL), ...)`. It does not pass `endpoint` or `operation`.

Using the released `specmill::bind_tools('test_inventory', ...)` and test-renderer/scaffold tools via ComptoxR's `dev/generate_tests.R --generate`, the generated metadata test correctly asserts method and path, then adds:

```r
expect_true('endpoint' %in% names(call) || 'operation' %in% names(call))
```

That assertion always fails for this native wrapper. Minimal wire-free demonstration:

```r
captured <- NULL
testthat::local_mocked_bindings(.ct_request = function(...) {
  captured <<- list(...)
  list()
}, .package = 'ComptoxR')
ComptoxR::chemi_toxprints_assays()
stopifnot(identical(captured$path, '/api/toxprints/assays'))
'endpoint' %in% names(captured) || 'operation' %in% names(captured)
# FALSE
```

Legacy generic helpers accept `endpoint`; the native helper accepts `method`/`path`. The metadata renderer should select the appropriate assertion by helper. The unchanged wrapper is already covered by ComptoxR's existing bespoke public-options suite, which asserts the native method/path/query/server. We are registering that suite rather than adopting a known false generated assertion, editing generated tests, patching a helper, or changing the wrapper API. No new public route or alias is added.

PR345: https://github.com/seanthimons/ComptoxR/pull/345
