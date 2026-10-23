# Search and safety retained-facade review

Base: ComptoxR `341b8526`, PR345. Private worktree:
`/tmp/comptox-search-safety-341b8526`, branch `candidate/search-safety-v41`.
Only `chemi_search` and `chemi_safety_rqcodes` were reviewed. Neither can be
adopted on the released generator while preserving the requested contracts.
The original wrapper bytes, signatures, exports, docs, active mappings, helpers,
contract fixtures and ownership remain unchanged. No endpoint-count increment.
No push, production write or upload.

## Exact released source

Specmill 0.1.41 source `05862bee1804806cea157ff1962300d741516301` was archived
from the local upstream Git object and installed into this private worktree's
`dev/specmill-pilot/artifacts/toolkit-library`. Its SHA256 matches
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.
The installer checked installed version, source revision and source checksum.
Official release verification was supplied by the parent/user; this review
independently verified the reproducible source archive, not a second release download.
No pin or helper changes are part of this commit.

## Search hold

[Specmill #173](https://github.com/seanthimons/specmill/issues/173), linked from
[PR345](https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6253253185).
Changing only the retained mapping's implementation to generated reproduces four
observable differences on released v41:

- `all_pages` enters initial hook params, unlike the original 16-field state.
- It is forced before pre hooks, even when a skip should leave it unevaluated.
- A partial hook update can replace the transport's `all_pages`; the old wrapper
  uses the original public argument.
- A NULL result retains a named result slot; the old `$result <- NULL` removes it.

The archived candidate preserves other state fields, but those differences still
break hook replacement and lazy callers. Native generated paging additionally
adds public controls and executes hooks per page. Search requires the original
17 formals, numeric body-offset advancement, one pre/post cycle, and complete
pre-hook return state after combined transport. Released combined-post support
requires a batch and parameter state. It does not solve this facade's full-state
paging contract. No synthetic hooks or fan-out were introduced.

`generated-search.R.txt` archives the released renderer output outside `R/`;
only trailing space on a blank roxygen line is normalized. `verify.R` regenerates its parsed expression from the active mapping
and asserts the four differences using independent frozen original/candidate calls.
It uses private Specmill inspection functions solely for this reproduction;
package generation and freshness checks use public `generate_client`.

## Safety hold

[Existing PR168 comment](https://github.com/seanthimons/specmill/pull/168#issuecomment-6253252790).
The unbatched final formatter remains rejected in released v41. The archived
reproduction reaches that renderer guard with an existing client function name;
it never invokes that placeholder formatter or installs an unreleased change.
A native response-policy projection can format a response, so the unbatched
formatter enhancement alone is not proof of an unavoidable native blocker.

The separate unresolved contract is substantive: `chemi_safety_rqcodes()` has no
arguments and calls the old helper with query=NULL. Normal calls raise the original
cli empty-query error before HTTP. Its rqCode/compact/row-bind/split/unit conversion
is observable with a replacement helper. There is no reviewed chemical input to
send from the original zero-input signature. An unconditional error-only native
wrapper, arbitrary Chemical array or fake hook would not finish the migration.
Retain this wrapper until an explicit input-contract decision and released
formatting support can be verified together.

## Read-only live evidence

`evidence.rds` contains request objects, timestamps, status and response bodies for
production `https://hcd.rtpnc.epa.gov/api` and staging
`https://cim.sciencedataexperts.com/api`, plus frozen source expressions, the exact
candidate expression and hashes of the untouched canonical schema files.
No credentials are stored or printed.

Both services returned HTTP200 and **755 records** for the exact legacy mass
body with params.limit=1 and no top-level limit. Both returned HTTP200 and one
record for the schema-shaped string-valued params with top-level limit=1.
This corrects the earlier session update's premature 100-record description.
The first exploratory request used incorrect camelCase mass parameter keys and
returned500. It is archived as a rejected control, not successful source evidence.
No body correction was adopted while #173 holds the wrapper.

Safety SID-only arrays returned200 with a Chemical and no rqCode. Production []
returned200/[]; staging [] returned400 requiring 1–1000 chemicals. A CAS-only
formaldehyde array returned production500 and staging400 requiring chemical.sid.
The first mixed SID/CAS request contained inconsistent chemical identifiers and
is preserved as an exploratory control, excluded from positive chemical evidence.
No populated live rqCode or safe replacement for the no-input facade is claimed.

## Checks

The permanent `test-retained_search_safety.R` suite covers exact pre/post states,
partial updates, lazy skip, NULL key presence, original paging control, the
zero-input safety error before transport, rqCode conversion/empty/error/warnings,
and actual localhost HTTP. Localhost cases capture POST path/content type/body,
first/second offset bytes, single/paged results including all attributes, partial
received500, single404/500 response-bearing conditions, malformed JSON before
post, and malformed record conditions after post. Real httr2 execution remains
in place, including `req_perform_sequential`; no attributes are stripped.

The existing search/helper/fixed-contract suites pass in the CRAN-safe lane.
The final new suite passes all 58 assertions with no skips, failures or warnings;
`test-results.rds` records its per-test counts. This is focused retained-contract evidence, not a full package
check or evidence that migration is complete. Full generation/freshness results
are recorded in `generation-checks.json`. The first apply completed and changed
only private manifest metadata; its outer harness then incorrectly rejected that
expected manifest write. The corrected guard permits that metadata-only change,
and the independent fresh public check establishes final freshness. Temporary
root pin/manifest metadata is restored before the evidence commit.

Reproduce the generator differences with the isolated v41 library installed:

```sh
Rscript dev/specmill-rebuild/search-safety-v41/verify.R
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(retained_search_safety|chemi_search|chemi_search_helpers|contract-chemi_search|contract-chemi_safety_rqcodes)$", stop_on_failure=TRUE)'
```

`verify.R` constructs a temporary verification lock from the archived pin. It
never changes the parent-owned root pin. `generation.R apply` and then
`generation.R check` use the same archived provenance for whole-client public
generation with validation=TRUE; apply may refresh private manifest metadata. The shared REPORT/progress/checkpoint
files were not edited.
