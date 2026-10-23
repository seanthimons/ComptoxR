# SID input trial for ComptoxR #352

## Current branch verification, 19 October 2026

The implementation was already integrated in `3a3fd61a`. Rechecked at
`3b49067d530b905b8779eddad2476b0a1d4db019` with official Specmill 0.1.51.
No wrapper, hook, schema, mapping, signature or runtime change was needed.

- Four focused suites pass 245 assertions with zero failures, errors, warnings
  or skips. See `current-tests.json` and `current-tests.rds`.
- Public validated generation freshness passes all 34 selected sources with
  zero operation diagnostics, mapping diagnostics or signature drift. All 660
  owned outputs are unchanged and their hashes match. See
  `current-generation.json` and `current-freshness.rds`. The existing OAS 3.1
  GET-body interoperability warning remains unrelated to this POST operation.
- Fresh actual-wrapper calls through the resolver pass on staging and
  production. Benzyl chloride returns 100 lb/45.4 kg, disulfoton returns
  1 lb/0.454 kg, and ethylene oxide is omitted. See `current-live.json`.

The agreed interface is `chemi_safety_rqcodes(query = NULL)` with validated
DTXSID vectors. No arguments still fail before HTTP. This resolves the input
contract and migration work in #352. The resolver remains an availability
dependency. No full package suite, installed-package replay or remote CI was
rerun for this verification, and nothing was pushed or merged.

## Original trial and integration evidence

Worktree branch: `fix/352-sid-rqcodes`, based on `810d688f`.

The generated `chemi_safety_rqcodes(query = NULL)` accepts a vector of DTXSIDs.
It validates inputs before HTTP, uses the existing resolver pre-hook with
`idType = "DTXSID"`, and flattens the resolved ChemicalRecords with the existing
flattening hook. The safety request sends a top-level Chemical array. The
original RQ formatter is preserved as a post-response hook. The no-argument
call retains its original early error.

Pinned Specmill 0.1.41 supports this configuration without PR #168 or changes
to the shared request helper. Existing response-policy and error-preservation
configuration preserve typed HTTP errors and original transport failures.

The live trial on staging and production returned benzyl chloride with
`rq_lbs = 100`, `rq_kgs = 45.4`, and disulfoton with `rq_lbs = 1`,
`rq_kgs = 0.454`. Ethylene oxide has no RQ result and is omitted. See
`live-results.json`. This establishes these positive controls, not complete
service coverage. A resolver outage can now prevent a safety lookup even
though the safety endpoint itself accepts SID-only objects.

Reproduce from the worktree root with the pinned toolkit library installed:

```sh
Rscript -e 'rd <- roxygen2::roc_proc_text(roxygen2::rd_roclet(), paste(readLines("R/chemi_safety_rqcodes.R"), collapse="\n")); writeLines(format(rd[[1]]), "man/chemi_safety_rqcodes.Rd")'
Rscript dev/specmill-rebuild/issue-352/verify-generation.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(native_safety_rqcodes|retained_search_safety|chemi_resolver_transformations|native_resolved_payloads)$", reporter="summary", stop_on_failure=TRUE)'
Rscript dev/specmill-rebuild/issue-352/live.R
```

The old zero-input helper-call contract tests are replaced by tests of the
resolver plus safety request. Existing RQ formatting checks move to that new
request path. The shared resolver and unrelated wrappers remain unchanged.

The root generation check uses the established `wrappers` and `tests` artifact
scope. Requesting all documentation also exposes 86 protected outputs in the
initial plan, including NAMESPACE and existing manual pages. Those unrelated
outputs are not adopted. The changed RQ manual page is generated directly from
its roxygen block. No full package check is claimed by this trial.

Final focused verification passed 268 assertions with no failures, warnings or
skips, including 39 assertions in the new RQ suite. All 647 owned outputs exist
and match their manifest hashes. The superseded helper-only test ownership was
explicitly retired with supported `specmill::apply_files`; its plan/apply/check
evidence is `test-retirement.rds`.

Validated root wrapper/test apply and public freshness check completed with zero
operation diagnostics, mapping diagnostics or signature drift. The existing
archived OAS 3.1 GET-body interoperability warning remains. The saved check has
no writes, removals or protected outputs. Updating the verification script during
execution caused a trailing parser error after these results had been saved;
a separate clean R process verified the current script parses and asserted the
saved public-check result. No generated source changed after that check.

## Root integration on released v0.1.42

The SID contract and resolver preprocessing were independently emitted in the current root. The public decoder callback is `resolved_chemical_response`, so native 401 remains a hard `specmill_call_error`; other HTTP errors and transport conditions retain typed/original failures. The original candidate used `remaining_facade_response` and expected typed httr2 401. This is an explicit native-policy difference, not a formatter or helper patch.

Root replay passes 248 assertions across the four selected suites, zero failures/errors/warnings/skips. The earlier isolated 268 count describes a different parent suite. `root-tests-v42.rds` preserves the root result. `root-live-v42.json` independently reproduces both positive SID controls and omission of the third SID on staging and production through the actual generated wrapper and resolver. All 704 root owner hashes match after emission; the superseded helper-test owner was retired through `specmill::apply_files`. All unrelated owner records are unchanged. Freshness and the final broad/package gates follow the eight-facade integration, rather than claiming the isolated trial as a full package check.
