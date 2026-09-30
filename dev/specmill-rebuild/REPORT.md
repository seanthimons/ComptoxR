# Specmill public API client rebuild (#325)

Work stays on `feat/specmill-migration-pilot`. Deletion experiments run only in
detached worktrees under the ignored `dev/specmill-pilot/artifacts/rebuild-<commit>/`.
Toolkit pin: specmill v0.1.8 `2df2657b7f3576ef7af8072c21ed6b1f6aa9ce8c`, archive SHA-256
`6085d39a0d02822fabd870916e697065294f597238592c51bccaea2fc05b8091`. Air 0.11.0.

## Generic request migration (#331)

[The assessment in #331](https://github.com/seanthimons/ComptoxR/issues/331) inventories all four transport helpers
and identifies the upstream ports needed before replacement: response policy,
generated batch/pagination support, and plain-text bodies. Existing native
serialization, authentication, form encoding, and retry controls can be reused.
The helpers remain client-owned while compatibility is verified; #331 is open.
The installed-client verifier now checks internal search/PubChem transport and
all four helper signatures as well as exported wrapper contracts.

## Preservation inventory (#326)

`Rscript dev/specmill-rebuild/inventory.R` parses every top-level definition in
`R/` and writes [inventory.json](inventory.json): file, export status, category,
review reason, mapped operation, lifecycle badge, and deparsed formals. It also
writes [removal-allowlist.json](removal-allowlist.json), which lists whole files
with SHA-256 hashes.

| Export category | Exports |
| --- | ---: |
| generated (specmill-owned) | 263 |
| retained_mapped (fixed contract, existing implementation) | 5 |
| unmapped_wrapper (retained with recorded reason, #310–#314) | 83 |
| runtime (request helpers, hook registry/hooks, startup, server setters) | 20 |
| sidecar (DSSTox/ECOTOX/ToxVal local databases) | 26 |
| utility | 11 |
| re-exported `%>%` | 1 |
| **Total** | **409** |

The inventory categorizes exports by source file and mapping, not by name
prefix. As a result, `chemi_server()` and `epi_server()` are classified as
runtime, not endpoint wrappers. They are two of the 248 functions in #310 and
stay retained as runtime configuration. Counts include the #337 waves below; the original tranche was 101 generated and 246 unmapped.

The allowlist is derived from the generated operation mappings and the specmill
manifest. It now contains the 226 whole files that hold the 263 generated wrappers
(originally 93 files for 101 wrappers).
A file is allowlisted only if every top-level definition in it is generated.
The script stops if a generated file has a retained or unaccounted neighbor.
The four retained files (`R/ct_chemical_detail_search.R`,
`R/ct_chemical_list_all.R`, `R/chemi_search.R`, and
`R/chemi_resolver_lookup_bulk.R`) are excluded.

Preservation check: after rebuilding in the worktree, `git status --porcelain`
must be empty. That compares every tracked file byte for byte, including runtime
code, hooks, sidecars, `man/`, `NAMESPACE`, tests, fixtures, and the manifest.
Because the files are identical, exports, signatures, documentation, and
lifecycle badges are unchanged.

## Rehearsal of the existing 101 wrappers (#327)

`Rscript dev/specmill-rebuild/rehearse.R` (clean committed checkout) does the following:

1. Creates a detached worktree at `HEAD` and links the pinned toolkit library.
2. Checks each allowlisted file hash, then deletes exactly those 93 files.
3. Runs `dev/generate_specmill.R --apply`, then `--apply` again, then `--check`.
   After each step, `git status` must show no difference.

Result at `71ca1678`: 93 files removed and 101 operations regenerated. All three
steps were byte-identical. The planner printed the existing informational
relative-server-URL notes; they are not diagnostics.

Runtime verification of the rebuilt worktree, installed into
`artifacts/rebuild-library`:

```bash
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request_edge|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks)$", stop_on_failure=TRUE)'
Rscript dev/specmill-full/verify-runtime.R artifacts/before-library artifacts/rebuild-library artifacts/rebuild-runtime
```

The fixed contract, request-edge, and hook tests all passed. All 459 installed-client
localhost cases passed against the original `4fd720b9` client, with no candidate
failures. No output was promoted: the rebuilt files are identical to the branch.

Rollback: revert the `dev/specmill-rebuild/` commits. The package is untouched.

## Specmill v0.1.6 and stable generation (#310)

The toolkit is pinned to v0.1.6, which fixes stable-wrapper generation.
Stable wrappers are generated normally, and the badge comes from the mapping
(`docs: {lifecycle: ...}`). Nothing is marked `implementation: existing`,
nothing was badged by hand, and no generated file was edited. Re-running the
schema audit at 0.1.6 gave the same 53 parser blockers and 102 fixture failures
as 0.1.4. Only the CHET collision reason text changed, and it now has more
detail. The re-audit output was not committed.

v0.1.8 renders data-literal defaults and examples as plain R
([seanthimons/specmill#53](https://github.com/seanthimons/specmill/issues/53))
and adds `propose_mappings()` and `verify_adoption()`
([seanthimons/specmill#54](https://github.com/seanthimons/specmill/issues/54)).
Re-pinning changed no generated wrapper: `--apply` only updated the manifest's
`toolkit_version`, and the rehearsal stayed byte-identical.

## Generation waves (#310, #311, #314)

`Rscript dev/specmill-rebuild/wave.R <name>` screens every unmapped export and
stages mechanical candidates in a detached worktree. It stops if the generated
wrappers change any roxygen output. `dev/specmill-rebuild/verify-wave.sh <name>`
does the rest:

- retires superseded legacy tests;
- re-runs `--check`;
- installs the candidate;
- runs the contract, request-edge, and hook tests;
- compares the installed original `4fd720b9` client with the candidate on localhost.

A wave is adopted only when all of the following hold:

- generation is idempotent;
- roxygen, `man/`, `NAMESPACE`, and lifecycle lines are unchanged;
- formals are identical;
- the before/after interfaces are equal;
- there are zero candidate failures.

| Wave | Operations | Localhost cases | Commit |
| --- | ---: | ---: | --- |
| hazard-pilot | 5 | 489 | `77de2d69` |
| stable-batch | 67 | 834 | `0fb6f4d5` |
| options-batch | 52 | 1015 | `b851a6cd` |
| vector-examples | 14 | 1099 | `30a4dc49` |
| hook-owned | 10 | 1151 | `d5c4224d` |

The options-batch wave covers wrappers with an optional `options <- list();
if (!is.null(x)) options$k <- x` prelude, which is mapped to specmill
`compact_object`. Each candidate is called with the option inputs omitted,
explicit, `FALSE`, and `0`, and with no arguments at all. Every call must reach
the helper exactly as the original does. On localhost, the requests are
observed and compared between the original and generated clients, not
modelled.

The vector-examples wave maps a `c()` of scalar literals in an example to a
sequence example. At 0.1.6 it was rejected because specmill rendered it as
`base::evalq(c(...), envir = base::baseenv())`, which changed the Rd examples.
At 0.1.8 the Rd output is unchanged. The wave adopts the nine `*_bulk`
wrappers and five siblings that were retained only because they share a file
with one of them.

## Defects found in the original client (#329, #330)

- Paginated `generic_request` wrappers send only the first query of a batch.
  Queries 2..n are dropped. The runtime batch probe is skipped for these
  wrappers, and the before/after snapshots keep the original behavior.
- `chemi_stdizer_records` and `chemi_toxprints_assays_bulk` overwrite their
  public `options` argument with a locally built list. The #337 options-correction
  wave below fixes both and generates their wrappers.
- `chemi_chet_reaction_batchsearch` evaluates its missing arguments in a
  different order from its signature, so a generated wrapper would give a
  different missing-argument error. It is retained.

## Dispositions (#310–#314)

`Rscript dev/specmill-rebuild/dispositions.R` covers all 248 checklist exports
and writes [dispositions.json](dispositions.json) and
[DISPOSITIONS.md](DISPOSITIONS.md). Each generated export records its service,
operation key, file, and wave. Each retained export records:

- the screen reason;
- the helper route (method and endpoint);
- the supported and blocked audit records on that route, with code, reason,
  pointer, and issue;
- any file siblings;
- for hooked wrappers, the hook chain, with the file that defines each hook and
  the stages the wrapper actually invokes.

| Issue | Generated | Retained | Retained mapped | Client utility |
| --- | ---: | ---: | ---: | ---: |
| #310 | 90 | 15 | 1 | 3 |
| #311 | 59 | 34 | 0 | 0 |
| #312 | 10 | 16 | 0 | 0 |
| #313 | 1 | 15 | 0 | 0 |
| #314 | 2 | 2 | 0 | 0 |

Reasons for keeping an export retained:

- no unique supported schema route (40), including the ambiguous-media and
  malformed-route blockers in #313;
- a client hook chain (18);
- a hand-written implementation (16);
- an inseparable grouped file (11);
- the remaining original evaluation-order defect above.

A retained function is a valid completion state. No contract is guessed.

## Hooks (#312)

Ten fixed-route descriptor and WebTEST wrappers are generated through the
hook-owned wave in #340. The other 18 previously unmapped hooked wrappers remain retained.
Hook functions and the runtime registry remain client-owned in every case.

## Hook-owned requests (#340)

The `hook-owned` wave adopts the scalar and bulk forms of `chemi_padel`,
`chemi_mordred`, `chemi_rdkit`, `chemi_webtest`, and `chemi_webtest_predict`.
`wave.R` uses the reviewed GET/POST routes from #340 and checks them against
the corresponding schemas. It never infers a route from a hook expression.
Each helper argument referencing `req_data$request` is bound to `hook_state`;
literal arguments remain `value` bindings. The declared pre/post chains,
full post-hook state, and `post_on_skip` are preserved. The prediction wrappers
also retain required `endpoint`/`endpoints` formals that become NULL when omitted.
The existing `preserve_choice_defaults` callback keeps vector defaults unchanged.

The screen compares formals and the full hook/helper call sequence against the
original, with both normal and skipped requests. Roxygen output, `man/`,
`NAMESPACE`, examples, and lifecycle badges are unchanged. Generated contract
tests freeze the original hook/helper boundary. The descriptor and WebTEST
behavior tests run with `verify-wave.sh` too; the obsolete assertion requiring
the local variable text `post_data <- req_data` was removed.

Localhost cases stub only identifier resolution. All ten wrappers exercise a
resolved identifier, each engine's explicit options/body, raw output, invalid
input that skips transport, unresolved identifiers, and missing required input.
Both prediction wrappers also exercise omitted endpoint selectors, which the
validation hooks reject after the wrappers convert missing arguments to NULL. Requests,
results, warnings, and errors are compared with the original installed client.
Only the random localhost port in result provenance is normalized.

The verification script passed all contract, request-edge, descriptor, and
WebTEST hook tests. All 1151 localhost cases and 409 exported signatures matched
the original, with zero candidate failures. The inventory parser now skips the
generator marker before reading lifecycle badges, so the ledger retains each
wrapper's actual badge.

The 217-file rehearsal at `d5c4224d` regenerated all 249 generated wrappers.
Regeneration, a second apply, and check were byte-identical. Verification
results are recorded in `wave-hook-owned.json` and `runtime-results.json`. The disposition ledger records the reviewed route,
request bindings, hook chains, post state, and post-on-skip policy for every
adopted wrapper.

## Full rebuild rehearsal (#328)

Scope is frozen at the 409 exports in [inventory.json](inventory.json), and
each one is classified. The rehearsal ran `rehearse.R` at `ee7a80c6`
(specmill 0.1.8) with the expanded allowlist. In a detached worktree, it
removed the 212 allowlisted files. Regeneration, a second `--apply`, and
`--check` were each byte-identical, and `git status` stayed empty. The rebuilt client was then
installed into `artifacts/rebuild-final-library` and checked two ways:

- The contract, request-edge, and hook tests passed.
- All 1099 localhost cases (409 exported signatures) matched the original
  `4fd720b9` client, with no candidate failures.

No output was promoted: the rebuilt tree is identical to the branch.

Rollback: revert the wave commits (`77de2d69`, `0fb6f4d5`, `b851a6cd`,
`30a4dc49`) to
restore the hand-written files and legacy tests. Revert the other
`dev/specmill-rebuild/` commits to remove the tooling.

## Resolver query validation (#337)

`chemi_resolver_lookup` and `chemi_resolver_lookupCASRN` now use schema
parameters instead of explicit `inputs`. Both reject missing, NULL, empty,
blank, NA, and multiple query values before transport. Lookup's optional
parameters also use the schema's types and enums. Public signatures,
lifecycle badges, valid request bytes, and returned objects are preserved.
The bulk lookup wrapper moved unchanged into its own file and remains retained.

The contract suite, resolver regression tests, and legacy generator checks
passed. The installed-client localhost comparison passed 1172 cases with
zero candidate failures and preserved all 409 exported signatures and helper
signatures. The 12 corrected invalid-query cases are recorded separately in
`runtime-results.json`; all make zero requests in the generated client.

In a detached worktree with the current changes applied over `5bab21b5`,
removing all 218 allowlisted wrapper files and regenerating restored every
managed file byte-for-byte. A second apply and check were also identical.
Evidence is recorded in `wave-resolver-query.json`.

## Inline CT mappings (#337)

The `inline-ct` wave generated `ct_bioactivity_assay_search_by_endpoint`,
`ct_chemical_search_equal_bulk`, and its grouped sibling `ct_chemical_search_equal`.
The wave mapper now supports named inline request lists and the exact-search
batch-limit callback. Public signatures, stable badges, documentation,
namespace, query encoding, and returned objects are preserved. Bulk exact
search still sends newline-delimited `text/plain` with a `1000` fallback when
`batch_limit` is unset.

The contract, request-edge, hook, batch-limit regression, and PubChem CAS
fallback tests passed. Three superseded legacy tests were retired, and the
legacy generator check passed. A focused installed-client comparison passed
96 localhost cases with zero failures. It covered all three CT exports,
the prior resolver corrections, and existing pilot/helper probes, and
preserved all 409 exported signatures and retained helper signatures.
The verifier now uses an exact lookup of `query` so `query_params` is never
mistaken for a batch query through R's partial list-name matching.

The deletion/rebuild rehearsal at the disposable snapshot `12c9a72c` removed
220 allowlisted files. Regeneration, a second apply, and check were
byte-identical. Evidence is recorded in `wave-inline-ct.json` and
`runtime-inline-ct-results.json`. This completes two more #337 entries;
21 remain to review.

## Public options correction (#337)

The `options-correction` wave fixes and generates `chemi_stdizer_records` and
`chemi_toxprints_assays_bulk`, plus the grouped GET sibling
`chemi_toxprints_assays`. The reviewed routes are `POST /api/stdizer/records`
in `chemi-stdizer-prod.json`, and `GET /api/toxprints/assays` and
`POST /api/toxprints/assays` in `chemi-toxprints-prod.json`. The GET listing
route has optional query parameters `category` and `label`; the schema's
`GET /api/toxprints/assays/{name}` is a separate operation.

Both POST schemas declare an `options` property. The wrappers previously
replaced caller options with their accumulator before assigning that property.
The wave freezes a corrected reference using a separate accumulator and maps
it to the existing `compact_object` binding. Caller options now reach
`generic_chemi_request` at `options$options` and the existing wrapped payload
at `payload.options.options`. NULL values are omitted; empty lists, nested
lists, FALSE, and zero are preserved. The helper's existing query, wrapping,
sibling fields, authentication, error handling, and returned objects stay
unchanged. Public signatures, experimental badges, documentation, examples,
and namespace output are preserved.

The contract, options regression, request-edge, and hook suites passed.
The focused regression adds 57 assertions, and three superseded generated
legacy tests were retired. The legacy generator check passed. All 1209
installed-client localhost cases passed with zero candidate failures, preserving
409 exported signatures and all helper signatures. `verify-runtime.R` records
14 intentional options-correction cases separately from the prior 12 resolver
query corrections. It asserts the corrected nested options field and compares
every other request field, results, warnings, and errors with the original.
`runtime-options-correction-results.json` records the full comparison; exact
parity is intentionally false for the recorded corrections.

The disposable snapshot `e4afc155` includes the existing uncommitted work.
Its rehearsal removed all 222 allowlisted files and regenerated 256 wrappers.
Regeneration, a second apply, and check were byte-identical. The user's branch
and index were preserved; no files were deleted in the primary checkout for
the rehearsal. The inventory, allowlist, and dispositions now reflect this
wave. Evidence is in `wave-options-correction.json` and
`runtime-options-correction-results.json`. Two more #337 entries are complete;
19 remain to review. The GET sibling was also migrated as part of whole-file
ownership.

## Prediction body alternatives (#337)

The `prediction-bodies` wave generates `chemi_opera_bulk` and
`chemi_predictor_models_predict_bulk`, plus their grouped GET siblings
`chemi_opera` and `chemi_predictor_models_predict`. The reviewed routes are
`GET /api/opera` and `POST /api/opera` in `chemi-opera-prod.json`, and
`GET /api/predictor_models/predict` and `POST /api/predictor_models/predict`
in `chemi-predictor_models-prod.json`.

Both POST schemas have two `oneOf` body alternatives. The development callback
`prediction_body` renders the existing non-NULL shape check from each schema's
required-field sets, then compacts schema properties in public input order.
Exactly one of smiles or chemicals must be supplied; the predictor also
requires a non-NULL model ID. The original error message, explicit JSON body,
NULL omission, scalar/empty/FALSE/zero acceptance, and field order are preserved.
OPERA's cache_only body field and format/standardize query fields retain their
defaults and explicit NULL behavior. Both GET wrappers retain their options
and transport settings. No new behavior correction is introduced. Public
signatures, experimental badges, documentation, examples, namespace output,
helper defaults, and returned objects are unchanged.

The contract, prediction regression, request-edge, and hook suites passed.
The focused regression has 122 assertions. Four superseded generated legacy
tests were retired, and the legacy generator check passed. All 1249
installed-client localhost cases passed with zero candidate failures and
preserved all 409 exported signatures and helper signatures. The 40 cases
added for this group matched exact requests, returned objects, warnings,
and errors. They cover both POST shapes, encoding, empty/FALSE/zero values,
OPERA controls, neither/both body shapes, NULL or missing model IDs, HTTP 400,
and both GET siblings. The prior resolver and options corrections remain
recorded separately in `verify-runtime.R`.

The disposable snapshot `ad813f74` contains the existing uncommitted work.
Its rehearsal removed all 224 allowlisted files and regenerated 260 wrappers.
Regeneration, a second apply, and check were byte-identical. The original
branch, index, and unrelated work were preserved. The inventory, allowlist,
and dispositions now reflect this wave. Evidence is recorded in
`wave-prediction-bodies.json` and `runtime-prediction-bodies-results.json`.
Two more #337 entries are complete; 17 remain to review. Both GET siblings
were also migrated to preserve whole-file ownership.

## Explicit request-body builders (#337)

The `request-bodies` wave generates `ct_chemical_msready_search_by_mass_bulk`
and `epi_submit_batch`, plus the grouped GET sibling
`ct_chemical_msready_search_by_mass`. Reviewed schema routes are
`POST /chemical/msready/search/by-mass/` and
`GET /chemical/msready/search/by-mass/{start}/{end}` in
`ctx-chemical-prod.json`, and `POST /api/submit/batch` in
`epi-suite-prod.json`.

The mapper now recognizes `request_body <- list()` followed by direct or
NULL-guarded field assignments, using the existing `compact_object` binding.
The existing `search_equal_batch_limit` callback preserves the environment
setting and fallback of 1000. Both explicit bodies still bypass query batching
and send one request. Public field order, defaults, required-argument errors,
NULL omission, FALSE/zero/empty values, helper defaults, authentication,
response handling, experimental badges, documentation, examples, and namespace
output are preserved. The small `mass_range_path_params` development callback
emits the original `c(end = end)` expression. The GET public `end = NULL`
default remains optional despite the schema requiring both path parameters.

EPI discrepancy disposition: the schema requires an array of 1-100
`BatchEstimateRequest` objects, but the public wrapper builds one object from
73 public fields. This migration generates that existing object without wrapping,
batching, or additional schema validation. The wrapper also retains its
current default `ctx_burl` server and `auth = TRUE`, even though the reviewed
schema route belongs to EPI. Correcting these public request policies requires
separate API review. The discrepancy is recorded in `dispositions.json` and
`wave-request-bodies.json`; no behavior correction is introduced here.

All 1152 contract and regression assertions passed, including 51 focused
assertions. The focused suite covers all body fields in original order,
omitted and explicit NULL inputs, FALSE/zero/empty values, missing arguments,
batch-limit defaults and overrides, and optional GET path parameters.
Three superseded legacy generated tests were retired; the legacy generator
check passed. Roxygen output and namespace output are unchanged. The prior
resolver query and public-options corrections remain recorded separately in
`dev/specmill-full/verify-runtime.R`.

The installed original and migrated clients passed all 1291 localhost cases
with zero candidate failures. The 42 new cases matched exact requests, objects,
warnings and errors, including JSON precision, empty accumulators, GET start
encoding, the existing reserved-end URL parsing error, and HTTP 400 responses.
All 409 exported signatures and all four helper signatures are preserved.
The existing verifier ran the independent clients concurrently; its comparison
and prior-correction assertions were unchanged. Results are recorded in
`runtime-request-bodies-results.json`.

The final disposable snapshot `b47f3d8d` removed all 226 allowlisted files
and regenerated 263 wrappers. Regeneration, a second apply and check were
byte-identical. Evidence is recorded in `wave-request-bodies.json`.

The inventory, removal allowlist, dispositions and wave evidence are updated.
The mirror-selection plan and all unrelated uncommitted work were preserved.
Two more #337 entries are complete; 15 remain to review. The GET sibling was
also migrated to preserve whole-file ownership.

## Bulk resolver compatibility (#337)

`chemi_resolver_lookup_bulk` now has an explicit supported mapping for
`chemi-resolver-prod.json POST /api/resolver/lookup` and a fixed helper-call
contract in `specmill-rebuild-contracts.rds`. Its disposition is
`retained_mapped`, using specmill's existing `implementation: existing` policy.
The stable handwritten source is byte-identical and remains outside the
removal allowlist. Specmill checks its public signature and generates the
fixed contract test. The prior generic legacy test was retired.

The wrapper is a shared resolution root for compound, descriptor, hazard and
WebTEST hooks and the resolve-then-POST wrappers. It rejects NULL/length-zero
`ids` before evaluating any other argument or entering `generic_chemi_request`,
then calls `as.character`. It retains `idsType`, `fuzzy` and `mol` options even
when explicitly NULL, but omits NULL `filters` and `format`. The helper keeps
identifiers in an array through `I(query)`, deduplicates and removes NA/blank
values, merges options at the top level and sends one request. The original
helper defaults, caller `tidy`, defaults, field order, scalar/FALSE/zero/list
acceptance, missing-argument errors, badges, documentation and authentication
are preserved without imposing schema enum/type validation.

A prototype rendered by pinned specmill 0.1.8 confirmed why generation was
rejected. Request-binding callbacks run after `params <- list(...)` and inside
the helper invocation. With a query callback, NULL ids enter the helper before
raising the original guard error. With `idsType = stop("option evaluated")`,
parameter capture raises that option error before checking NULL ids, whereas
the original raises `ids must be a non-empty character vector` without
forcing the option. The probe results are recorded in `wave-resolver-bulk.json`.
A generated replacement needs reviewed guard/coercion support before public
parameter capture; callbacks inside helper arguments do not preserve that
boundary. No runtime hooks or callbacks were added for this retained mapping.

All 1360 contract, regression and hook assertions passed with no failures,
errors or warnings. The resolver/caller suite has 128 assertions, including
45 direct resolver assertions. Tests cover the guard before helper/option
execution, coercion, mixed NULL options, FALSE/zero/empty/nested values,
field order, no environment-driven batching, returned objects, and the shared
resolution callers. The legacy generator check passed.

All 1317 installed-client localhost cases passed with zero candidate failures.
The 26 new bulk-resolver cases matched exact requests, returned objects,
warnings and errors. They cover singleton-array serialization, numeric/logical/
factor/list coercion, duplicate/NA/blank filtering, encoded identifiers, default
and mixed NULL/FALSE/zero/empty/nested options, unknown enum passthrough, raw
results, environment batch settings, missing/NULL/empty ids, and HTTP 400.
All 409 exported signatures and all four helper signatures are preserved.
Results are recorded in `runtime-resolver-bulk-results.json`.

The disposable snapshot `8ff314c1` removed all 226 allowlisted files and
regenerated 263 wrappers. Regeneration, a second apply and check were
byte-identical. The retained resolver source was never deleted and its hash
remained unchanged. Evidence is recorded in `wave-resolver-bulk.json`.

The inventory, dispositions, removal allowlist and wave evidence are updated.
Prior intentional corrections remain recorded separately in
`dev/specmill-full/verify-runtime.R`. The original branch and unrelated work,
including the mirror-selection plan, were preserved. This completes one
retained #337 disposition; 14 entries remain to review.

## Resolver, classification and RQ transformations (#337)

The `resolver-transformations` wave reviews three more entries and records each
as `retained_mapped`, with fixed Specmill contracts and byte-identical source:

| Wrapper | Schema | Exact operation key | Mapping service |
| --- | --- | --- | --- |
| `chemi_resolver_getsimilaritymap` | `chemi-resolver-prod.json` | `POST /api/resolver/getsimilaritymap` | `chemi-resolver-prod-rebuild` |
| `chemi_classyfire` | `chemi-amos-prod.json` | `GET /api/amos/get_classification_for_dtxsid/{dtxsid}` | `chemi-amos-prod-full` |
| `chemi_safety_rqcodes` | `chemi-safety-prod.json` | `POST /api/safety/rqcodes` | `chemi-safety-prod-rebuild` |

These keys were checked against the schema path/method definitions and parser
operations, then against the literal helper calls. The supported ClassyFire
route is also mapped by `amos-pilot` for its separate public wrapper. The five
upstream-blocked AMOS entries are excluded from this wave.

Similarity-map starts with `chemicals=NULL` in its pre-hook parameters. The
registered chain in `inst/hook_config.yml` resolves through the retained shared
`chemi_resolver_lookup_bulk`, retries without `idsType` on resolver failure,
keeps only FOUND records, selects chemical fields in the original order with
retained NULL values, clears query to NULL, and flattens the nested chemical
records. These primitives live in `R/hooks_compound.R`; their sibling callers
are covered by the existing resolution, descriptor, hazard and WebTEST tests.
There are no other direct production callers of these three public wrappers.
The wrapper returns a skip result immediately, without a request or post hook.
It applies partial parameter updates, omits only NULL section, serializes sort
with `tolower(as.character())`, and calls `generic_chemi_request(tidy=FALSE)`.
The helper uses default `chemi_burl`, auth=FALSE and wrap=TRUE, retains NULL
chemical fields, omits NULL URL parameters and preserves HTTP failures.

The schema's `PubchemRequest` declares `chemicals` and a top-level `section`;
the original helper places section inside `options`. This wave preserves that
existing request. Its required boolean sort also keeps the public FALSE default
and permissive NULL/zero/string behavior. The post-hook state contains the
updated public parameters and excludes chemicals. The registered formatter
returns a named matrix, molecule-name tibble and hclust object for cluster,
row-major off-diagonal pairs for long, or the unchanged response for raw.
NULL format and method use the original defaults; invalid choices retain the
post-hook error class. `hook_registry.R` still owns hook chaining/error wrapping.

ClassyFire uses `generic_request` with GET, batch_limit=1, chemi_burl and
auth=FALSE. Query normalization, deduplication, URL encoding, sequential requests,
tidy binding and request errors remain in that helper. For nonempty results,
its `any_of` selection preserves available query/value/sid aliases under dtxsid
and selects kingdom, superklass, klass and subklass in that order, renaming the
last three. Multiple identifier columns retain dplyr's dtxsid1/2/3 naming.
Empty data frames return unchanged; malformed NULL helper results retain their
original error. The wrapper has no lifecycle badge and invokes no hooks.

RQ codes has no parameters or hook calls. It passes explicit `query=NULL` to
`generic_chemi_request`, which rejects an empty query before constructing or
sending an HTTP request with `Either query or chemicals parameter must be
provided.` The schema requires a Chemical array; changing this call or signature
requires separately authorized correction. Mocked helper responses exercise its
otherwise unreachable transformation: pluck rqCode, compact missing records,
return NULL when empty, bind tibble rows, split rq on a space, remove parentheses
and commas, then convert pounds/kilograms to numeric. Field order, FALSE/zero
metadata, malformed split errors and numeric-coercion warnings are preserved.

`probe-transformations.R` replays the pinned 0.1.8 rendering probes using existing
bindings and the existing choice-default callback. Similarity-map generation
omits chemicals from the initial pre-hook state; ClassyFire returns the original
column names and extra fields; RQ codes returns the raw list instead of a tibble.
Results are recorded in `wave-resolver-transformations.json`. No hooks were added
to force generation, and the toolkit pin and prior intentional corrections in
`verify-runtime.R` are unchanged. Retained mappings generate contract tests,
not replacement wrappers, and remain outside the removal allowlist.

The installed original and candidate both pass the 92 focused regression
assertions. The contract, regression, caller/hook, helper and legacy stub
suites pass 1,651 assertions with zero failures, errors or warnings. The
legacy generator check passes. The installed-client localhost comparison
passes all 1,353 cases, including 36 new cases for these wrappers, with zero
candidate failures. It compares exact wire bytes, authentication, classes,
objects, warnings/errors, all 409 exported signatures and helper signatures.
The 12 prior query corrections and 14 options corrections remain separately
asserted by `verify-runtime.R`. Evidence is in
`runtime-resolver-transformations-results.json` and
`wave-resolver-transformations.json`.

The isolated snapshot `95b83b4c` deleted all 226 allowlisted files and rebuilt
263 generated operations. Regeneration, second apply and check were
byte-identical, with no differences. The three retained source files were
excluded from deletion and kept their original hashes. The inventory,
dispositions, removal allowlist and wave evidence are updated. This completes
three more #337 entries; 11 remain, including the five upstream-blocked AMOS
entries. The mirror-selection plan remains uncommitted and unchanged.

## Custom transformations (#337)

Reviewed `chemi_toxprint`, `chemi_functional_use` and `chemi_safety_section`
from original wrappers through helpers, imported request builders, hook registry,
callers and exact schema operations. There are no lifecycle badges or hook calls
in these three wrappers. `probe_api_function` categorizes functional-use and
safety-section as legacy probes; its caller tests and exported utility contracts
are included in verification. Public signatures, source, documentation and
imports are unchanged.

ToxPrint's exact key is `chemi-toxprints-prod.json POST /api/toxprints/calculate`.
The pinned native parser rejects its binary `files[]` query parameter and nested
`request` query object, reporting `binary_parameter`, `review_required` and
source location `#/paths/~1api~1toxprints~1calculate/post/parameters/0/schema`.
This requires source contract review (#16); it does not establish schema validity.
`blocked-toxprint.yml` is an inactive proposal, not an adopted mapping. Original
behavior remains: `generic_chemi_request` receives ordered OR/PV1/TP options,
retains explicit NULL/FALSE/zero, uses its existing default transport and returns
with helper visibility. Query rejection precedes forcing lazy options. The
schema differs from this existing chemicals/options payload; no correction is
made. Regression and localhost cases cover this preserved behavior despite the
parser blocker.

Functional-use's exact key is `chemi-amos-prod.json GET
/api/amos/functional_uses_for_dtxsid/{dtxsid}`. This supported operation is
separate from the five excluded upstream-blocked AMOS entries. Its direct httr2
requests validate nonempty character input, preserve duplicate/blank/NA values,
and append identifiers literally to the path. Invalid URLs containing spaces
send no request; sequential `on_error='continue'` swallows their errors and
returns an empty data frame. Authentication and retries are absent. CLI messages
and progress are unconditional; run-debug returns the first dry run. Normal
JSON parses to a list and currently fails `jsonlite::flatten` with
`is.data.frame(x) is not TRUE`. Unqualified `list_c` is also unavailable in the
namespace. Mocked parsing/utilities exercise the otherwise unreachable named
`dtxsid,functional_classes` tibble transformation, retaining FALSE/zero.

Safety-section's exact key is `chemi-resolver-prod.json GET
/api/resolver/pubchem-section`. Section validation precedes forcing query,
including omitted arguments and native errors. Ordered URL parameters are
query, idType=DTXSID, section. Duplicates and FALSE/zero survive; empty query
creates no requests and returns NULL. There is no debug shortcut, auth or retry.
All failed responses return NULL. Normal named JSON currently fails inside
`resps_data` with `Can't merge the outer name` before reaching the unavailable
unqualified `list_c`, `keep_at` and `discard_at`. Copied original closures with
mocked collaborators exercise section naming, Value extraction and Markup
removal without adding bindings to the package namespace. Existing failures,
messages and returned classes remain unchanged.

Pinned rendering probes return raw response lists rather than the originals'
empty data frame/NULL. The toolkit also rejects `req_perform_sequential` as a
client helper because it is imported from httr2 rather than defined in `R/`.
The two supported operations therefore have explicit `retained_direct` mappings
in `screen-results.json`, consumed by inventory and dispositions, with frozen
handwritten request-builder contracts. Their YAML proposals remain outside
active `specmill.yml`. No shim or hook was introduced to force generation.
Neither direct wrapper nor blocked ToxPrint is on the removal allowlist.

The installed original passes all 85 focused regression/contract assertions.
The candidate's contract, regression, caller/hook, request helper and legacy
stub suites pass 1,824 assertions with no failures, errors or warnings. The
legacy generator check passes. Prior intentional corrections remain unchanged
in `verify-runtime.R`; the toolkit pin and mirror-selection plan are unchanged.
This wave generates zero wrappers, retains two mapped wrappers and records one
parser-blocked wrapper. Nine #337 entries remain: five upstream-blocked AMOS
entries, this ToxPrint parser blocker and three unreviewed entries.

The isolated snapshot `febc39b6` deleted 226 allowlisted files and rebuilt
263 operations. Regeneration, second apply and check were byte-identical.
All final generation inputs and allowlisted file bytes match that snapshot.
All three reviewed source files retain their original hashes.

The installed original/candidate localhost comparison passes all 1,396 cases
(including 43 new cases), with zero candidate failures. Exact wire requests,
returned objects/classes, errors/warnings, 409 exported signatures and helper
signatures match, apart from the previously recorded 12 query and 14 options
corrections, which remain separately asserted. Evidence is recorded in
`runtime-custom-transforms-results.json` and `wave-custom-transforms.json`.
