# Resume the full Specmill API migration

Updated 18 October 2026. Branch feat/specmill-migration-pilot, PR345. Local commits authorized; no ComptoxR push/merge/release. Inspect actual HEAD/status first.

## Current root state

Committed checkpoint 499/548. Endpoint addition b53685bd, hook discovery e6cf6cd1, and CI/public-artifact checks a7986f98 are committed locally. Root uses official Specmill 0.1.42, source b17a0856263e0179a164a9673399f221168cda6d, versioned private library dev/specmill-pilot/artifacts/toolkit-library/0.1.42. All generation is wrappers/tests scope with validationTRUE, official helper scaffold. No runtime helper/executor/generic_request patches.

Latest iteration adds reviewed standardizer POST /api/stdizer/groups/preflight from audit655886bc. Import script has ALREADY run; do not rerun it. New native R file is officially emitted, all 705 ownership hashes match and all 704 preceding owner records are unchanged. New schema/provenance/config/export/Rd/registered test are present. Current production api-docs retrieval is parsed-identical to canonical; canonical raw bytes unchanged. Public freshness/all31 source reports pass; progress and current49-identity dispositions are regenerated.

Completed root gates:
- Public apply and maintenance freshness completed, result canonical-holds-audit/root-fresh.rds. All 31 selected sources pass validation.
- Final broad safe suite completed successfully: 13,031 passing assertions, 50 expected skips, zero failures/errors/warnings. Pinned R_LIBS42, keys blank, external proxy denied, localhost allowed. Full evidence canonical-holds-audit/broad-safe-tests.rds/csv/log.gz and broad-safe-summary.json. Do not repeat broad DB testing without new changes or unresolved concerns.
- Installed package replay completed128 assertions, no failures/errors/warnings/skips. Source corrective replay132 is clean.
- No active delegated task. The AMOS child failed at model capacity before starting; parent prepared an isolated archive directly. The user then explicitly deferred both XLSX migrations pending specialized-behavior review. See amos-batch-candidate/README.md: generation passes, behavior proof incomplete, no root adoption.

The preceding broad 498 run completed 12,942 passing assertions / 50 expected skips / 2 errors, zero failed expectations/warnings. It is NOT a clean full pass. Saved in v42-11-integration/broad-two-errors.rds and log.gz. Two fixes now pass focused 132 assertions: restore the exact unchanged native GET assay fixture accidentally removed with the eight migrations, and Connection:close for WebTEST localhost replies across204/malformedJSON. Runtime transport unchanged. Focused132 includes GET 2, WebTEST 85 and new preflight 45. Do not delete the owned GET contract test. WIP fixture restores its exact parent entry.

## Passed gates and evidence

The eleven-operation iteration added approved #352 SID/resolver contract, eight original facades fromb9674e5a and WebTEST exports2 from5e497b94. All704 ownership hashes/all 30 selected-source reports/freshness/current retained inventory pass. Root focused 616 assertions pass. Both public maintenance entrypoints pass. Package gate0 errors/warnings/notes, optional Suggests relaxed and tests/examples/vignettes/manual excluded. Its snapshot has the same runtime core but predates added preflight1 and still contains three since-retired unowned tests, excluded by --no-tests. Do not claim a full strict package check.

#352: actual generated root wrapper and resolver positive controls PASS on staging/production. Query=NULL accepts validated DTXSID vectors; no-argument early error retained; native hard401/config remain hard through existing resolved_chemical_response. Resolver dependency documented. Root focused248 earlier, isolated268 is different baseline. See issue-352/root-* and PR345 comment6254889384, issue352 comment6254889600.

Review: Standards 0 findings; Spec 1 P2 hook-discovery finding resolved. dev/check_hook_config.R now exposes all already parsed package functions to strict validator. Six absent/unexported stale registry names removed. Actual hook CLI now passes 272 functions / 123 hooks / 34 extras including preflight. Discovery outside hooks_*.R plus missing-hook/wrapper rejection self-check PASS. No function bodies moved/changed. Evidence v42-11-integration/REVIEW.md, check-hook-discovery.R and hooks-*.txt.

## Next concrete work

1. Keep both AMOS XLSX migrations deferred at the user's explicit request until specialized return/file-handling behavior is reviewed. Fresh controls and the isolated, incomplete candidate are archived; do not count or adopt them. Continue the other held identities when verified releases or source evidence arrives; current499/548 remains unchanged.
2. The final broad result is clean and recorded, and PR345 progress comment6255254919 includes its verified totals. No push. Hook validation, retained inventory, public-boundary checks and all13 workflow YAML parses pass locally; remote CI has not run.
3. Keep native401/config hard and explicit preserve_errors controls for complete request mappings. No source guessing, aliases or validation bypasses.

## Holds and released-only adoption

Official v43 and v44 verified available, root remains42 because current mappings require42 and inputs were kept stable during gates. v44 source 496c91e1eb7365f8f73f9c063f6c78b0c98aa1ee, tarSHA7fdc088cbd3660fab74a7da2c22b67293601dfb0c5fbaf3fc4b93bbb9ee7e478 releases 172 ownership reconciliation. PR176 release is next per overwatch, not yet verified here.

Private proofs, all held for official release/pin:
- PR176 exact a656ce446fd2f4fe28184e3cad69da02e209ef26, proof 13801f14: five actual boolean routes/shared throttle, 210 groups/65localhost requests PASS, root dev/specmill-pr176-proof.
- PR179 revised exact 1c3e8a34c41eba5d2a20cc46f8bc2e39abb6d18c, proof 3d9369e7:227 assertions PASS all three prior blockers, root pr179-finish-1c3e8a3. First105 diagnostic proof retained separately. PubChem source/service mismatch remains separate.
- PR180 exact d9c6f9600f075e941999fc4fafffd4ede3d90b73: 492 assertions/36localhost requests PASS three forms; root dev/chet-admin-auth/pr180-exact.

Other concrete generator holds:181 ToxPrint chunked object-body facade;61 aggregate descriptor GET/POST server identity and duplicate safety GET /api/alerts/render media ownership. Exact v42 repros and issue comments recorded in canonical-holds-audit/descriptor-blockers.json and webtest-exports/safety-ownership.json. Sent overwatch current actionable proof, no duplicate implementation. Metadata182 has supported fixed/bespoke coverage, not a runtime adoption blocker. PubChem three original wrappers/six HTTP operations additionally await174 cache and175 throttle; those are outside canonical548 denominator. Thirty-eight residual source/service/route holds after new preflight are documented by exact operation/evidence in audit report. Do not claim deployed success for inherited payload defects under #311.

Overwatch thread cbc44732-4d1d-4d9a-800f-80147bee5a81 owns Specmill changes. User permits staging/dev read/calculation probes and CTX key use. No deployed mutations/uploads/auth/session calls. All child R/build runs use TMPDIR=/home/sxthi/.cache/comptoxr-specmill-finish/tmp before R launches; /tmp tmpfs remains near full. Never modify active libraries or delete others' evidence.

## Verification traps

- Full request.arguments replaces defaults: include preserve_errors explicitly.
- Adopt uses specmill:::output_hash, not raw file SHA. Filter nonexistent paths.
- Stable lifecycle badges can retain unowned files even with adopt. Freeze and
  hash-check reviewed old bytes before removing only those bytes for official
  emission; inspect file actions and all owner records afterward.
- Never sort NAMESPACE raw lines: multiline imports must stay intact. Append
  reviewed exports and parse the namespace.
- Keep generation inputs stable throughout a full generation/check call.
- Keep real httr2 sequential execution in parity tests; replacing it with named
  lapply invents names and false behavior differences.
- CRAN-safe full tests block external HTTP and allow localhost. Live service
  tests are separately recorded. Do not claim a full R CMD check when tests,
  examples or vignettes were excluded; report those gates separately.
