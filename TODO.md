# TODO

## Pending PRs (Resolve Immediately)
- [ ] PR #74: Refine PubChem search parameter passing [draft] — `copilot/add-pubchem-search-functionality`

## High Priority (Quick Wins & Critical)
- [x] Add request backoff feature to generic requests (#75) — high impact, medium complexity
- [x] Stub generator: protect stable functions from overwrite (#95) — lifecycle guard in `scaffold_files()`, fallback function-definition matching in `find_endpoint_usages_base()`, `overwrite=FALSE` default (PR #112)
  - [x] In `scaffold_files` or upstream: before overwriting, scan the target file for `@lifecycle` roxygen tags — skip if any function has `stable`, `maturing`, or `superseded` lifecycle
  - [x] Improve `find_endpoint_usages_base` matching to reduce false negatives (e.g., partial route matching, cross-reference by function name not just endpoint string)
  - [x] Consider `overwrite = FALSE` as the default in CI, with explicit opt-in for known-safe overwrites

## Medium Priority
- [ ] Schema-check workflow improvements (#96) — further iteration on the automated schema-check CI:
  - [ ] Fix "Schema diff encountered errors" warning — debug why `diff_schemas.R` hits errors during parsing (likely a single schema with non-standard OpenAPI structure)
  - [ ] Detect endpoint-level changes within files that only differ by formatting — currently pretty-printing neutralizes these, so real param/route changes inside otherwise-reformatted files could be missed
  - [ ] Add a "no changes" early exit — skip PR creation entirely when only cosmetic JSON formatting diffs exist (no endpoint-level changes and no meaningful file diffs)
  - [ ] Deduplicate PR creation — if an open `automated/schema-update` PR already exists with identical schema diffs, update it in place rather than closing and recreating
- [ ] Auto-mark removed endpoints as `.Defunct()` (#86) — when CI detects an endpoint removal from a production schema and an existing R function wraps it, auto-replace `@experimental` with defunct lifecycle badge and inject `.Defunct()` at function top. Scoped to removals only (not param changes or staging). Touches stub generator, diff engine, and workflow.
- [ ] Explore S7 class implementation (#29) — medium impact, high complexity
- [ ] Advanced schema handling: content-type extraction, primitive types, nested arrays (#83) — medium impact, high complexity

## Refactoring: Migrate to Generic Requests
- [ ] Migrate `ct_bioactivity()` to generic requests + promote to stable (#97) — `R/ct_bioactivity.R:1`
- [x] Fix incorrect function reference in `ct_bioactivity()` (#98) — replaced `ct_bio_assay_all()` with `ct_bioactivity_assay()`
- [ ] Migrate `ct_cancer()` to generic requests + promote to stable (#99) — `R/ct_cancer.R:1`
- [ ] Migrate `ct_demographic_exposure()` to generic requests + promote to stable (#100) — `R/ct_demographic_exposure.R:1`
- [ ] Migrate `ct_details()` to generic requests + promote to stable (#101) — `R/ct_details.R:1`
- [ ] Migrate `ct_descriptors()` to generic requests + promote to stable (#102) — `R/ct_descriptors.R:1`
- [ ] Migrate `ct_env_fate()` to generic requests + promote to stable (#103) — `R/ct_env_fate.R:1`
- [ ] Migrate `ct_functional_use()` to generic requests + promote to stable (#104) — `R/ct_functional_use.R:1`
- [ ] Add post-processing to `ct_hazard()` + promote to stable (#105) — `R/ct_hazard.R:1`
- [ ] Migrate `ct_lists_all()` to generic requests + promote to stable (#106) — `R/ct_lists_all.R:1`
- [ ] Evaluate `ct_prop()` for migration to generic requests (#107) — `R/ct_prop.R:1`

## Low Priority (Backlog)
- [ ] Follow up on bad SMILES info (#30) — low impact, low complexity
- [ ] Remove hardcoded `ctx_server(server = 9)` workaround in `ct_related()` (#108) — `R/ct_related.R:43` — remove override once the related-substances API endpoint is available on production
- [ ] Determine if `ct_related()` endpoint will remain (#109) — `R/ct_related.R:1` — follow up on whether the related-substances endpoint is permanent
- [ ] Investigate missing DTXSID field in `chemi_cluster()` (#110) — `R/chemi_cluster.R:77,86` — some compounds don't return a DTXSID field; the field was removed as a workaround but root cause is unclear

## Completed
- [x] PR #94: chore: API schema updates detected [merged] — `automated/schema-update`
- [x] POST requests for chemical/search/equals/ (#73)
- [x] fix: follow-up on unicode_map always saving to sysdata.rda (#80)
- [x] fix: ComptoxR::as_cas() and is_cas() error handling (#77)
- [x] Create minimal schema checking functions (#33)
- [x] Add custom coverage badge (#68)
- [x] Investigate suppressing startup messages (#61)
- [x] Generic requests should assign to variable (#39)
- [x] Add in custom batch sizing (#23)
- [x] Fix chemi_rq (#21)
- [x] Update chemi_safety to httr2 (#20)
- [x] Add searching by first INCHI block (#17)
- [x] Remove images from chemi_resolver results (#28)
- [x] Slow pinging on initial startup (#27)
- [x] Building failing on non-Windows platforms (#26)
