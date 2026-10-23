# Native management bindings

Adds 24 previously unbound alerts, hazard and ToxPrints routes. The wire contracts
come from the three unchanged canonical schemas. These new functions have native
Specmill arguments and results; they do not claim parity with an old facade.

The parent drafts supplied operation selection, names and independent request
samples. The fixture fixes integer `sheet` values and uses declared hazard
`ChemicalRecord` and `HazardOptions` properties. Multipart fixtures contain a
minimal identifier record and raw bytes including NUL and 0xff.

Reproduce from the repository root:

```sh
mkdir -p "$HOME/.cache/comptoxr-management-child/tmp"
export TMPDIR="$HOME/.cache/comptoxr-management-child/tmp"
# Optional: set SPECMILL_V41_LIBRARY to another verified released library.
Rscript dev/management-bindings/build-fixture.R
Rscript dev/management-bindings/generate.R
Rscript dev/management-bindings/verify.R
Rscript dev/management-bindings/reproduce-held-freeze.R
```

`generate.R` checks released 0.1.41 provenance, compares the existing transport
with the official scaffold using the established documentation-only adoption,
and creates a small isolated client under the persistent cache. It runs official
full generation with schema validation enabled, then freshness verification and
an independent normalized-text SHA256 check of every manifest entry. It copies
only the 24 generated wrappers and their Rd files into this worktree and adds
exports. No helper, pin or root manifest is changed.

`generation-proof.json` records schema validation, canonical source hashes,
normalized ownership hashes and freshness. `test-proof.json` records the focused
localhost suite and registrations. The final run passed 688 assertions with zero
failures, errors, warnings or skips across the 24 adopted bindings. The suite
exercises exact methods, paths,
queries, JSON bodies, multipart JSON parts and file bytes, response media,
HTTP 400/401/404/500, and invalid input with zero HTTP requests. Both raw uploads
and `curl::form_file()` uploads are checked. The fixture is rebuilt from the
canonical operation records in `cases.json`; requests are not recorded from the
generated implementations.

The parent must reapply the new service config and generate with its released
v41 pin and helper. This commit intentionally leaves `.specmill/manifest.json`
unchanged. If generated files are copied first, adopt only their exact reviewed
hashes from `generation-proof.json`, then independently verify all ownership
hashes after root generation. Do not copy the isolated manifest over the parent
manifest.

The three `files[]` query declarations and the old alerts-groups bulk binding
are excluded. The 25th route, `PATCH /api/alerts/groups/{id}/freeze`, is held for
[Specmill #177](https://github.com/seanthimons/specmill/issues/177). Native scalar
booleans bypass the serializer and arrive as uppercase `FALSE` / `TRUE`.
`held-freeze.R` preserves the officially generated candidate outside the package
runtime; `reproduce-held-freeze.R` captures the defect on actual localhost.
`candidate-25-generation-proof.json` records validated generation of the original
25 candidates; the final `generation-proof.json` covers only the adopted 24.
The blocker is linked from
[ComptoxR PR #345](https://github.com/seanthimons/ComptoxR/pull/345). No production or
staging requests, writes or uploads were made. No live validation is claimed.
Full package checks and the parent's existing integration gates are outside this
isolated task. Hook validation here covers only the 24 new registrations; the
broad baseline checker reports unrelated missing wrappers and hooks.
