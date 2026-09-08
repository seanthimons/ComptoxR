# Toolkit extraction verification

The source baseline is integration commit
`8f055b8ad143a4db8d6faead254c5e19fbd04671`. The migration decisions are in the
plans at commit 516dfd4 or later. The implementation is in a separate worktree.
No runtime wrappers, local hooks, schemas, cassettes, exports or package
dependencies changed in this workstream. Endpoint policy remains with the
coordinator.

The separate package is wrapmaint 0.1.0, source commit
`aae88f99f6bd355a06d3404fd100b86620609e83`. `dev/toolkit-lock.json` records the
verified source archive SHA256. Install the archive as a development tool.
There is no local toolkit source fallback. The coordinator supplies the
reachable immutable asset URL and CI installation. The toolkit's source and
tests are included in that source archive; a public source repository is not
required.

## Recorded checks

All local checks use R 4.5.1 on Windows 11. Set `LC_ALL=C`, `LC_CTYPE=C` and
`LANG=C` for command-line checks: inherited C.UTF-8 is not a valid Windows
locale here. This is a process setting, not a package metadata change.

| Check | Result |
| --- | --- |
| Before edits: targeted test filter below | 425 pass, 0 fail, 0 skip, 4 warnings |
| Final installed-toolkit run of the same filter | 425 pass, 0 fail, 0 skip, same 4 warnings |
| `Rscript dev/generate_tests.R --check` before and after | 376 generated contract tests current; static validation passes |
| `Rscript dev/check_hook_config.R` before and after | 240 functions, 340 hooks, 34 extra parameters pass |
| `Rscript dev/migration-evidence/generator-parity.R` | Old generator and installed toolkit compare 387 files: parsed code/signatures, roxygen and hook metadata; second pass has identical file hashes |
| `Rscript dev/migration-evidence/verify-protected.R` | 474 runtime/schema/hook SHA256 values unchanged; explicit chemical fixture hash recorded |
| `Rscript dev/migration-evidence/installed-runtime.R` | Both installed clients run with wrapmaint absent from every runtime library; all 376 committed generated client contract files run |
| wrapmaint `R CMD build .` then `R CMD check --no-manual wrapmaint_0.1.0.tar.gz` | Status OK; no errors, warnings or notes |
| wrapmaint `air format R tests` and `jarl check R tests` | Pass |

The exact targeted filter is
`generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts|hooks`.
Run it with `Rscript dev/migration-evidence/verify-toolkit.R`.
The four test warnings say jsonlite and dplyr were built under R 4.5.3,
and purrr and here under R 4.5.2. They occurred before extraction too.
Legacy regeneration emits its existing warnings (including route pagination
inference). These are not claims of generic schema or live transport coverage.

The toolkit package check runs four sourceable scripts: `catalogue.R`,
`boundaries.R`, `schema-versions.R` and `loading.R`. They cover all four catalogue
operations, fixed independent request records, successful completion, four
intentional faults, httr2 URL encoding and JSON placement, pre/post hooks,
two installed client namespaces with identical hook names, separate reference
documents, required-input diff findings, unsupported diagnostics, duplicate
names and target paths, manual files, path containment, parser and renderer
failure before mutation, and 2,000 repeated operations (18.13 seconds in the
final package check). No live request is sent.

The neutral fixture subset includes scalar path/query values and explicit
JSON object/array bodies in Swagger 2.0, OpenAPI 3.0.3 and OpenAPI 3.1.0 fixtures.
Header/cookie and other unsupported constructs produce per-operation reasons.
The toolkit README defines the subset and the limitations of structural diffs,
fixture constraints and file rollback. A hard process termination during
multi-file apply can require recovery from its retained backup journal; this
is not a cross-file filesystem transaction.

## Boundary and parity evidence

`toolkit-baseline-sha256.txt` freezes source, schema, config, wrapper and test
inputs. `toolkit-baseline-session.txt` records the initial environment.
`toolkit-protected.txt`, `toolkit-render-parity.txt` and `toolkit-runtime.txt`
record the final results. The ignored `.render-baseline` and `.render-installed`
directories preserve both regenerated trees for local review. Local raw logs
are retained but ignored. Existing committed generated wrappers can be stale;
the parity gate compares old regeneration against new regeneration using the
same frozen inputs, not against that stale committed output. The initial
comparison exposed a missing copied example dataset and a missing Air step;
both were corrected before accepting parity.

The ComptoxR adapter supplies the existing chemical fixtures, naming,
exclusions, stage rules, renderers and hook runtime. Generic modules are
installed package functions with explicit client contexts. The small neutral
catalogue uses the default renderer and a local helper/config; it does not
provide a replacement renderer. Its second installed namespace also needs no
engine edits. `toolkit-comparison.md` records the actual OpenAPI Generator
R/httr2 fixture comparison.

The new ComptoxR entry adapter is 61 lines. Retained client policy is 615 lines
in `stub_specs.R`, 553 in parameter parsing, 2,562 in the specialized wrapper
renderer and 118 in the chemical test renderer. These are retained compatibility
costs, not a claim that all rendering logic is generic. The neutral catalogue
has a 30-line local helper, uses a 17-line generation specification before its
independent expected records, and contains no replacement renderer.

The coordinator owns integration, reachable archive publication, CI/readiness,
full integrated ComptoxR tarball/documentation checks and the subsequent
endpoint policy migration. Roll back by pinning the previous generator source
and its matched generated output together. No new runtime toolkit dependency
or legacy database is introduced.
