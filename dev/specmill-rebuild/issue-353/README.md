# ToxPrint bulk rebuild, issue 353

The user explicitly authorized purging the inherited legacy bulk implementation
and rebuilding it with Specmill. Public formals remain `chemi_toxprints_bulk(query)`.
The canonical schema is unchanged. Official Specmill 0.1.51 emits the POST into
R/chemi_toxprints.R alongside the existing GET. GET function formals/body and its ownership operation identity are unchanged.
Its original DTXSID example was misleading for development; its YAML docs now
use SMILES and explain headers/profile and the envelope result. before.json
preserves the original GET source and ownership for an AST comparison.

The old POST inherited the CTX host, API-key authentication and a top-level array.
The replacement targets Cheminformatics /api/toxprints, has no CTX authentication,
and validates each `{chemicals: [...]}` chunk against canonical ToxprintsRequest.
It preserves query cleanup, batch_limit fallback 100, single-error propagation,
partial successful chunks, and tibble output. The old contract fixture entry and
owned helper-mocking test were retired. Supported specmill::apply_files removed
that test and updated its ownership record.

Live inspection exposed an additional formatting problem: the existing tidy
helper turns nested descriptor arrays into semicolon-separated text. The new
supported response-policy callback returns one row per chemical, with numeric
descriptor vectors and service metadata in descriptors/info list-columns. This
is an intentional behavior repair; no runtime helper or transport was modified.

Evidence:

- Four raw direct read-only controls are archived as *-control.json. SMILES CCO
  returns 729 descriptors in development and production without an API key.
  DTXSID7020182 succeeds in production but development rejects it with400,
  'Invalid chemical structure.' No client resolution hook is added.
- installed-live.json/rds: isolated installed generated-wrapper live replay in
  development and production. Three unique SMILES, with duplicate/blank/NA inputs,
  are cleaned and split into 2+1 chunks, returning three typed rows with729 bits
  each. Development single400 remains an httr2_http_400; a failed chunk does not
  discard the successful chunk. Production DTXSID output is positive.
- The first wrapper replay used the old formatter and failed its expected
  descriptor-list assertion despite successful calculation responses. This led
  to the intentional response mapping repair above; no service-success claim is
  based solely on that initial replay.
- test-toxprints_bulk.R verifies GET preservation, public formals, canonical dry-run
  bodies, chunk cleanup, absence of inherited API-key headers, invalid inputs and
  the typed descriptor-vector output using a real saved service response. No
  localhost server is used. generation.json records validated official emission.

Reproduce generation: Rscript dev/specmill-rebuild/issue-353/generate.R

Render GET/POST help: Rscript dev/specmill-rebuild/issue-353/document.R

Install into an isolated library and replay live:
Rscript dev/specmill-rebuild/issue-353/live.R <installed-library>

Final freshness: Rscript dev/generate_specmill.R --check

DTXSID support is deployment-dependent. Larger batches, alternate profiles,
staging and full package checks are unverified. The wrapper intentionally keeps
its one-argument interface; options and profile are not newly exposed.

GET audit: six raw GET controls and four installed-wrapper GET calls confirmed
working SMILES input, 729 descriptors, optional 729 header labels and explicit
profile in production and development. Production accepts the DTXSID control;
development rejects it. live-get.R and installed-get-live.json record the audit.
The request implementation was already correct and was preserved; only its
generated documentation was corrected.
