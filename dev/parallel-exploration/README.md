# Parallel request exploration

Branch: `explore/specmill-parallel-services`.

The pinned Specmill 0.2.3 revision already supports bounded parallel HTTP
batches. On 2026-11-10, fetching upstream found 0.2.4 at
`c72a934`; its R implementation is identical to the pin. No pin bump is
needed to explore concurrency.

Run from the package root:

```sh
Rscript dev/explore_parallel.R         # offline generation and assertions
Rscript dev/explore_parallel.R --live  # also make small read-only probes
Rscript dev/explore_parallel.R --post  # local POST transport assertions
Rscript dev/explore_parallel.R --post --live # also probe four CTX POST searches
Rscript dev/explore_parallel.R --extended --live # larger chunks and failure cases
Rscript dev/parallel-exploration/assess-extended.R --aed-control # compare records and capture sequential AED control
Rscript dev/parallel-exploration/assess-extended.R # replay captured assessment offline
Rscript dev/parallel-exploration/probe-native-policies.R # generated failure-policy matrix, no network
Rscript dev/parallel-exploration/reproduce-mapped-batch.R
Rscript dev/parallel-exploration/diagnose-chemical.R # capture repeated sequential POST results
Rscript dev/parallel-exploration/diagnose-chemical.R --replay # reproduce captured mismatch offline
```

The experiment copies tracked generation inputs into a disposable directory,
enables `batch.concurrency: 2` on compatible existing batches, and asserts
that the emitted wrappers contain concurrency support and retain their public
arguments. Production wrappers, API configs, dependency declarations, and the
Specmill pin stay unchanged. Documentation generation is disabled in the copy.

`inventory.json` records each existing batched operation, its schema and
whether it can use concurrency without changing its request mapping.
Eligibility alone says nothing about a provider's capacity or acceptable rate.
`live-probes.json` records diagnostics and sequential/parallel result equality
for representative GET routes. No credentials or response bodies are stored.
CTX probes require `ctx_api_key` in the R environment. Empty results and invalid
test identifiers cannot establish useful service support. A failed sequential
baseline makes a parallel failure inconclusive.

`post-probes.json` records the POST experiment separately. It sets `batch_limit`
to one for the test process and uses three distinct identifiers plus a duplicate.
The existing input policy removes duplicates before batching, so each call
must send three POST chunks. The local delayed HTTP fixture tests
actual overlap, input ordering after out-of-order completion, duplicate
removal, a dropped 404 chunk, and stop-on-error behavior. Chemical detail
intentionally removes failure metadata; Hazard preserves it. These released
differences are checked against the original sequential wrappers.

Local tests use a dummy credential and force HTTP/1.1 for the HTTP fixture.
Live tests restore the real environment and normal transport, and use a
two-requests-per-second throttle with zero retries. They call only search
operations, with no mutations or job submission. No credentials are stored.
The original smoke probes retain diagnostics only; the focused and extended
diagnoses below save public response bodies and tables, with no request headers.

## Findings

The offline experiment successfully generated parallel versions of 131 of the
151 existing batched operations, with no public-argument drift. The remaining
20 use explicit request mappings blocked by Specmill. Those include all of the
ClassyFire group's current batching.

Representative live GET probes returned identical sequential and parallel
results without warnings for CTX Bioactivity, Exposure, Hazard, AMOS and ChET.
CTX Chemical detail succeeded in both modes. Some comparisons differed in
column order. The focused diagnosis below reproduced this with the original
sequential wrapper and traced it to JSON field order in the service response.
Comparisons should align columns by name while preserving row order. This
supports further testing at concurrency two; it does not
establish a provider's quota or sustained-load capacity. Inspect the probe
file for exact wrapper names and inputs in `explore_parallel.R`.

Toxprints' assay-by-name route returned HTTP 404 for `AMES` in both modes.
A follow-up `chemi_toxprints_assays()` discovery call returned an empty assay
list. Toxprints remains unverified until a valid fixture is available.

### POST results

Live tests covered these read-only CTX search operations:

- `POST /chemical/detail/search/by-dtxsid/`, projection `chemicalidentifier`.
- `POST /bioactivity/data/aed/search/by-dtxsid/`.
- `POST /exposure/seem/general/search/by-dtxsid/`.
- `POST /hazard/genetox/summary/search/by-dtxsid/`.

Each sequential and parallel call sent three single-item JSON array chunks.
Every chunk returned HTTP 200 without warnings. In the confirmatory run, all
four returned exactly equal tables, with the three identifier groups in input
order and nonempty results for each identifier. The supplied duplicate was
removed before sending in both modes, matching the existing input policy.

The initial Chemical POST comparison differed, with column-name and positional
component mismatches. Its diagnostics are preserved in `post-probes-initial.json`.
The repeat matched exactly; `post-probes.json` also records column names and
a comparison after aligning columns. The focused diagnosis below reproduced
the same diagnostic pattern and established a column-order cause. Consumers
should use column names rather than fixed column positions.

All six local transport scenarios passed across Chemical detail and Hazard
summary: successful batching, dropping a 404 chunk, and stopping on error for
each wrapper. The fixture observed two simultaneous POST requests and
deliberately reversed the first pair's completion order. Returned rows stayed
in input order, warnings matched sequential execution, and the wrappers kept
their existing failure-metadata behavior. On stop, all three parallel requests
had already reached the server, even though sequential execution stopped at
the failed second chunk.

The initial checks cover small read-only batches at concurrency two. The
extended checks below cover larger chunks. Sustained load, provider quotas,
and write/job-submission POST routes remain untested. Package runtime code
and shipped wrappers are unchanged.

### Chemical mismatch diagnosis, 2026-11-12

Two consecutive calls to the original sequential
`ct_chemical_detail_search_by_dtxsid_bulk()` reproduced the mismatch with
projection `chemicalidentifier` and three one-item chunks. All six responses
were HTTP 200. The tables were exactly equal after aligning columns by name,
with row order preserved. No chemical values differed.

The saved response bodies show the cause directly. One response lists
`dtxsid, dtxcid, casrn, preferredName, iupacName, inchikey`; another response
for the same identifier lists `inchikey, dtxsid, dtxcid, casrn, preferredName,
iupacName`. The returned table follows that field order.

Offline replay reproduces the same mismatch through the original wrapper.
It also reproduces with one identifier and one response per call, eliminating
the batch combiner and parallel executor. Replaying the same body repeatedly
gives the same result. The comparison-by-name self-check still rejects changed
values and reordered rows.

`chemical-diagnosis/` contains the captured public tables and response bodies
as RDS files, plus readable `summary.json` and `replay.json`. It contains no
requests, headers, or credentials. The original historical mismatch had no
body capture, so it cannot be checked retrospectively; this new capture
reproduces its exact diagnostic pattern and resolves the demonstrated concern.

This is existing service field-order variability. There is no evidence here
that enabling concurrency changes chemical data, and no generated wrapper or
runtime fix is indicated for this mismatch. The extended batch-size checks
below add coverage; service-capacity checks remain open.

### Extended checks, 2026-11-12

Live tests used 27 known identifiers from `testing_chemicals`, with chunk sizes
10 and 25, at concurrency two. The short final chunks contained seven and two
identifiers respectively. All chunks returned HTTP 200, without warnings,
across the same four CTX search routes. Sequential and parallel calls returned
the same complete record multiset for each case, including duplicate counts.
Changing chunk size also preserved the record multiset for every route.
This checks equivalence to sequential results, not that every identifier has
data available in every service.

Chemical, Exposure and Hazard also preserved row order between modes after
column alignment. AED rows varied within the result, while the complete data
matched. Two repeated calls to the original sequential wrapper with the same
ten identifiers reproduced that variation. The captured JSON response arrays
already differ in row order, and each table follows its response order.
Four earlier single-identifier control calls were stable; these are retained
in `aed-single-id-control.rds`. The multi-identifier control captures explain
the live batch difference without implicating the parallel executor.

The local HTTP fixture passed 16 scenarios across Chemical detail and Hazard
summary: success, dropped 404, explicit stop, 429, 503, timeout, 401, and all
chunks failing. Request counts confirmed no unexpected retries. HTTP 401
stopped both modes; all-failed calls returned their existing empty-table and
diagnostic behavior. The parallel call had already sent all three requests
before reporting stop/auth errors, while sequential calls stopped after two.

One existing failure-policy risk is now demonstrated: Chemical detail drops
a timed-out chunk and returns the other rows with no warning and no `failed`
attribute. Hazard returns partial rows with a warning and failure metadata.
Both behaviors are identical in sequential and parallel execution. These are
mocked timeout failures, not observed failures on the live service. No
production policy was changed.

Client timeouts also do not cancel server work. The fixture showed the timed
out request still running when the next sequential request arrived. Thus an
HTTP concurrency bound alone does not guarantee a bound on server-side work
after timeouts. Clients should avoid treating retries or timeouts as proof
that the earlier work has stopped.

`extended-post-probes.json` and `extended-assessment.json` contain the results.
The companion capture RDS files retain public result tables and response
bodies. HTTP error conditions are reduced to messages/classes before saving
because they can otherwise retain request credentials. Captures include no
request objects or auth headers. The offline assessment rejects missing rows
and changed values; it keeps the original ordered comparison alongside the
record-multiset comparison rather than silently discarding order differences.

CTX Bioactivity, Exposure and Hazard native read batches are the clearest
starting point for adoption. Keep
concurrency opt-in per operation, review hook side effects and rate policies,
and extend transport-level coverage to each adopted operation before shipping a change. The
current experiment leaves every shipped wrapper sequential.

## Constraints

- Parallel batches need httr2 >= 1.3.0, a throttle, and zero retries. The
  package currently declares httr2 >= 1.0.0. Raise that dependency before
  distributing any parallel wrappers.
- Concurrency is an operation setting, not a global batching option. Native
  fan-out and split batches qualify; unrelated wrapper calls stay synchronous.
- The experimental throttle allows two requests per second. It is a probe
  setting, not a verified service quota or a production recommendation.
- Pre-request hooks prepare every chunk before sending. Responses and
  completion hooks run in input order after transport completes. Hook side
  effects need review before adopting concurrency.
- With stop-on-error, other requests may already have completed. There is no
  rollback. This exploration sends only read-only GET and POST searches.
- Pagination, caches, custom request mappings, route guards and visibility
  preservation cannot currently combine with parallel batches.

## Upstream blocker

[Specmill #297](https://github.com/seanthimons/specmill/issues/297) tracks
support for explicit native request mappings. A verified offline reproduction
is included here. `ct_chemical_search_equal_bulk` currently splits newline
text bodies correctly; adding concurrency causes generation to reject the
operation. Keep affected wrappers on their current implementation until an
upstream release supports them and ComptoxR updates its pin.

As of 2026-11-12, #297 is closed and its mapped-batch fix is released in
Specmill 0.2.5, upstream commit `d1fd026`. ComptoxR is still pinned to 0.2.3.
The inventory and blocker reproduction above describe that pinned version;
adopting 0.2.5 and rechecking affected mappings is a separate change.

PubChem has cached wrappers and retry behavior that need their own design;
EPI Suite batch submission creates jobs and is outside these read-only probes.
Descriptor bulk endpoints accepting arrays do not automatically have
package-managed split batches. These services need separate work before they
can enter this experiment.

## Native policies and upstream follow-up, 2026-11-12

The silent Chemical timeout drop is caused by ComptoxR's explicit compatibility
configuration. `batch.metadata: false` removes the helper's `failed` attribute,
and `.ct_batch_http_warning` returns NULL for transport errors. Specmill is
preserving the requested behavior; this is not a parallel-runtime defect.

`probe-native-policies.R` emits six experimental wrappers from the real
Chemical detail API configuration into a disposable directory. It tests the
three policies below with concurrency one and two, for success, a mocked
transport exception, and HTTP 503. All 18 assertions passed, with tibble returns
preserved and no network calls or production helper/config changes.

- Existing configuration: transport failures are silent and have no metadata;
  HTTP failures retain their custom warning.
- Retain metadata only: both failure kinds identify the dropped chunk through
  `attr(result, "failed")`; transport errors still have no warning.
- Retain metadata and omit the custom warning callback: both failure kinds
  warn and identify the dropped chunk. HTTP warning text becomes the native
  default rather than the existing custom message.

A candidate configuration for a deliberately reviewed behavior change is:

```yaml
batch:
  split: true
  max_items: {env: batch_limit, default: 100}
  on_error: {single: stop, multiple: drop}
  empty: .ct_empty_table
  metadata: true
  # Omit warning to use the native warning for every dropped chunk.
```

This is a proposal, not applied to `apis/ctx_chemical.yml`. It changes observable
warnings and attributes even though the result remains a tibble. The existing
operation response policy, input normalization and other settings stay part of
the operation; this snippet is only its proposed batch policy.

Two upstream requests now cover the reusable features:

- [Specmill #303](https://github.com/seanthimons/specmill/issues/303): opt-in
  declarative output column ordering and record ordering by explicit keys.
  Preserve wire order by default; do not infer keys or drop duplicate records.
  The existing extension point is a client-owned formatter or combined hook,
  so a built-in policy would avoid duplicating sorting implementations.
- [Specmill #304](https://github.com/seanthimons/specmill/issues/304): opt-in
  fallback to the native warning when a custom formatter returns NULL. This
  would preserve established HTTP warning messages while adding diagnostics
  for unhandled transport failures. Existing suppression semantics remain
  unchanged unless the client opts in.

Basic failure visibility needs no new Specmill feature. Preserving the current
custom HTTP warning text while adding a generic transport warning is the
smaller upstream gap. Neither request needs promises or a different public
return type. Production wrappers remain on their current implementation, and
no local runtime/helper workaround has been introduced. Adoption of any new
upstream capability requires a release, pin update and explicit policy review.
