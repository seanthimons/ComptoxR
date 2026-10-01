# Issue #325 closeout review, 1 October 2026

Reviewed `feat/specmill-migration-pilot` at `e5995b6ca1cfb9e978db5c7f0a0f8d2dd49c19cc`
against original client `4fd720b97fb2f7f2abf131925e9270b0c11b057a`, current GitHub
issue bodies/comments, and draft PR #345. Three subagents reviewed migration
dispositions, recent runtime/standards changes, and automation/hooks independently.
Recommendations concern this PR branch. Evidence from another local branch does
not establish completion here. The initial review made no GitHub changes;
the user subsequently authorized the closeout actions recorded below.

## Closeout recommendations

| Issue | Recommendation | Basis or remaining work |
| --- | --- | --- |
| #326 | Close | Complete preservation inventory, whole-file ownership and removal allowlist; all acceptance items checked. |
| #327 | Close | Original 101-wrapper scope completed: 93 files deleted in disposable checkout, byte-identical regeneration/second apply/check, contracts and 459 installed-client cases. Historical evidence satisfies its original scope. |
| #334 | Close for adopted generated scope | Specmill parses declared hook chains, generated wrappers invoke pre/post stages, frozen contracts assert hook/helper call order, and regeneration preserves injection. Broader retained-wrapper verification remains in #312. |
| #340 | Close | Ten fixed-route hook-owned wrappers generated with boundary tests, 1,151-case compatibility wave and byte-identical rebuild. |
| #344 | Close | Fetch/freeze normalization prevents empty Swagger basePath recurrence; both frozen schemas validate and JSON/YAML regressions pass. Upstream documents need not be repaired for this client fix to be complete. |
| #337 | Reconcile checklist, then close | All 25 listed entries have generated, mapped-retained, utility/excluded or blocked-retained dispositions. Five AMOS bulk implementations remain retained under upstream blockers; its completion rule permits written retention. |
| #336 | Record explicit retention policy, then close | All 24 wrappers have retained reasons and upstream diagnostics. Add the promised group-by-group policy and blocker links to REPORT.md and #325; leave unresolved upstream work open. |
| #314 | Keep open pending specific protection evidence | Whole-file dispositions are complete, but its remaining acceptance item requires wrapper stale-adoption and retained-definition rejection evidence. Historical stale-hash evidence exists in dev/specmill-pilot/generation-results.json; helper-emitter overwrite tests alone do not establish the current grouped-wrapper gate. |
| #310 | Keep open | Five supported CT multipath wrappers and ct_chemical_list_search_by_name lack the fixed retained contracts required by acceptance. See DISPOSITIONS.md:59-73. |
| #311 | Keep open | Dispositions exist, but supported retained/grouped entries still need the required original wrapper/caller and contract evidence. Refresh the ChET image disposition after #342. |
| #312 | Keep open | All 26 entries have dispositions, but retained chains still need the required order, partial-update, skip and exception verification. |
| #313 | Keep open | Genuine upstream blockers and supported-route mismatches need explicit classification, follow-up links and separated fixture evidence. |
| #328 | Keep open | Rebuild evidence is substantial, but reconcile current scope/pin, specific protection evidence, and remaining legacy-generator maintenance responsibilities. Latest full deletion evidence predates helper adoption. |
| #332 | Keep open | Scheduled schema updates still invoke dev/generate_stubs.R in .github/workflows/schema-check.yml:201. Existing Specmill freshness CI does not migrate schema-update automation. |
| #333 | Keep open | Selection remains explicit per-service includes; unsupported diagnostics abort generation. Opt-out blacklist/compliance gating and automatic recovered-endpoint adoption are not implemented. |
| #329 | Keep open | Current generic_request still paginates only req_list[[1]], dropping subsequent queries. Reproduced offline at reviewed HEAD. |
| #330 | Keep open | Migrated options wrappers are corrected, but legacy template still emits options <- list() at dev/endpoint_eval/07_stub_generation.R:1735. Its recurrence-prevention acceptance item remains unmet. |
| #343 | Keep open | Delimited conversion remains in decoder/facade policy; requested reusable post_response hook is absent. |
| #341 | Keep open pending explicit retention documentation | Either generate the aggregate fallback with declared second-route support, or use its allowed retention path by citing #341 in both dispositions.json and REPORT.md. Those explicit citations are currently absent. |
| #331, #342 | Keep closed | Recent helper adoption, reproducibility protections and published pagination/image evidence support completion. |
| #335, #338 | Already closed | Retention is allowed by their completion rules. Do not describe every listed wrapper as generated or infer that other-branch execution is present here. |
| #339 | Restore fix in PR branch or reopen | Closure cites commits on local feat/specmill-hooks-wave. Current PR branch still lacks the prefix in 24 of 28 exported ChET wrappers. |
| #325, PR #345 | Keep open; PR stays draft | Remaining schema automation, opt-out adoption, hook and preservation/maintenance gates prevent milestone completion. |

## Standards and runtime findings

No material new correctness or standards violations were found in the recent
generic-helper adoption and schema-normalization changes. Two known defects
remain significant to closeout:

1. **High: closed #339 does not describe this PR branch.**
   `R/chemi_chet_reaction_libraries.R:17` still binds `reaction/libraries` with
   `server = "chemi_burl"`. The resulting default URL is
   `https://hcd.rtpnc.epa.gov/api/reaction/libraries`, rather than
   `/api/chet/reaction/libraries`. The helper appends the endpoint verbatim.
   Only the image and three pagination wrappers currently have corrected paths.
   The closure's `d4dc1ea9` commit belongs to local `feat/specmill-hooks-wave`.
   Restore reviewed mappings and regenerate with updated contract evidence.
2. **High: #329 still silently drops queries.**
   `R/z_generic_request.R:438` selects only the first request for pagination.
   A mocked call with `c("CHR", "DEV")` requested CHR once and never DEV.
   `dev/specmill-full/runtime-cases.R:563` deliberately omits paginated batch
   comparisons, so compatibility success does not demonstrate this bug is fixed.

## Spec and evidence findings

The rebuild report's top-level 0.1.8 pin, old helper-retention description and
category counts are historical. Current reviewed helper pin is Specmill 0.1.11
at `d59014365b8b30bde2ce319b5e60d9c3f94fe48f`. The ChET image ledger still
records an old retained route despite the adopted correction. Update current
summaries while preserving accurately labelled historical evidence.

The 1,474-case compatibility summary predates subsequent image and pagination
route corrections. Those have focused published verification; do not relabel
the historical summary as a complete final-HEAD comparison.

## Validation performed

- Hosted Specmill Maintenance run 36926205675 completed successfully at reviewed
  HEAD, including fixed contracts/client policy tests and no-change regeneration.
- `Rscript dev/specmill-342/verify.R` passed provenance, emission freshness,
  idempotence, overwrite refusal, explicit adoption and whole-file ownership checks.
- Subagent offline/localhost runtime, edge, Chemi, hooks, adoption and schema
  normalization tests passed. Both frozen descriptor schemas validated as passed.
- Focused hook/contract checks passed 111 assertions without failures, warnings
  or skips; current generation freshness check passed.
- #329 reproduced using mocked responses, without production requests.

Package/CRAN readiness was skipped for the draft PR and is not established by
the green Specmill maintenance lane. No production write requests were made.

## Authorized closeout actions

Closed #326, #327, #334, #337, #340 and #344 with evidence on GitHub. #334 explicitly
covers adopted generated-wrapper hook injection; retained-hook verification
remains in #312. #337 now records all 25 reviewed outcomes: 10 generated, 8
retained with fixed contracts, 1 utility, 1 excluded scraper and 5 upstream-blocked
retained AMOS wrappers. Updated #340's completed work checklist.

Parent #325 now records the retained-maintenance policy for #336 and #341,
updates the completed child checklists, and notes the outstanding #339 branch
discrepancy. Parent #325 and PR #345 remain open.

Closed #336 and #341 after recording their explicit retention policies in the
issue bodies, parent #325 and local REPORT.md. Persisted those reasons in
dispositions.R and the JSON/Markdown ledgers. Validation parsed the R source,
checked all 26 retained reasons, verified upstream group counts of 16/6/1/1,
and confirmed that no JSON fields other than those reason strings changed.
Local documentation changes are uncommitted and have not been pushed.
