Released legacy-facade candidates for ComptoxR PR345

Base `cd34efb4`. The required minimum is official Specmill 0.1.42, source
`b17a0856263e0179a164a9673399f221168cda6d`. The parent verified official tar
SHA256 is `0d1be547b950fb807b1a8d027199651304fb74e30fdde9e487a3a99a10e37aa8`;
the installed source-archive SHA256 is
`dbd15b2509171431f00a193a648f426a02873aee5e16a73de740d30b56792351`.
`setup.R` checks version, source and archive metadata in the read-only private
library supplied by the parent. No active library or root pin/helper is changed.
Released v43's unbatched result formatter is unnecessary for this selection.

Eight original facades now use officially generated native calls. Public names,
files, formals/defaults, exports and experimental lifecycle are retained:

- `chemi_chet_reaction_database_old_by_pagenum_and_searchterm`, GET
  `/reaction/database-old/{pagenum}/{searchterm}`, CheT schema, `/api/chet` prefix.
- `chemi_chet_reaction_searchcounts`, GET
  `/reaction/searchcounts/{search_input}/{search_type}`, same schema/prefix.
- `chemi_stdizer_groups_recursive`, GET `/api/stdizer/groups/{id}/recursive`,
  standardizer schema.
- `chemi_stdizer_records`, POST `/api/stdizer/records`, standardizer schema.
- `chemi_resolver_resolve`, POST `/api/resolver/resolve`, resolver schema.
- `chemi_toxprints_assays_bulk`, POST `/api/toxprints/assays`, toxprints schema.
- `chemi_toxprints_chemicals_categories`, POST
  `/api/toxprints/chemicals_categories`, toxprints schema.
- `chemi_toxprints_toxprints_categories`, POST
  `/api/toxprints/toxprints_categories`, toxprints schema.

The unchanged native GET assays sibling is included in the isolated generation
because it shares `R/chemi_toxprints_assays.R`. Thus nine selected operations
represent eight migrations. No public alias is added. The raw records alias from
child161570cf is neither generated nor exported here. All other standardizer
operations are excluded.

The CheT mappings reuse the corrected `rootheldrelease` proof. The released
`validate_inputs` function seam calls the pure `.chet_validate_inputs` exactly
once on the complete normalized captured parameters before fan-out. Its return
is ignored. It reproduces the cross-input `cli_abort`, builds/parses complete
URLs without sending and preserves indexed malformed-URL errors before the
drop handler. The formatter, actual hooks, helper, `generic_request`, and real
httr2 sequential executor are unchanged. Numeric/list/duplicate/NA cleanup,
blank suffix omission, raw suffix ordering, warnings, NULL slots and original
condition class/message/parent/location are compared without stripping result
attributes or names. Native hard401/config behavior is intentional.

Recursive GET uses the existing canonical route instead of the old reversed
`/groups/recursive/{id}` route. Evidence is reused from
`../remaining-facades/recursive-live.rds`: the advertised staging group
`65e938bb76bc105c96ab1c6c` returned404 at the old route and200 with recursive data
at the canonical route. No new service call was needed. The localhost comparison
normalizes only that reviewed path difference and separately asserts the actual
canonical wire path. Error/warning endpoint labels retain the old identity.

The five generic-chemi facade projections preserve the existing payloads,
permissive inputs, eager public argument capture, compact sibling options,
empty-input errors, unbatched result structure and typed received failures.
They do not introduce identifier resolution, uploads or invented parameters.
There are no configured pre/post hooks on these eight facades at this baseline;
`hooks.yml` freezes the real registry and adds only bespoke suite registration.
No replacement hook or lifecycle event is invented. The complete original
parameter capture is retained rather than replacing it with the cleaned IDs.

Preserved behavior includes existing client defects. Resolver resolve still
synthesizes Chemical SID objects and nests queries under options rather than
using the declared ResolveRequest. Assay creation and standardizer records also
retain their original Chemical/options envelopes rather than silently changing
to Assay or StdizerRecordsRequest bodies. Category facades retain their bare Chemical
SID arrays. Canonical schemas remain byte-for-byte unchanged. These projections
prove native execution and compatibility, not successful deployed handling of
those payloads. Contract repair belongs to the existing review in
https://github.com/seanthimons/ComptoxR/issues/311. The records facade is not a
placeholder: it performs the original request and decodes normal responses.

`chemi_toxprints_bulk(query)` stays unchanged. Its configurable chunk splitting
cannot be generated on the canonical object request body. `held-bulk.yml` and
`verify-held.R` reproduce the released rejection. New upstream
https://github.com/seanthimons/specmill/issues/181 is linked from PR345 at
https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6254403045.
Its inherited CTX server/auth defaults and array body also need separate client
contract review. Scalar fan-out would change its chunk contract, so no alias,
alternate schema, helper patch or scalar-loop workaround is adopted.

The resolver/toxprints inventory has no other unexcluded literal legacy calls:
resolver getpubchemlist remains excluded under173 and similarity-list under165.
Existing zero-argument functions are unchanged. In particular the optional-body
GET ghs-list-count contract is already tracked in313/336; no required public
argument is invented. Search paging173, similarity-list165, group/upload28/31,
safety rqcodes352 and all other standardizer operations remain outside this work.

Reproduction uses persistent temporary storage:

```sh
export TMPDIR=/home/sxthi/.cache/comptoxr-facades-v42/tmp
export SPECMILL_LIBRARY=/path/to/verified/private/0.1.42
Rscript dev/specmill-rebuild/released-facades-v42/generate.R
Rscript dev/specmill-rebuild/released-facades-v42/verify.R
Rscript dev/specmill-rebuild/released-facades-v42/check.R
Rscript dev/specmill-rebuild/released-facades-v42/verify-held.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(native_released_facades_v42|chemi_public_options)$", reporter="summary", stop_on_failure=TRUE)'
```

`generate.R` requests validated official wrapper/documentation generation in a
private package copy, explicitly adopts only that copy's namespace and checks
fresh wrapper output plus every private owner hash. Only scoped wrappers/docs
are copied back. The private namespace bytes are preserved separately; root
NAMESPACE already exports every public name. The frozen original definitions
are reproducible with `freeze.R` from the base commit. Runtime tests use an actual
localhost server, real httr2 sequential execution and real transport failures.
The fixture supplies the real Chemi `/api` base suffix and identical retry
controls for both implementations, with zero Retry-After backoff. No runtime
helper, hook or executor binding is replaced by the localhost suite.

Root integration is parent-owned. Copy the operation mappings into the corresponding root `apis/*.yml` services
from `chet.yml`,
`recursive.yml` and `chemi.yml`; retire each same-named old mapping/include entry
before adding this selection. The unchanged GET assays sibling must have one
owner, sharing its existing file with POST. Load the two CheT callbacks from
`../rootheldrelease/callbacks.R` and this directory's `callbacks.R`. Merge only
`hook-additions.yml` into the live hook registry, preserving all real hooks. Its
extra ninth registration points the unchanged GET assays sibling at the existing
public-options suite. The metadata renderer otherwise emits a false
endpoint/operation assertion on this method/path call, tracked in
https://github.com/seanthimons/specmill/issues/182; no generated test is patched.
Keep `R/chet_facade_input_policy.R` and the native suite/frozen fixture. Retire
the eight stale generic-helper tests listed by this commit; the public-options
wire cases are now in the localhost suite. Adopt reviewed scoped bytes through
official generation after updating the official toolkit pin and helper. Do not
merge a child manifest or overwrite the shared registry/config with a private
snapshot. Update the root ledger only after the parent's integration gates.

`prepare-whole.py NEW_PRIVATE_DIRECTORY` builds exactly that overlay from the
base plus these candidates. In that directory, run `verify-whole.R`; its marker
guard prevents applying to the shared checkout. It validates full-client
wrapper/test generation, checks independent freshness and every private owner
hash. This is also an executable integration recipe. The base's existing source
validation reports remain visible. `audit.R` verifies canonical and parent-owned
files against the base and records hashes. Portable results/logs and final
counts are in `verification.json`. No push, deployed mutation/upload/session
call, full package test run or R CMD check is claimed.

Final scoped replay: 368 passing assertions, zero failures/errors/warnings/skips.
The CheT matrix has 518 exact comparisons out of 554; all 36 differences are the
intentional native hard401 policy. Focused preflight checks pass. Validated scoped
generation has 18 matching owner hashes and 9 unchanged fresh wrapper/namespace
outputs. The disposable whole-client wrapper/test gate has 679 unchanged fresh
outputs, 679 matching owner hashes and zero operation/mapping/retained/signature
diagnostics. Scoped documentation is independently emitted/owned above; the
whole-client gate uses wrapper/test artifacts. Its source-validation reports
remain in the raw log. Setup failures and interrupted test-fixture runs are
preserved in logs; they are not described as passing full runs.

The final legacy metadata inventory has 12 wrappers and passes its current/static
validation check. Registering the unchanged GET sibling against its already
passing six-assertion public-options suite avoids the false renderer assertion
in #182. The first generated candidate test is not adopted or hand-edited.

Whole-client validation requested TRUE: 29 source reports passed and the existing
canonical AMOS invalid-source report remains visible. No source finding is
bypassed, and this is not a whole-package test/check result.

## Root integration

The root retains the old existing service IDs for the five Chemi mappings and their native GET assays sibling. Only CheT and recursive unbound mappings receive new service files in `apis/`. Both callback files are registered, preserving public formals and the real hook lifecycle. The selected obsolete helper entries were removed from both `specmill-rebuild-contracts.rds` and `specmill-full-contracts.rds`; leaving the latter entries correctly blocked generation. Owned tests were retired through public `apply_files`. Its ownership protection preserves unowned manual tests, so the three replaced manual suites were separately frozen against HEAD and explicitly removed. The new localhost suite supersedes those exact helper mocks. No generated test or runtime is patched.

Root apply passes all 702 output hashes and leaves all 694 unrelated owner records unchanged. Root focused replay, together with the new safety SID contract suites, passes 616 assertions with zero failures/errors/warnings/skips. Initial merge/retirement failures are retained in `../v42-11-integration/`. The first broad run was stopped after exposing those three obsolete manual tests; the final restart has its own result files and is not conflated with that run. Final freshness/broad/package results follow in the integration evidence.
