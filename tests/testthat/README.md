# Test policy: local databases, fixtures, and the offline/CRAN-safe lane

ComptoxR tests must pass with **no network, no API key, and no local database**
(the CRAN-safe lane). This note records how that is achieved so new tests follow
the same rules.

## Test lanes

| Lane | How it's selected | External access |
|------|-------------------|-----------------|
| CRAN-safe / offline | `COMPTOXR_CRAN_SAFE_TESTS=true`, or `NOT_CRAN` unset/≠`true` (the default) | none |
| Full / local dev | `NOT_CRAN=true` **and** the resource is present | network, keys, local DBs |

`comptoxr_cran_safe_tests()` (helper-api.R) is the single source of truth for
which lane is active.

## Local DuckDB databases (ECOTOX, ToxValDB)

These databases are large, built on demand (`eco_install()` / `toxval_install()`),
and are **never committed as fixtures**. Tests that need one skip when it is
absent:

```r
test_that("...", {
  skip_if_no_local_db("ecotox")   # or "toxval"
  ...
})
```

`skip_if_no_local_db()` (helper-api.R) wraps the older inline idiom
`skip_if_not(file.exists(eco_path()), "...")` — both are fine; prefer the helper
in new tests.

Why this is automatically offline-safe: in the CRAN-safe/CRAN-like lanes,
`setup.R` redirects `ComptoxR.{dsstox,ecotox,toxval}_path` to a missing temp
directory, so `file.exists(<db>_path())` is always `FALSE` and every DB-backed
test skips without touching disk state.

## Network / live-API tests

Gate anything hitting the network, secrets, or a running Plumber service:

```r
skip_if_cran_safe_external("reason")   # skips in the CRAN-safe lane
skip_if_offline()                      # also honours CRAN-safe, then checks connectivity
skip_if_no_key()                       # real ctx_api_key required
```

## Fixture policy (no live resource in CI-safe tests)

- **CompTox / cheminformatics HTTP** → `vcr` cassettes (see `helper-vcr.R`;
  record once against production, sanitize the API key to `<<<API_KEY>>>`).
- **Internal download/build/connection functions** → `testthat::local_mocked_bindings()`
  (see the `eco_install()` tests in `test-eco_connection.R`).
- **Local databases** → skip via `skip_if_no_local_db()`; do not synthesize a
  DuckDB fixture.

The rule of thumb: a test that cannot run offline must call a `skip_*()` guard as
its first line, so the CRAN-safe lane stays green with zero external dependencies.
