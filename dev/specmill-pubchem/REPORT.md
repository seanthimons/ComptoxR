# PubChem migration wave, retained on released v0.1.41

This wave is blocked, not adopted. The three public facades remain byte-for-byte
at root `341b8526`: `R/pubchem_properties.R`, `R/pubchem_search.R`, and
`R/pubchem_synonyms.R`. Their names, files, formals, caches, lazy evaluation,
results, attributes, warnings and transport are unchanged. There are no new API
wrappers, helpers, hooks, executor changes or generic_pubchem_request patches.
No parent checkout, shared progress ledger, PR checkpoint, pin, exports,
production schema snapshot, generated ownership or documentation was changed.
No ComptoxR push was performed.

## Released-generator blockers

- [Specmill #174](https://github.com/seanthimons/specmill/issues/174) needs
  generator-owned cache lookup, early return, uncached-CID partitioning, routing
  and store/final projection. A pure response projection cannot prevent HTTP,
  select the uncached remainder before chunking, or mutate the session cache.
  Existing facades do not have hooks; inventing cache hooks would change their
  lifecycle. `prepare` is a development callback. `cache` is an unknown operation
  setting in the exact official release.
- [Specmill #175](https://github.com/seanthimons/specmill/issues/175) needs the
  original real httr2 throttle policy, capacity=4 and fill_time_s=1. The official
  native emitter has no throttle option. `request_controls.throttle` is rejected
  by mapping validation. Directly passing that field to the native helper is
  ignored and yields a request without a throttle realm. No sleeps or helper
  edits were substituted.
- [Existing #157](https://github.com/seanthimons/specmill/issues/157) separately
  limits unbatched final formatters. No duplicate issue or fake fan-out was made.

Both new issues include affected operations, old/released behavior and minimal
reproductions, and are linked from PR345:
[cache comment](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6253354238),
[throttle comment](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6253414761).
The official release was independently checked against source
`05862bee1804806cea157ff1962300d741516301` and reproducible git-archive SHA256
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.
Private PR167 code was not used.

## Source review and scope

There was no existing PUG REST config or schema. `pug-rest-original.md` preserves
verbatim bytes from the [official NCBI Markdown source](https://pubchem.ncbi.nlm.nih.gov/pcfe/docs/markdown/pug-rest.md).
The HTML docs failed Firecrawl retrieval; the official Markdown URL succeeded
with HTTP200. `source-ledger.json` records URL, retrieval timestamp and SHA256 of
both original and derived source. `build_source.py` reproduces the complete,
self-contained OAS3.0.3 `pubchem-reviewed.json`. This is a client-authored prose
translation, not an NCBI-published OpenAPI snapshot. Its full text is the exact
reviewable proposed source addition; no canonical source edits are involved.

The selected contract has three public operation families and six HTTP
operations: GET/POST CID search, GET/POST property tables, and GET/POST synonyms.
Search GET namespaces are name/inchikey/formula; POST namespaces are smiles/inchi.
POST input is application/x-www-form-urlencoded. CID POST fields are comma
separated. Property sets are comma-separated path fields. The source does not
invent a server maxItems=100 rule; that is existing client batching policy.
Response objects stay open, allowing actual nullable/extra fields. Original
property aliases and public allowlist remain untouched.

**Adopted endpoints: 0 of the 6 separately reviewed operations.** This source
review does not add six endpoints to any canonical denominator. The parent owns
that decision. The standalone generator probe uses six explicit `probe_*`
operation names only in a disposable project to test source support. These are
not public facade replacements and are never written into ComptoxR.

## Evidence and checks

`test-pubchem_retained_http.R` compares frozen root implementations with current
functions using independent caches and an actual localhost server. All 77
assertions pass. It compares complete returned R objects and warning classes and
messages without removing attributes. Coverage includes whole-cache hits before
server resolution, partial-cache routing, cached-before-fresh order, duplicates,
150 CIDs split over two POSTs, SMILES form encoding, query GETs, raw/tidy synonyms,
validation-before-default forcing, cached empty search results, received404/401
Faults, Fault in HTTP200, invalid JSON and absent success envelopes.

The entire `pubchem` test selection passes **181 assertions, zero failures,
warnings or skips**, including the retained helper-boundary tests and the
`util_pubchem_resolve_dtxsid` caller. Full raw output is `test-output.txt`.
The fixed fixture `tests/testthat/fixtures/pubchem-retained-originals.rds` contains
original expressions and SHA256s. `freeze.R` deliberately requires the original
root HEAD before creating it again.

`probe_transport.R` checks the exact official helper scaffold without modifying
it. `transport-evidence.rds` records identical original/native URL bytes but
missing native throttling. Its one success-only request-capture mock honors the
request's actual HTTP error predicate. Failure behavior in the retained suite
uses real HTTP. Real httr2 sequential execution is untouched.

`probe_live.py` made seven public read-only controls. All returned HTTP200 with
positive success envelopes and no Fault: name, SMILES and InChI searches; scalar
and bulk property requests; scalar and bulk synonyms. Exact requests, response
bytes and retrieval timestamp are in `live-evidence.json`. These are independent
wire-contract controls, not evidence that a generated facade with caches works.
No production mutations, uploads or CTX secrets were involved.

The official v0.1.41 whole-client plan with `validation = TRUE` passes with
zero operation, mapping, retained diagnostics and drift. Its only proposed root
file change is `.specmill/manifest.json`. The root remains pinned to v0.1.40;
that manifest/pin/helper integration is parent-owned and was not applied here.
The generator prints a 20-warning summary on the existing whole-client setup;
this is not a warning-free whole-client claim. Archived invalid schema reports
remain visible for retained operations.

The separate six-route source passes OAS3 validation and public generation,
apply, then a fresh public `mode = "check"` with every managed file unchanged and
zero operation/mapping/drift diagnostics. Official generation owns the six
probe files only in its disposable project. `source-freshness.rds` records these
plans and ownership hashes; `verification.rds` records the official toolkit,
source review and full root plan. `full-generation-output.txt` is the raw output.

No full-root freshness result is claimed for the v0.1.40 pin. An auxiliary
v0.1.40 library lacked source-provenance metadata; its read-only check was discarded rather than counted. Its partial output is preserved in
`discarded-v40-check-output.txt`. `check_pinned.R` is the reproducible check for a
library verified against the unchanged root lock. The accepted candidate checks
use only the independently verified official v0.1.41 library. Full-root v0.1.41
freshness remains parent-owned together with the expected manifest/pin/helper
integration. This wave's standalone source freshness passed.

The first full root attempt failed with ENOSPC on the shared /tmp tmpfs. That
failed output is preserved in `failed-full-generation-enospc.txt`; the concurrent
baseline attempt exited1 with empty output, preserved separately. Successful
reruns used a dedicated persistent workspace TMPDIR set before launching R.
Remaining R invocations and the reproduction commands use
`/home/sxthi/.cache/comptoxr-pubchem-345/tmp`. No library changed during retries.
No full package build/check was run.

## Reproduce

From this checkout with independently installed toolkit libraries. Set TMPDIR to
a dedicated persistent directory before launching R:

```sh
mkdir -p /home/sxthi/.cache/comptoxr-pubchem-345/tmp /home/sxthi/.cache/comptoxr-pubchem-345/check
export TMPDIR=/home/sxthi/.cache/comptoxr-pubchem-345/tmp
python3 dev/specmill-pubchem/build_source.py
Rscript dev/specmill-pubchem/check_pinned.R /path/to/library-matching-dev-specmill-lock
Rscript dev/specmill-pubchem/verify.R /path/to/official-v41-library
Rscript dev/specmill-pubchem/verify.R /path/to/official-v41-library --source-only
Rscript dev/specmill-pubchem/probe_transport.R /path/to/official-v41-library
Rscript -e 'testthat::test_local(filter="pubchem", stop_on_failure=TRUE)'
```

`probe_live.py` is optional and repeats public network requests. The default
verification and tests do not need production access. Upstream must release
support for both new gaps before adopting facade mappings and updating the
parent's pin/helper/ownership. A successful low-level source generation does
not establish facade parity.
