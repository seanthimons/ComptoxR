# Exact PR176 candidate proof

This is an isolated test of Specmill PR176 at
`a656ce446fd2f4fe28184e3cad69da02e209ef26`. It does not test the moving PR head.
The deterministic `git archive --format=tar` SHA256 is
`ba5e8d3cd205cb0eba35d463db3f70394cac0b32f9629dfd5741319ce4eb104e`.
The candidate is installed into its own cache library, with source revision and
archive hash recorded in DESCRIPTION and checked before generation. Only those
two provenance fields are added to the extracted source before installation.

Final result: **210 assertion groups and 65 localhost HTTP requests passed**.
Both exact upstream acceptance scripts passed. All four canonical schemas pass
full validation, and both private generations pass freshness with zero operation,
mapping, retained-output or signature-drift diagnostics. All six ownership
records in each generation match, 12 checks total. Independent checks also match
the frozen output snapshots against both owner sets. All four installed templates
match exact source. The real hostname pool consumes tokens 99, 97, then 93 after
two batches; five declarative wrapper calls reduce it to 88. No tested contract
remains blocked at this candidate SHA. `results.json`, `verification.txt` and
`upstream-tests.txt` retain the evidence. Inactive `generated-throttle/` snapshots
show the final declarative request controls.

No gap was found requiring a comment on [PR176](https://github.com/seanthimons/specmill/pull/176).
PR176 and [ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345)
are registered with the T3 thread. No duplicate issue or upstream implementation
was created. Parent release/pin adoption remains outside this proof.

The five actual held operations are generated from the unchanged canonical
schemas with `validation = TRUE`:

- Alerts `PATCH /api/alerts/groups/{id}/freeze`.
- Standardizer `PATCH /api/stdizer/groups/{id}/freeze`.
- Resolver `POST /api/resolver/exportsimilaritylist`.
- Resolver `POST /api/resolver/exportsimilaritymap`.
- OPERA `POST /api/opera/file`.

The standardizer and OPERA input configs are copied from commits `161570cf` and
`1fa29328`. Alerts follows the held name in `dev/management-bindings`; resolver
uses the exact canonical operations held in `dev/resolver-extra`. These are new
bindings, so the baseline is the source contract rather than legacy behavior.
The alerts/resolver configs enable the existing native typed error policy.
Runtime error checks explicitly enable that policy for all five wrappers.

Reproduce from the package root:

```sh
bash dev/specmill-pr176-proof/run.sh
```

R dependencies and the repository's formatter must already be installed. The
launcher first verifies `inputs.sha256`, then fetches the exact git commit, checks its identity and deterministic
archive checksum, installs privately, runs the two unchanged upstream acceptance
scripts, and runs the ComptoxR proof. `PROOF_CACHE` can override the default
`~/.cache/comptoxr-pr176-exact`. TMPDIR is persistent under that cache and is set
before R starts. No production toolkit library is loaded or changed.

`verify.R` generates the official helper with the production provenance settings,
then checks helper bytes against that scaffold. It compares all installed
candidate templates with exact-source template hashes and independently checks
the production helper against its existing scaffold baseline, allowing only the
already documented roxygen noRd/trailing-whitespace adjustments. It uses the
unmodified native helper and validator; no executor replacement, callback boolean
conversion, handcrafted wrapper, or request encoding is used.

Both absent-throttle and declarative-throttle generation receive independent
freshness checks and normalized SHA256 checks for every private manifest owner.
The five wrapper snapshots, validator and scaffold are reviewable under
`generated/` as inactive text. The results record source/schema/template/helper
hashes, both ownership records and localhost request counts. `wire.rds` preserves
exact captured methods, paths, query strings, multipart metadata and bodies.

The runtime matrix covers FALSE/TRUE, both mixed two-flag combinations, source
defaults, optional NULL omission, required NULL/missing rejection, invalid boolean
types before HTTP, nested resolver bodies, raw/form_file OPERA multipart, invalid
nested bodies and absent required bodies. Native 400/404/500 errors preserve the
received response; 401 stays hard even under native batch-drop policy. Nine
invalid throttle configurations remain hard with zero HTTP for all five wrappers.

Throttle tests use the upstream localhost/httpuv and `httr2::throttle_status()`
seams. Real GET, POST, OPERA and two native fan-out batches consume one hostname
pool across calls. A separate realm and runtime override use the real httr2 pool.
Omitting throttle creates no policy and consumes no configured pool tokens. The
five declaratively throttled wrappers are also executed against localhost. The
large token capacity avoids waiting; no rate-limit sleeps or elapsed-time timing
assertions are used. The only bounded sleeps wait for localhost server startup,
as in the upstream test seam.

No production wrapper, pin, helper, config, runtime, manifest, progress ledger or
HANDOFF is adopted. All tracked files outside this proof directory are hashed
before and after the run. No push, deployed mutation, upload, authentication or
session operation occurs. GitHub is used only to obtain source; API tests target
127.0.0.1 exclusively.

`pubchem_properties`, `pubchem_search` and `pubchem_synonyms` remain held for
[cache lifecycle #174](https://github.com/seanthimons/specmill/issues/174).
A passing throttle proof does not establish their migration. The five bindings
also remain unadopted until the released generator and parent pin are updated.
No whole-package suite, R CMD check or deployed-service behavior is claimed.

Proof setup corrections before the final replay: convert the stored companion
settings list to the scaffold's character vector; keep the executing script
stable; assert the encoder's actual query order; construct file parts with
`curl::form_file()` and expect the schema-default `application/octet-stream`
part type; preserve one-item YAML sequences when adding the declarative
throttle defaults. These were test harness corrections, without candidate source or
client helper changes. The completed runtime subset passed 190 assertion groups
and 60 localhost requests before the final generation/freshness replay.

The frozen official helper text deliberately retains upstream trailing whitespace
in deparsed companions. `git diff --check` reports that snapshot; the proof
script, configs and other artifacts pass the scoped whitespace check. Stripping
it would stop preserving exact scaffold output. Air and Jarl pass on `verify.R`,
and `bash -n` passes on the launcher.
