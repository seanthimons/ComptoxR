# Phase 37: Build & Patch Integration - Research

**Researched:** 2026-04-28
**Phase:** 37 - Build & Patch Integration
**Goal:** Plan build-script and in-place patch integration so both paths produce the correct ECOTOX lifestage tables with deterministic refresh behavior, Windows-safe DuckDB write handling, and patch metadata.

## Research Question

What do we need to know to plan Phase 37 well?

The implementation is mostly present. The phase is an integration-hardening pass over `R/eco_lifestage_patch.R`, section 16 in both ECOTOX build scripts, and `tests/testthat/test-eco_lifestage_gate.R`. The highest-value plan is not a broad rewrite. It should lock the intended behavior with targeted tests, then make small changes where the current code diverges from Phase 37 decisions.

## Current State

Relevant code and artifacts:

- `R/eco_lifestage_patch.R` owns the source-backed lifestage helper layer, `.eco_lifestage_materialize_tables()`, `.eco_lifestage_load_seed_cache()`, and `.eco_patch_lifestage()`.
- `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` already have character-identical section 16 blocks that source or import `.eco_lifestage_release_id()` and `.eco_lifestage_materialize_tables()`, read distinct `lifestage_codes.description`, materialize tables, and write `lifestage_dictionary` and `lifestage_review`.
- `tests/testthat/test-eco_lifestage_gate.R` already contains temporary DuckDB helpers, cache/baseline/live patch tests, metadata-key presence checks, runtime-read checks, and the section 16 identity test.
- Phase 36.2 completed semantic adjudication and intentionally left `needs_context_aware_derivation` rows as non-blocking review handoff rows. Phase 37 should wire build and patch behavior, not reopen ontology expansion or semantic policy.

Current divergences from Phase 37 decisions:

- `.eco_patch_lifestage()` calls `.eco_close_con()` once, then attempts one `DBI::dbConnect(..., read_only = FALSE)` and aborts immediately on failure. It does not yet implement the required 3-attempt / 200 ms retry loop.
- `.eco_lifestage_load_seed_cache()` currently treats `force = TRUE` for strict `cache` and `baseline` modes as a fallback to `auto`. Phase 37 context says force should mean forced live lookup.
- `refresh = "auto"` can still reach live provider resolution if local seed rows are missing. Phase 37 context requires normal cold-start patching to be deterministic and local-artifact based; live lookup should be explicit through `refresh = "live"` or `force = TRUE`.
- Metadata tests currently assert key presence, but they do not fully validate non-empty values, replacement of prior `lifestage_patch_*` rows, actual refresh method, installed release, and package version.

## Key Planning Findings

1. One plan is enough. The roadmap calls for one plan, and all INTG requirements touch the same small integration surface.
2. Tests should lead the change. Existing test helpers make it cheap to add regression tests for retry behavior, refresh mode semantics, metadata replacement, and build-script sync.
3. The retry loop belongs around the close-then-connect boundary only. Once the read-write connection is valid, write failures should surface normally.
4. The retry loop should be isolated in a small internal helper so it is mockable without brittle manipulation of a real Windows file lock.
5. The implementation should not add new DESCRIPTION dependencies. Existing imports already cover DBI, duckdb, cli, tibble, dplyr, readr, purrr, rlang, and testthat usage.
6. Build-script section 16 should stay thin and identical. If helper signatures change, both scripts must be updated together and the existing character-identity test should remain the durable drift guard.
7. Phase 37 should avoid live provider calls in default verification. Network behavior belongs behind explicit `refresh = "live"` or `force = TRUE` and should be tested with mocks.

## Recommended Implementation Shape

Add or adjust tests in `tests/testthat/test-eco_lifestage_gate.R` before implementation:

- A mocked write-connection retry test where `DBI::dbConnect()` fails twice and succeeds on the third attempt. Assert three attempts and a successful patch.
- A failure test where all three write-open attempts fail and the error contains a patch-specific message plus the last DBI error.
- A deterministic `refresh = "auto"` test showing a matching baseline populates `lifestage_dictionary` without live provider calls when no user cache exists.
- A `refresh = "baseline"` release-mismatch test showing it aborts and does not call live providers.
- A `force = TRUE` test showing force routes through live provider lookup even if cache/baseline artifacts exist.
- Metadata validation asserting all four patch keys exist once, have non-empty values, and match the installed release, actual refresh method, and current package version.

Then implement:

- Add a small internal helper such as `.eco_lifestage_open_patch_connection(db_path, attempts = 3L, backoff = 0.2)` near `.eco_patch_lifestage()`.
- In each attempt, call `.eco_close_con()`, then try `DBI::dbConnect(duckdb::duckdb(), dbdir = db_path, read_only = FALSE)`.
- Sleep only between failed attempts.
- Abort after the final failure with a patch-specific message and the last DBI error.
- Update `.eco_lifestage_load_seed_cache()` and/or `.eco_lifestage_materialize_tables()` so `force = TRUE` uses live lookup, while ordinary `auto` does not silently call live providers when local artifacts are the expected source.
- Keep table writes and metadata writes outside the retry loop.

## Validation Architecture

Primary validation commands:

- `Rscript -e "devtools::test(filter='eco_lifestage_gate')"`
- `Rscript -e "contents <- paste(readLines('data-raw/ecotox.R', warn = FALSE), collapse = '\n'); installed <- paste(readLines('inst/ecotox/ecotox_build.R', warn = FALSE), collapse = '\n'); rx <- '(?s)  # 16\\\\. Lifestage dictionary ---------------------------------------------------.*?  # 17\\\\. Effects super-group ----------------------------------------------------'; stopifnot(identical(regmatches(contents, regexpr(rx, contents, perl = TRUE)), regmatches(installed, regexpr(rx, installed, perl = TRUE)))); cat('PASS\n')"`

Acceptance checks:

- Section 16 remains character-identical between `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R`.
- `.eco_patch_lifestage(refresh = "auto")` uses cache or matching baseline deterministically in normal local patching tests and does not call live providers.
- `.eco_patch_lifestage(refresh = "baseline")` requires matching baseline release and does not fall through to live providers.
- `.eco_patch_lifestage(..., force = TRUE)` is the explicit live-provider route and is tested with mocked providers.
- The write-open retry loop attempts exactly three close/connect cycles with 200 ms backoff between failed attempts.
- Patch metadata rows are complete, non-empty, replacement-style, and match the actual patch result.

## Risks And Pitfalls

- Do not treat ontology expansion as the next reflex; Phase 36.2 intentionally closed that loop for now.
- Do not simulate Windows lock contention with real flaky file locks. Mock the connect boundary and count attempts.
- Do not retry writes after a successful read-write connection. That would hide real data or schema errors.
- Do not let `auto` verification hit live providers because it will make local patching non-deterministic.
- Do not duplicate section 16 logic inline in both build scripts. Shared behavior belongs in package internals.
- Do not turn `.eco_patch_lifestage()` into a public exported API in this phase.

## RESEARCH COMPLETE
