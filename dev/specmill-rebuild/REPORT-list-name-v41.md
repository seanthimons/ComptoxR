# Released v0.1.41 list-name adoption

Local work over `2b88f70f` for ComptoxR PR345. No push or production writes.
The shared progress ledger and resolved-chemical configs are outside this change.

## Official source

The remote `v0.1.41` tag resolves to
`05862bee1804806cea157ff1962300d741516301`, which contains the reviewed PR163 head
`b79412fd330ddad452ff1a31c22917ba6fa543eb`.
The release package downloaded with `gh release download` matches its official
`SHA256SUMS` and the supplied checksum:
`66fc7630db90b3d353c74ecfd0db3c70b4c30337df18566acdb1db756396fe88`.
The independently generated `git archive --format=tar` has SHA256
`70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.
The lock records that source archive checksum, as required by the installer.

`dev/install_specmill.R` installed the pinned commit into the checkout's isolated
`dev/specmill-pilot/artifacts/toolkit-library`. `dev/specmill-342/emit.R` consumes
the official `scaffold$code` directly. Both the emitted helper and its provenance
are byte-identical to v0.1.40. No helper, executor, or generic facade was patched.

## Comparison with ComptoxR 1.7

Both `v1.7.0` and `v1.7.1` distinguish these operations:

- `ct_chemical_list_search_by_name(listName, projection, extract_dtxsids)` calls
  `GET /chemical/list/search/by-name/{listName}` and runs extraction once after
  combining the results.
- `ct_chemical_list_chemicals_search_by_listname(list)` calls
  `GET /chemical/list/chemicals/search/by-listname/{list}` without an extraction
  hook. It is already generated and is unchanged here.

The held PR163 wrapper and extraction hook were unchanged from both 1.7 tags.
The old wrapper file's SHA256 is
`70a2cb20215c92dfac8d94a450bd6c9d42a598fbdd78698d86b521e628c91c63`.
An isolated installation of `v1.7.0`, commit
`9a79d48ce88af1e2ea9da6dda571a1e7db6709fa`, supplied all thirty frozen baseline
records in `tests/testthat/fixtures/native-ctx-list-name.rds`.

## Adoption

`apis/ctx-list-name.yml` selects the held operation from
`schema/ctx-chemical-prod.json`. It uses `post_response_scope: combined`,
`post_params_source: original`, the existing native response collector, and a
final formatter composing the existing list formatter and `safe_tidy_bind`.
The existing hook is unchanged. Original blanks, duplicates and NA reach the
hook; normalized unique nonblank values reach transport. Formatter failures
stay outside batch dropping, and hook failures propagate after final formatting.
The mapping explicitly retains JSON Accept and CTX API-key headers and selects
released `preserve_errors` controls for transport identity and typed received
404/500 conditions. Native 401 remains a hard call failure.

The exact legacy whole-file source was frozen before removal and official
generation, following the existing wave adoption workflow. The replacement
behavior suite is registered in `inst/hook_config.yml`. Only its exact old
helper-mock test was retired, through supported `specmill::apply_files` with an
exact hash predicate. Retirement evidence is `list-name-test-retirement.rds`.
No shared callback definitions changed.

## Checks

Full generation ran with `validation = TRUE`, artifacts `wrappers` and `tests`,
and zero operation, mapping, retained or public-signature drift diagnostics.
Twenty-five schema validations pass. The existing archived Swagger AMOS schema
remains reviewed-invalid, with its recorded findings preserved; the reviewed
AMOS subset passes. This change adds no validation bypass.

The final installed candidate passes all thirty comparisons against the isolated
1.7.0 package. Helper freshness, idempotence, provenance, version rejection,
overwrite refusal, explicit adoption and whole-file ownership checks pass.
`Rscript dev/generate_tests.R --check` passes with 23 remaining legacy wrappers.

The fresh validated check reports all 546 files unchanged. Nine suites pass
36 tests and 1,811 assertions, with zero failures, errors, warnings or skips.
The list-name suite contributes 333 assertions, including the thirty-case replay,
raw original parameters, hook/formatter boundaries, real localhost 200/404/500/401
behavior and transport condition identity. The other suites cover collection
responses, normalization, list-all, preserved/response errors, generic-request
edges and helper adoption. Exact totals and local logs are recorded in
`list-name-v41-validation.json`.

Baseline and candidate snapshots use the same fixed CLI width and Unicode
settings. Messages are compared exactly; they are not normalized to conceal
condition differences. Credential header assertions use httr2's public reveal
accessor for the dummy local key; real localhost requests check the wire value.

Repeat the targeted suite from the package root:

```sh
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^native_ctx_list_name$", stop_on_failure=TRUE, reporter="summary")'
Rscript dev/specmill-342/verify.R
Rscript dev/generate_tests.R --check
```

For full validated generation, load the pinned toolkit and callbacks, then use
the public generator with each mode in a fresh R process:

```r
source('dev/install_specmill.R')
verify_specmill()
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
specmill::generate_client(
  root = '.', config = 'specmill.yml', callbacks = callbacks,
  mode = 'check', artifacts = c('wrappers', 'tests'), validation = TRUE
)
```

Use `mode = 'apply'` before the fresh check when adopting the reviewed outputs.
The new help page was rendered by Specmill's roxygen documentation workflow and
applied through `apply_files`; shared helper code was not edited.

Full `R CMD check` and production endpoint calls were not run. The existing
archived AMOS validation finding remains recorded above.
