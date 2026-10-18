# PR179 exact-source independent facade replay

**Blocked, proof only.** No root production files, runtime, generator pin, mapping,
helper, ownership manifest, exports or progress count changed. No push. No deployed
service, mutation, upload or session calls. HTTP execution uses localhost and real
httr2 execution, including the retained sequential pager. Hook spies replace only
the application hook boundary to inspect replacement/skip/partial-update states.
Normal search and resolver hooks are also exercised unchanged.

Specmill PR179 source is exactly `5566da87ae5acc7a95e10eaa209dbc18a290f498`,
tree `6a24e59116121708360e44177f35c76ab16bfb38`. GitHub source archive SHA256 is
`96a72b802a7f2466ac0014fb0e86032a64944ecafaeea46eb3342cdc9e3b64fe`.
`provenance.json` records the archive URL, ComptoxR base and original production
hashes. The source archive was installed with R CMD INSTALL into a private library
under `/home/sxthi/.cache/comptoxr-pr179`; every R process used persistent TMPDIR
under that directory. This unreleased package still identifies itself as 0.1.41;
the exact archive, not the version string, identifies the candidate.

## Findings

1. Search hook state can overwrite deferred transport `all_pages`. A pre-hook
   returning `params=list(query='changed', all_pages=FALSE)` is valid in the old
   facade, which still pages using the original public TRUE argument. Candidate
   replaces the callable and errors `attempt to apply non-function` before HTTP.
2. Search NULL skip results retain a named `result=NULL` slot in candidate post
   state. Old `$result <- NULL` removes it. Both otherwise preserve the full state,
   skip lazily without forcing all_pages and run one pre/post cycle.
3. PubChem `max_pages` cannot bind the actual public or hook-updated argument.
   Both `{from: [params,max_pages]}` and a callback require binding support, whereas
   candidate accepts only a literal integer. The attempted callback mapping is
   preserved as a rejection in `pubchem-dynamic-max-pages.rds`; `generate.R`
   reconstructs it before generating the explicitly fixed-100 diagnostic candidate.
   Localhost `max_pages=1` makes one old request and two diagnostic requests.

Reported on [PR179](https://github.com/seanthimons/specmill/pull/179#issuecomment-6254290135),
with a backlink on [PR345](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6254292561).
No duplicate issue or local upstream implementation.

The actual canonical PubChem source/service hold remains independently of these
upstream gaps. Old wraps nested ChemicalRecord objects with options. Declared
service input is flat Chemical with five required query controls absent from the
public signature. Service responses use items/total; legacy paging reads
records/totalRecordsCount and returns empty on that service-shaped payload.
This replay reuses the previously archived service finding, makes no new deployed
claims, and proves the collector mismatch with a localhost service-shaped response.
Flattening the payload, supplying hidden query defaults or switching response keys
would be explicit source/service corrections, not parity. None was adopted.

Native paging writes offset=0 on the first request and requires a size field.
Search's normal size field already exists, but diagnostic PubChem additionally
gets options.limit=100. Old initial requests omit those fields. These wire
changes are recorded separately and are not described as validated service
corrections. Canonical schemas are unchanged. The diagnostic candidates do not
establish full wire parity or a working deployed PubChem wrapper.

## Checks and limits

Final focused replay: **8 tests, 105 passing assertions, 0 failures, 0 errors,
0 warnings, 0 skips**. These assertions verify both working behavior and the
observed blockers; this is not a claim that facade migration passed.

Both canonical schemas pass full `validation=TRUE` generation. Official helper
scaffold code and provenance are emitted directly without rewriting. The public
generator emits both wrappers at their exact original paths and with identical
public formals, then a fresh check reports only unchanged outputs. Both private
owned wrapper hashes match. The helper bytes and provenance independently match
a fresh official scaffold. The private project copies the original NAMESPACE;
root exports and documentation remain untouched. `verification.json` records the
hash checks, including all frozen production inputs.

Runtime checks cover actual normalization, the real resolver pre-hook, duplicate/
blank/NA filtering, empty-input errors, partial hook state, skip state, original
formals, single and paged search results including attributes, numeric offsets,
one hook cycle, partial received404/500, malformed JSON/metadata, hard401,
invalid runtime configuration, native dryrun with no HTTP/post hook, transport
failure and the diagnostic PubChem limit mismatch. Received404/500 conditions
keep response bodies. Native401 is deliberately hard `specmill_call_error`;
`runtime.rds` preserves the old outcomes for comparison, including the old paged
collector's partial recovery. That is a deliberate native policy difference.
Native dryrun is tested as its own contract; the old debug printer is not claimed
identical. Malformed metadata is a hard callback error, not a success or empty
result.

The exact source's `tests/request-pagination.R` also passes unchanged. Full
upstream checks and the whole ComptoxR package suite were not run here. Historical
reports remain historical; no full release check is inferred from focused proof.
Initial harness failures are retained and explained by their filenames: the
candidate environment initially lacked the existing server-resolver binding, and
one comparison used different hook states. The final harness binds the unchanged
client resolver and compares equal inputs. No runtime helper was patched. Official generated wrapper evidence and raw initial
logs retain their emitted trailing whitespace; git diff --check reports those
archived bytes. They were deliberately not reformatted.

## Replay and eventual integration

From the recorded ComptoxR base, with existing development dependencies and gh
access, run:

```sh
bash dev/specmill-rebuild/pr179-exact/install.sh
TMPDIR=/home/sxthi/.cache/comptoxr-pr179/tmp Rscript dev/specmill-rebuild/pr179-exact/verify.R
```

The installer verifies the full source SHA and archive checksum, installs only the
private candidate library, recreates a private project, generates officially with
full validation and freshness, and replays the tests. `PR179_CACHE` may select
another persistent location. Neither script writes package production files.
`generate.R` contains the pure generator callbacks; `policy.R` contains only
client body/response/metadata projections, with no network loop or executor.

Integration stays held. First obtain released upstream fixes for deferred control
isolation, NULL state semantics and dynamic max_pages, then resolve and explicitly
review PubChem's source/service changes. Update the parent-owned release pin only
after those releases and full checks pass. Recreate this private replay against
that release, remove the fixed-100 diagnostic restriction, regenerate root output
officially rather than copying private helpers/manifests, repeat freshness and
all owner hashes, run focused contracts and the broad package gates. Keep both old
facades until all of those conditions are satisfied.
