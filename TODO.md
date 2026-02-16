# TODO

## Pending PRs (Resolve Immediately)
- [ ] PR #85: chore: API schema updates detected [open] — `automated/schema-update`
- [ ] PR #74: Refine PubChem search parameter passing [draft] — `copilot/add-pubchem-search-functionality`

## High Priority (Quick Wins & Critical)
- [ ] Add request backoff feature to generic requests (#75) — high impact, medium complexity

## Medium Priority
- [ ] Auto-mark removed endpoints as `.Defunct()` (#86) — when CI detects an endpoint removal from a production schema and an existing R function wraps it, auto-replace `@experimental` with defunct lifecycle badge and inject `.Defunct()` at function top. Scoped to removals only (not param changes or staging). Touches stub generator, diff engine, and workflow.
- [ ] Explore S7 class implementation (#29) — medium impact, high complexity
- [ ] Advanced schema handling: content-type extraction, primitive types, nested arrays (#83) — medium impact, high complexity

## Low Priority (Backlog)
- [ ] Follow up on bad SMILES info (#30) — low impact, low complexity

## Completed
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
