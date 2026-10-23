# CheT extra native bindings

Adds 35 previously unbound operations from `schema/chemi-chet-prod.json` under
`/chemicals/`, `/curators/`, and `/reaction/`. These are new native bindings with
schema-derived signatures, not replacements for existing public wrappers.
`apis/chemi-chet-extra.yml` is deliberately not registered in root `specmill.yml`.
The parent owns registration, its pin, helper, manifest and integration checks.

Scope was selected against the current parent at
`/home/sxthi/Documents/Projects/ComptoxR`, not the child base alone. `scope.json`
records the exact parent configuration/service hashes and bound operation keys.
`cases.json` records the selected canonical operations and independent fixture
inputs are built by `build-fixture.R`. The child started at `341b8526`.

Excluded from this wave:

- Every operation already mapped by the parent, including its four new direct reads.
- `GET /chemicals/chemical_DL`, completed in `96b2799f` using a reviewed OAS3.1
  source subset. The new POST binding ends in `_post` to reserve the GET name.
- The two reaction searches held for Specmill #166 and unreleased PR167.
- `GET /chemicals/chemdelete`. The canonical OAS3.0.3 declaration has an optional
  JSON body, which generation ignores under that dialect. There is no authorized
  positive read-only deployment proof for this mutating GET, so the reviewed
  correction used for the download in #171 cannot be applied here. No bodyless
  wrapper or schema correction is shipped.
- Admin/auth prefixes. Curator login/logout remain in the requested curator
  prefix and are exercised only against actual localhost.

No selected operation has a scalar boolean query affected by #177. Visibility's
boolean is declared in JSON. The two file inputs are declared multipart binary
parts. No query-to-upload reinterpretation or new upstream correction is used.
Canonical schemas are unchanged. The open object bodies use permitted arbitrary
properties in fixtures; this tests their declared wire contract, not deployed
application rules. No new generator gap was found.

Reproduce from the repository root:

```sh
mkdir -p "$HOME/.cache/comptoxr-chet-extra/tmp"
export TMPDIR="$HOME/.cache/comptoxr-chet-extra/tmp"
# Optional: SPECMILL_V41_LIBRARY points to another verified released v41 library.
Rscript dev/chet-extra/build-fixture.R
Rscript dev/chet-extra/generate.R
Rscript dev/chet-extra/verify.R
```

Generation uses released 0.1.41, source
`05862bee1804806cea157ff1962300d741516301`, in a small persistent-cache project.
Official generation includes full schema validation, wrappers and documentation,
freshness checking, and an independent normalized-text SHA256 comparison of every
owned file. Only generated wrappers and Rd files are copied back; exports and
bespoke test registrations are added. `generation-proof.json` records the exact
ownership hashes. Do not copy the isolated manifest into the parent. Register
this service and regenerate with the parent's official pin and helper instead.

The focused suite uses the real httr2 executor and an actual localhost httpuv
server. It checks methods, exact encoded paths and decoded queries, JSON content and content
types, multipart raw/file bytes including NUL and 0xff, nested JSON/text/binary
responses, input rejection without HTTP, typed HTTP errors, hard 401 errors and
configuration failures. Password fixtures are invented localhost values.
No production or staging calls, writes, uploads or session changes were made.
No live deployment claim is made. Full package checks are outside this child.

Related work: [ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345),
[Specmill #166](https://github.com/seanthimons/specmill/issues/166),
[Specmill #171](https://github.com/seanthimons/specmill/issues/171),
[Specmill #177](https://github.com/seanthimons/specmill/issues/177).

The final focused run passed 1,277 assertions with zero failures, errors,
warnings or skips across 35 bindings. All 72 isolated manifest ownership hashes
passed independently. `test-proof.json` records the focused results and fixture
hash. No full package check was run.
