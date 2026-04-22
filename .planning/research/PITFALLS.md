# Pitfalls Research

**Domain:** Ontology API resolution + DuckDB in-place patching + release-scoped caching in an existing R package
**Researched:** 2026-04-22
**Confidence:** HIGH

---

## Critical Pitfalls

### Pitfall 1: DuckDB Read-Only Handle Blocks Write Connection on Windows

**What goes wrong:**
`.eco_patch_lifestage()` calls `.eco_close_con()` to release the cached read-only connection, then immediately opens a read-write connection. On Windows, the OS file lock from the read-only connection can persist for a short window after `dbDisconnect(con, shutdown = TRUE)`, so the subsequent `dbConnect(..., read_only = FALSE)` throws `IO Error: Cannot open file ... used by another process`.

**Why it happens:**
DuckDB uses OS-level file locks. On Windows, `BufferedFileWriter` takes an exclusive lock every time it opens a file (GitHub issue #17418, May 2025). Even after `shutdown = TRUE`, the Windows handle release is not always synchronous — the lock may linger one OS tick. The problem is aggravated if the R session is running inside RStudio, which can hold implicit file handles through its environment pane.

**How to avoid:**
- In `.eco_patch_lifestage()`, after `.eco_close_con()`, wrap the `dbConnect(..., read_only = FALSE)` call in a retry loop with short back-off (e.g., 3 attempts × 200 ms sleep), not a bare `tryCatch`.
- Always call `DBI::dbDisconnect(con, shutdown = TRUE)` — not the default `dbDisconnect()` — to trigger WAL checkpoint and release the lock fully.
- Never open a read-write connection without first explicitly calling `.eco_close_con()`.
- Document in the patch function that callers should not hold active DuckDB connections.

**Warning signs:**
- `IO Error: Cannot open file ... used by another process` on the first `dbConnect` attempt in `.eco_patch_lifestage()`
- Error only appears on Windows, not macOS/Linux
- Error disappears if you wait a second and retry manually
- RStudio environment pane shows DBI connection objects that haven't been invalidated

**Phase to address:**
Shared helper layer phase — `.eco_patch_lifestage()` connection-open sequence must include retry logic from the start.

---

### Pitfall 2: Stale Cached Read-Only Connection Survives Patch

**What goes wrong:**
`.eco_patch_lifestage()` closes the cached connection, patches the DB, then returns. The caller or a subsequent `eco_results()` call invokes `.eco_get_con()`, which opens a new read-only connection. But if the internal cache slot `.ComptoxREnv$ecotox_db` was not cleared before the patch opened its write connection, and the write connection is still the last thing stored in that slot, the next `.eco_get_con()` call returns a read-write connection rather than opening a fresh read-only one — or, worse, returns an invalid connection that triggers a DBI error.

**Why it happens:**
`.eco_close_con()` sets `.ComptoxREnv$ecotox_db <- NULL`. If `.eco_patch_lifestage()` forgets the second `.eco_close_con()` call at the end (step 10 in the plan), the internal slot is empty but the file still has a lock from the write connection that `on.exit` closed. The next `.eco_get_con()` opens correctly. But if an error path bypasses `on.exit`, the slot is left with a closed-but-not-nulled reference, and `DBI::dbIsValid()` may return `FALSE` rather than throwing — silently returning a dead connection object.

**How to avoid:**
- Use `on.exit(.eco_close_con(), add = TRUE)` at the very start of `.eco_patch_lifestage()`, before opening the write connection. This ensures the session cache is always cleared even on error paths.
- Call `.eco_close_con()` again explicitly after `DBI::dbDisconnect(con, shutdown = TRUE)` to null the slot regardless of whether `on.exit` already ran.
- Test: after a successful patch, call `.eco_get_con()` and assert `DBI::dbIsValid()` returns `TRUE` and `DBI::dbGetQuery(con, "SELECT 1")` succeeds.

**Warning signs:**
- `eco_results()` silently returns 0 rows after a patch
- `DBI::dbIsValid(.ComptoxREnv$ecotox_db)` returns `FALSE` without error
- Queries after patching throw `Invalid connection` rather than running
- Second patch attempt fails with "file already open"

**Phase to address:**
Shared helper layer phase — connection lifecycle in `.eco_patch_lifestage()` must be fully specified in the first implementation.

---

### Pitfall 3: OLS4 Search Returns Out-of-Ontology Terms (local=true Ignored)

**What goes wrong:**
`.eco_lifestage_query_ols4()` searches with `ontology = "uberon"` but receives UBERON terms mixed with terms from imported ontologies like CL, GO, or BFO. These cross-ontology hits score above the true UBERON match, causing a term to resolve to the wrong ontology ID — or to "ambiguous" when it should resolve cleanly.

**Why it happens:**
OLS4 GitHub issue #623: the `local=true` query parameter (which limits results to the specified ontology only) is ignored. Queries against UBERON with `local=true` and `local=false` return identical result sets. The current implementation does not pass `local=true`, so it is already getting cross-ontology results — but the scoring layer may not filter them correctly if a CL or BFO term ranks higher than the correct UBERON term for a given query.

**How to avoid:**
- Filter `docs` in `.eco_lifestage_query_ols4()` by `ontology_name` or `obo_id` prefix: keep only rows where `obo_id` starts with the expected prefix (e.g., `"UBERON:"` for UBERON, `"PO:"` for PO).
- This is a post-filter on the response, independent of the `local` parameter bug.
- Add the filter before passing candidates to `.eco_lifestage_rank_candidates()`.

**Warning signs:**
- `source_term_id` values in the cache CSV contain prefixes other than `UBERON:` or `PO:` when querying those ontologies
- A lifestage term resolves to a CL (cell line) or GO (gene ontology) term
- `source_ontology` column says "UBERON" but `source_term_id` starts with "CL:" or "BFO:"

**Phase to address:**
Provider resolution phase — add prefix filter as a defense-in-depth measure regardless of OLS4 bug status.

---

### Pitfall 4: OLS4 Search Relevance Ranking Does Not Prioritize Exact Matches

**What goes wrong:**
OLS4 GitHub issue #860 (Feb 2025, closed with fix in PR #1138): the search API returns more-specific subclasses ranked above the exact parent concept. For a query like `"adult"`, OLS4 may rank `"adult organism stage"` (UBERON:0000113) below `"post-juvenile adult stage"` or a more specific term. The scoring layer in `.eco_lifestage_score_text()` relies on OLS4 returning the most relevant candidate in the top rows — if the exact match is buried at row 15 out of 25, it may be missed entirely.

**Why it happens:**
OLS4 uses Solr full-text search ranking, which boosts specificity. The fix was merged but whether it is deployed on the production instance at the time of implementation is not guaranteed — EBI deploys on their own schedule.

**How to avoid:**
- `.eco_lifestage_query_ols4()` already fetches `rows = 25`. Do not reduce this. The scoring layer must evaluate all 25 results, not just the first.
- `.eco_lifestage_rank_candidates()` already applies `.eco_lifestage_score_text()` across all candidates — this is the correct architecture. Do not short-circuit on the first candidate.
- Score all 25 OLS4 results before ranking; do not trust OLS4's native ordering as a proxy for relevance.

**Warning signs:**
- Exact lifestage label like `"Adult"` resolves to a specific sub-stage term instead of the parent
- The correct term ID appears in `lifestage_review` as ambiguous rather than in `lifestage_dictionary` as resolved
- Manually querying `https://www.ebi.ac.uk/ols4/api/search?q=adult&ontology=uberon&rows=25` shows the exact term is not in position 1

**Phase to address:**
Provider resolution phase — the current design of scoring all candidates is correct; verify it is not short-circuiting before writing tests.

---

### Pitfall 5: NVS SPARQL Endpoint Unavailability Silently Empties the Index

**What goes wrong:**
`.eco_lifestage_nvs_index()` makes a SPARQL POST to `https://vocab.nerc.ac.uk/sparql/sparql`. If the NVS endpoint is down or returns an unexpected content type, `httr2::resp_body_string()` may succeed (returning an HTML error page), and `jsonlite::fromJSON()` will throw a parse error. The current implementation aborts with `"NVS S11 lookup returned no concepts"` — but only if `bindings` is NULL or empty. An HTML error page parsed as string may not reach `fromJSON` at all, instead throwing a condition that propagates uncaught.

**Why it happens:**
The NVS SPARQL endpoint at BODC is a research infrastructure service without a published SLA. The ARGO monitoring probe (`ARGOeu/sdc-nerc-spqrql`) exists precisely because the endpoint has known availability concerns. An HTML 503 or maintenance page passes httr2's HTTP status check if the server returns 200 with an error body.

**How to avoid:**
- Wrap the entire NVS request in `tryCatch`, catching both HTTP errors and JSON parse errors. On failure, return an empty tibble with a `cli::cli_warn()` rather than aborting.
- When the NVS index is empty (0 rows), log a warning but allow OLS4-only resolution to proceed rather than aborting the entire patch.
- The session cache in `.ComptoxREnv$eco_lifestage_nvs_index` should only be written on a successful non-empty response. A failed or empty response must not overwrite a previously cached index.

**Warning signs:**
- All lifestage terms suddenly have no NVS candidates
- `source_provider` column in the cache contains only `"OLS4"` entries after a fresh live lookup
- `cli_warn` message about NVS during patch that was not present in earlier runs
- `jsonlite::fromJSON` error in stack trace during `.eco_lifestage_nvs_index()`

**Phase to address:**
Provider resolution phase — NVS query function must handle endpoint failures gracefully before the function is used in the patch path.

---

### Pitfall 6: Cross-Release Cache Contamination

**What goes wrong:**
A user runs `.eco_patch_lifestage(refresh = "cache")` against a DB with `ecotox_release = "2024-12"` but their user cache directory contains a file named `ecotox_lifestage_2024_12.csv` that was actually generated against a different DB build (same release identifier, different content). The cache validation in `.eco_lifestage_validate_cache()` passes because the `ecotox_release` column values match — but the `org_lifestage` terms in the cache do not match the current DB's `lifestage_codes.description` values.

**Why it happens:**
The release ID is derived from the ZIP filename (e.g., `ecotox_ascii_12_2024.zip` → `ecotox_ascii_12_2024`), not from a content hash. If the user downloaded two different ECOTOX builds that both produced the same release string, the cache file is the same path, and the second build silently uses the first build's resolution results. This is most likely when ECOTOX posts a corrected release with the same date code.

**How to avoid:**
- After loading the cache, validate that every `org_lifestage` value in the cache is present in the DB's current `lifestage_codes.description` set. Log a warning (not an abort) for any cache entries with no corresponding DB row.
- After patching, validate that every distinct `lifestage_codes.description` in the DB has a corresponding row in `lifestage_dictionary` or `lifestage_review`. Missing terms indicate the cache was stale.
- Document the release ID derivation so users understand it is not content-addressed.

**Warning signs:**
- `lifestage_dictionary` + `lifestage_review` row count after patch does not equal the count of distinct `lifestage_codes.description`
- Terms present in `lifestage_codes` but absent from both tables after patch
- `_metadata.lifestage_patch_method` shows `"cache"` but user reports unexpected classification for a known term

**Phase to address:**
In-place patch function phase — post-patch completeness check must be part of the patch function's success criteria.

---

### Pitfall 7: `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` Section 16 Drift

**What goes wrong:**
A developer modifies section 16 in one file but not the other. Both files are in version control and both are tested, but the test only runs one of them. After the next full ECOTOX build, the lifestage tables are built from the diverged version, producing different results than the patch path — which always uses the shared helper layer.

**Why it happens:**
Keeping two copies of the same logic synchronized is inherently fragile. The plan explicitly requires "both section 16 copies must remain identical after implementation" but provides no mechanical enforcement. A future contributor fixing a bug in `data-raw/ecotox.R` has no automated reminder to apply the same fix to `inst/ecotox/ecotox_build.R`.

**How to avoid:**
- Add a CI check (or a `devtools::check()` custom lint) that diffs the two section 16 blocks and fails if they diverge. Even a simple `diff` check in a GitHub Actions step is sufficient.
- Alternatively, factor section 16 into the shared helper layer completely so neither script contains the logic inline — both scripts just call `.eco_lifestage_materialize_tables()` with the same arguments, and section 16 becomes a 5-line call site in each.
- The current implementation already calls `.eco_lifestage_materialize_tables()` from section 16 — verify the call sites are identical and add the diff check.

**Warning signs:**
- Full-build lifestage tables differ from patch-produced tables for the same release
- Git blame shows section 16 in one file modified more recently than the other
- `diff data-raw/ecotox.R inst/ecotox/ecotox_build.R` produces section 16 differences
- A bug fix PR touches only one of the two files

**Phase to address:**
Build script integration phase — add the diff check to the verification step, not as a post-merge afterthought.

---

### Pitfall 8: Derivation Map Miss Sends Resolved Terms to Review

**What goes wrong:**
A term resolves cleanly to `UBERON:0000113` (adult) with `source_match_status = "resolved"`, but `lifestage_derivation.csv` has no row for `(UBERON, UBERON:0000113)`. Per the plan: "If a source-backed resolved row lacks a derivation mapping, it is quarantined as review data instead of entering `lifestage_dictionary`." The patch completes with a warning, but the caller of `eco_results()` sees a row with `source_match_status = "resolved"` that has no `harmonized_life_stage` — because the join to `lifestage_dictionary` found nothing for that term.

**Why it happens:**
The derivation map (`lifestage_derivation.csv`) is a manually curated file. It must be populated before the patch runs. If the committed baseline CSV covers 139 terms but the derivation map covers only 120, the 19 missing terms will always be quarantined — silently, with only a `cli_alert_warning()` count.

**How to avoid:**
- During the baseline CSV generation, cross-check every `resolved` entry against the derivation map and abort if any resolved term has no derivation row.
- The warning message from `.eco_lifestage_materialize_tables()` should print the specific `org_lifestage` terms that were quarantined due to missing derivation, not just the count.
- Before committing `lifestage_baseline.csv`, run a local patch against the current DB with `refresh = "baseline"` and assert that `nrow(lifestage_review) == 0` for expected-clean terms.

**Warning signs:**
- Patch completes but `nrow(lifestage_review) > 0` for terms that were previously in `lifestage_dictionary`
- `eco_results()` returns `NA` for `harmonized_life_stage` on terms that have `source_match_status = "resolved"`
- Warning: "X lifestage row(s) quarantined" after a patch where X was 0 in the previous run
- `lifestage_dictionary` row count is lower than expected after patch

**Phase to address:**
Bootstrap artifact phase (baseline CSV generation) and derivation map population — these must be built and cross-checked together.

---

### Pitfall 9: `system.file()` Returns Empty String for Missing Baseline

**What goes wrong:**
`.eco_lifestage_baseline_path()` calls `system.file("extdata", "ecotox", "lifestage_baseline.csv", package = "ComptoxR")`. If the file was not included in the built package (missing from `inst/extdata/ecotox/`), `system.file()` returns `""` — not an error. The function then tries the dev path `inst/extdata/ecotox/lifestage_baseline.csv`, which also doesn't exist, and finally aborts. But in a user's installed package, the abort message says "Committed lifestage baseline CSV not found" with no indication of what went wrong at install time.

**Why it happens:**
`system.file()` silently returns `""` for missing files unless `mustWork = TRUE` is set. Files under `inst/` are only included in the installed package if they were present at `R CMD build` time. A `.Rbuildignore` entry, a missing `inst/extdata/ecotox/` directory, or a forgotten `git add` will silently exclude the baseline from the installed package.

**How to avoid:**
- Use `system.file(..., mustWork = FALSE)` and check `nzchar()` explicitly — the current implementation does this correctly — but add a `cli::cli_abort()` message that includes the expected installed path so users can diagnose installation issues.
- In `devtools::check()` output, verify the baseline CSV appears in the installed package by checking `list.files(system.file("extdata", "ecotox", package = "ComptoxR"))`.
- Add `inst/extdata/ecotox/` to `.gitkeep` tracking so the directory is never accidentally absent from the repo.

**Warning signs:**
- `system.file("extdata", "ecotox", "lifestage_baseline.csv", package = "ComptoxR")` returns `""` in a freshly installed package
- `.eco_lifestage_baseline_path()` aborts in a user environment that does not have the dev tree
- `refresh = "baseline"` always falls through to `refresh = "auto"` with `force = TRUE` because baseline is never found

**Phase to address:**
Bootstrap artifact phase — verify the baseline CSV is included in `devtools::check()` output before committing.

---

### Pitfall 10: Windows Temp Path in R Network Calls During Live Lookup

**What goes wrong:**
On Windows, httr2 and jsonlite may use `tempdir()` internally for response buffering. If `tempdir()` resolves to a path with spaces (e.g., `C:\Users\John Smith\AppData\Local\Temp`) or to a network-mapped drive, the response buffer write can fail or R can segfault during `jsonlite::fromJSON()` on the buffered response.

**Why it happens:**
R on Windows has documented issues with temp paths containing spaces (known since at least 2019). The CLAUDE.md for this project explicitly notes: "R on Windows may segfault on network calls. If an R network fetch fails or segfaults, fall back to downloading via curl first." The live lookup path in `.eco_lifestage_query_ols4()` and `.eco_lifestage_nvs_index()` makes multiple sequential HTTP requests — increasing exposure to this failure mode.

**How to avoid:**
- The live lookup functions already use `httr2::req_perform() |> httr2::resp_body_string() |> jsonlite::fromJSON()` — this is the correct in-memory pipeline that avoids temp file writes.
- Do not switch to response body save-to-file patterns unless forced to by memory constraints.
- If a user reports segfaults during live lookup, the recovery is: download the OLS4 response via `curl`, save to a temp file using `tempfile()` (which uses R's `tempdir()`, not shell temp), and parse from the file.
- The cache/baseline modes avoid all network calls entirely — this is one reason those modes are preferable for CI.

**Warning signs:**
- Segfaults only occur on live lookup, not cache or baseline modes
- Segfaults correlate with Windows usernames containing spaces
- `tempdir()` in the user's session returns a path with spaces
- Error: `cannot open file '...' for writing`

**Phase to address:**
Provider resolution phase — document in `.eco_lifestage_query_ols4()` that it must not use temp files for response handling.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Using OLS4 native ranking order instead of scoring all results | Faster scoring logic | Misses exact match buried below specific subclasses (OLS4 issue #860) | Never — score all returned rows |
| Skipping prefix filter on OLS4 results | Fewer lines of code | Cross-ontology term IDs in lifestage_dictionary (CL:, BFO:, GO: in UBERON slot) | Never — filter by obo_id prefix |
| Single `.eco_close_con()` call before write | Simpler code | Windows file lock race condition on re-open | Never — use retry loop |
| Release ID from ZIP filename only | Simple derivation | Cache reuse across corrected builds with same date code | Acceptable if post-patch completeness check is in place |
| Keeping section 16 logic inline in both scripts | No refactor needed | Drift between build and patch paths | Never — call shared helper from both |
| Committing baseline CSV without cross-checking derivation map | Faster initial setup | Resolved terms quarantined silently at every patch | Never — cross-check before commit |
| NVS failure aborts the entire patch | Simpler error handling | Patch fails when NVS is temporarily down; OLS4-only resolution is viable fallback | Never — degrade gracefully to OLS4-only |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| OLS4 + ontology filter | Passing `local=true` and trusting it works | Post-filter by `obo_id` prefix after receiving results (OLS4 issue #623 — `local=true` is ignored) |
| OLS4 + scoring | Trusting rank position 1 is the exact match | Score all returned rows; exact match may be at position 15+ due to OLS4 relevance bug |
| NVS SPARQL + error handling | Letting JSON parse error propagate uncaught from HTML 503 body | Wrap in `tryCatch`; return empty tibble with warning on any failure |
| DuckDB read-write + Windows | Opening write connection immediately after `dbDisconnect` | Retry loop with 200 ms back-off; always `shutdown = TRUE` on disconnect |
| Cache + release ID | Assuming same release string = same content | Post-patch completeness check: every `lifestage_codes.description` must appear in dictionary or review |
| `system.file()` + baseline CSV | Trusting empty string return to be caught | Check `nzchar()` and abort with diagnostic path; verify file presence in `devtools::check()` |
| Derivation map + resolved terms | Building baseline before derivation map is complete | Cross-check resolved baseline entries against derivation map rows before committing either |
| Build scripts + shared helper | Calling shared helper differently from each script | Both section 16 call sites must be textually identical; enforce with CI diff check |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Per-term OLS4 requests for 139 terms | Live lookup takes 5–10 minutes; 139 sequential HTTP calls | Cache/baseline modes avoid all live calls; live mode is a one-time cost per release | Acceptable for live mode; CI must always use cache or baseline |
| NVS index fetched per term | 139 SPARQL calls to BODC | Session-level cache in `.ComptoxREnv$eco_lifestage_nvs_index` — fetch once, reuse | Currently handled correctly; do not remove the session cache |
| Scoring all 25 OLS4 results × 3 providers × 139 terms | Noticeable but not blocking (~40k string comparisons) | R vectorized string ops; acceptable cost | Only breaks at thousands of terms, not 139 |
| Reading derivation CSV on every patch | Minor I/O overhead | Acceptable; file is small | Not a real concern at current scale |

---

## "Looks Done But Isn't" Checklist

- [ ] **Patch function:** Closes read-only connection before opening write connection AND reopens read-only after patching — verify both `.eco_close_con()` calls are present
- [ ] **OLS4 query:** Results filtered by `obo_id` prefix to exclude cross-ontology hits — verify no `CL:`, `GO:`, or `BFO:` prefixes appear in a test result set
- [ ] **NVS query:** Wrapped in `tryCatch` that returns empty tibble with warning rather than aborting — verify behavior when endpoint is unreachable
- [ ] **Baseline CSV:** Every resolved entry has a matching row in `lifestage_derivation.csv` — verify cross-check passes before committing
- [ ] **Section 16 sync:** Both build scripts call shared helper identically — run `diff` and verify 0 differences in the section 16 call site
- [ ] **Post-patch completeness:** Row count in `lifestage_dictionary + lifestage_review` equals distinct `lifestage_codes.description` count — verify in test
- [ ] **Windows retry loop:** Write connection open includes retry logic — verify on Windows by simulating delayed lock release
- [ ] **`inst/extdata` inclusion:** `lifestage_baseline.csv` and `lifestage_derivation.csv` appear in `devtools::check()` installed file listing — verify before tagging release

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Windows write connection blocked | LOW | Retry automatically via loop in patch function; if still blocked, user must restart R session |
| Stale cache contamination | LOW | Delete cache file at `.eco_lifestage_cache_path(ecotox_release)`; re-run with `refresh = "live"` |
| Section 16 drift | MEDIUM | Diff both files; manually reconcile; add CI check to prevent recurrence |
| Derivation map miss | MEDIUM | Add missing rows to `lifestage_derivation.csv`; re-run patch with `refresh = "cache"` (no new live lookup needed) |
| Baseline CSV missing from installed package | HIGH | Reinstall package from source; add file to `inst/extdata/ecotox/`; rebuild |
| Cross-ontology term in dictionary | LOW | Delete user cache; re-run with `refresh = "live"` after adding prefix filter to query function |
| NVS unavailable during live lookup | LOW | Re-run with `refresh = "cache"` or `refresh = "baseline"` to bypass live lookup entirely |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Windows write-connection race | Shared helper layer (eco_lifestage_patch.R) | Test: patch succeeds on Windows without manual retry |
| Stale connection in cache slot | Shared helper layer (eco_lifestage_patch.R) | Test: `eco_results()` works immediately after patch |
| OLS4 cross-ontology hits | Provider resolution implementation | Assert: no non-UBERON prefixes in UBERON query results |
| OLS4 relevance ranking | Provider resolution implementation | Assert: scoring layer evaluates all 25 rows, not just position 1 |
| NVS endpoint failure | Provider resolution implementation | Test: `tryCatch` returns empty tibble when NVS URL unreachable |
| Cross-release cache contamination | In-place patch function | Test: post-patch row count == distinct lifestage_codes count |
| Build script drift | Build script integration phase | CI diff check: `diff` of section 16 in both scripts returns 0 |
| Derivation map miss | Bootstrap artifact phase | Assert: every resolved baseline entry has derivation row before commit |
| Baseline CSV not installed | Bootstrap artifact phase | `devtools::check()` installed file list includes baseline CSV |
| Windows temp path in network calls | Provider resolution implementation | Use `resp_body_string()` pipeline; no temp file writes |

---

## Sources

- [DuckDB Concurrency](https://duckdb.org/docs/current/connect/concurrency) — single-writer model, read-only vs read-write modes
- [DuckDB R issue #56 — Windows file locking](https://github.com/duckdb/duckdb-r/issues/56) — "used by another process" error pattern and workarounds
- [DuckDB issue #17418 — FileLockType Windows semantics](https://github.com/duckdb/duckdb/issues/17158) — `BufferedFileWriter` exclusive lock on Windows
- [OLS4 issue #623 — local=true ignored](https://github.com/EBISPOT/ols4/issues/623) — cross-ontology results in single-ontology queries
- [OLS4 issue #860 — misleading search ranking](https://github.com/EBISPOT/ols4/issues/860) — exact match not ranked first; Feb 2025, closed with fix
- [OLS4 GitHub](https://github.com/EBISPOT/ols4) — issues list for current known bugs
- [NERC NVS SPARQL endpoint](https://vocab.nerc.ac.uk/sparql) — BODC-hosted service, no published SLA
- [ARGO NVS SPARQL probe](https://github.com/ARGOeu/sdc-nerc-spqrql) — existence confirms endpoint availability monitoring is needed
- [R Packages (2e) — inst/extdata](https://r-pkgs.org/misc.html) — `system.file()` silent empty-string return behavior
- [DuckDB R issue #1088 — read_only flag](https://github.com/duckdb/duckdb-r/issues/1088) — `read_only=TRUE` not always applied correctly
- ComptoxR CLAUDE.md — Windows R segfault guidance for network calls, `/tmp/` path restrictions
- ComptoxR `R/eco_connection.R` — `.eco_get_con()` / `.eco_close_con()` implementation
- ComptoxR `R/eco_lifestage_patch.R` — existing provider query and scoring implementation
- LIFESTAGE_HARMONIZATION_PLAN2.md — patch safety checks, table contract, refresh mode semantics

---
*Pitfalls research for: Ontology API resolution + DuckDB in-place patching in ComptoxR v2.4*
*Researched: 2026-04-22*
