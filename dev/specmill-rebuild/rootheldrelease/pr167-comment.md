Correction and completed client parity proof for the two held CheT wrappers. This supersedes the outer-list-name claim in [my prior proof](https://github.com/seanthimons/specmill/pull/167#issuecomment-6253164045).

The prior harness incorrectly replaced `httr2::req_perform_sequential()` with `lapply(reqs, ...)`. `lapply` preserves names on named request lists; the real httr2 executor returns unnamed responses. **All 24 reported outer-list-name differences were mock artifacts. I retract that blocker.** No formatter change or stripping of output attributes is needed. Replaying the prior candidate with only the sequential replacement removed gives **400/490 exact matches**, rather than 376/490.

Minimal reproduction, with only `req_perform` mocked to return an httr2 response:

```r
reqs <- setNames(rep(list(httr2::request('https://executor.invalid')), 2L), c('1', '2'))
names(httr2::req_perform_sequential(reqs, on_error = 'continue', progress = FALSE))
# NULL
names(lapply(reqs, httr2::req_perform))
# c('1', '2')
```

The portable `executor-check.R` supplies that mock, asserts these exact results and verifies that the sequential executor binding remains unchanged. All parity runs now keep the actual httr2 sequential executor and mock only `req_perform`. Mock responses honor each request's `error_is_error` predicate and use `httr2::resp_check_status()`, including real typed HTTP404/500 errors and transport conditions.

I also completed the supported pure client projections for:

- `chemi_chet_reaction_searchcounts`, GET `/reaction/searchcounts/{search_input}/{search_type}`.
- `chemi_chet_reaction_database_old_by_pagenum_and_searchterm`, GET `/reaction/database-old/{pagenum}/{searchterm}`.

Both operations use `schema/chemi-chet-prod.json`, server prefix `/api/chet`. The old wrapper omits blank suffixes and rejects malformed space suffix URLs during request construction, before HTTP. The completed request-path callback uses the same httr2 path-append semantics, so blank suffixes omit the slash. The pure `validate_inputs` client function retains cross-input batching validation and constructs/parses the complete normalized URLs without sending requests. This preserves the original indexed URL-parse condition class/message/parent/location and zero sends before hooks, fan-out and the drop handler. No fake hooks, handwritten wrappers, helper/executor/generic_request patches or formatter changes.

The official `specmill::generate_client()` emitter still generates both candidates from **exact source `16928dc49804d8149bbf8e126a3bd02c8a68de75`**, archive SHA256 `afc11d55ded4c1a7832b77fb0d63ac7d1eef780df376d33c199d39b56b9de3d1`. The installed private toolkit provenance is verified; official regeneration is byte-identical. DESCRIPTION version 0.1.41 does not mean this PR source is in released v0.1.41. Frozen originals are byte-identical to fixture commit `a79a16b8`.

**Final matrix: 518/554 exact comparisons, with only 36 intentional native hard401 differences.** The original 490 diagnostics now have 454 exact matches and those 36 exceptions. All 64 added whitespace, Unicode, slash, empty-segment and list-suffix cases match. Comparisons retain complete values, names/attributes, warnings, condition class/message/parent/location and request URL/method/Accept/body. No output is un-named or stripped. Blank/space suffix mismatches are resolved, including space suffix zero-send errors under a selected 401 status.

Focused positive assertions also pass: unchanged formals; numeric/list/duplicate/NA/empty cleanup; full normalized params validated once; cross-input and malformed URL zero-send errors; ignored validator return; original sentinel condition identity and parent; validator warnings once outside fan-out; single HTTP404/500/transport parity; exact multi values/attributes, request counts, dropped NULL slots and warnings; mixed success/failure; intentional native hard401 and hard invalid configuration.

Portable candidate, proof scripts, raw diagnostics and report are under ComptoxR `dev/specmill-rebuild/rootheldrelease/`. No other client parity blocker remains in these checks. Adoption remains held only for a released generator containing this feature and the parent-owned toolkit pin update/integration. Public wrappers, actual hooks, runtime helper/executor, generic_request, root config and root pin remain unchanged. No production requests, push or full package check.
