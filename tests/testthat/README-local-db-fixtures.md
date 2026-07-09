# Local-DB fixture policy and shared skip helpers

Companion to `README.md` (which defines the CRAN-safe test lane). This note is
the fixture-and-skip policy the DSS / ECOTOX / ToxVal / EPI / Plumber test
issues (#222-226) build on. Helpers live in `helper-local-db.R`.

## Where fixture DBs live and how they are generated

- Real local DBs (DSS, ECOTOX, ToxValDB DuckDBs) are **built on demand** by the
  package (`eco_install()`, `toxval_install()`, DSS build) into user cache paths,
  resolved via `getOption("ComptoxR.<name>_path")` (e.g. `eco_path()`,
  `toxval_path()`, `dss_path()`). They are large and are **never committed**.
- A test that needs a *tiny, real* DuckDB creates one at runtime with
  `local_temp_duckdb(tables, envir)`, which writes named data frames, then
  removes the file and closes the connection via `withr::defer()`. Nothing lands
  on disk after the test.

## Excluding large assets

- No `.duckdb` / `.sqlite` fixture is checked in. HTTP interactions use `vcr`
  cassettes (`fixtures/*.yml`); build/connection internals are mocked with
  `testthat::local_mocked_bindings()`.
- If a temp DB is needed, build it per-test (above) — never cache it in the repo.

## Temp-dir cleanup expectations

- Use `withr::local_tempfile()` / `withr::defer()` (as `local_temp_duckdb` does)
  so files and connections are torn down when the calling frame exits.
- Do not write into the repo tree or the package cache from tests.

## How service tests skip in CRAN-safe mode

Every test needing a local resource calls a `skip_*()` guard as its first line:

| Resource | Guard | Source |
|----------|-------|--------|
| Named option DB (ecotox, toxval) | `skip_if_no_local_db("ecotox")` | helper-api.R |
| DB by concrete path | `skip_if_no_local_db_at(path, label)` | helper-local-db.R |
| External executable | `skip_if_no_executable("cmd")` | helper-local-db.R |
| Live integration (Plumber, real DB round-trip) | `skip_if_integration_only()` | helper-local-db.R |
| Network / secrets / live API | `skip_if_cran_safe_external()`, `skip_if_offline()`, `skip_if_no_key()` | helper-api.R |

`skip_if_integration_only()` requires **both** `NOT_CRAN=true` (not the CRAN-safe
lane) and `COMPTOXR_RUN_INTEGRATION=true`; otherwise it skips. In the CRAN-safe
lane, `setup.R` points the option DB paths at a missing directory, so all
option-derived DB guards skip automatically without touching disk.
