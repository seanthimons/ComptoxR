# Handoff: delegated package migrations

**Updated**: 2026-09-08
**Branch**: `docs/migration-publication-evidence`
**Status**: All three migrations are released and verified. Affected old database downloads are withdrawn.

## Completion (2026-09-08)

- Endpoint PR 307 merged as `35e0d0c` after all package/platform, readiness,
  coverage, toolkit, generation, and site acceptance checks passed. R-devel rerun
  `34181879988` completed successfully on Linux and macOS.
- Normal Release run `34185471524` published ComptoxR 3.0.0 at `e2de0aa`.
  Downloaded package SHA-256:
  `2e6249b2185af035f5fc69fa10288446beaf50728c27c2f011572c60b3652991`.
  Its runtime files match reviewed commit `e3b08c7`. Separate installation,
  default/explicit URL behavior, startup state, and the 1,206-file source-package
  boundary scan passed. No toolkit runtime dependency was loaded.
- Published ComptoxR 3.0.0 plus published envharmonizer 0.1.1 passed the full
  September database check: 664 selected rows match fresh localhost HTTP and
  explicit mapping, with native columns, row order, and database hash preserved.
- Release site workflow `34185724310` built and deployed successfully. Its
  downloaded artifact passed the 981-text-file scan. The live site shows 3.0.0;
  the removed `chemi_safety` reference page returns HTTP 404.
- Database withdrawal and September mapping publication details are recorded
  below and in `dev/reports/migration/publication.md`. Earlier pending statements
  are historical. No migration implementation, publication, or withdrawal remains.
- Users must update ComptoxR and envharmonizer, then restart local Plumber
  servers. Existing local databases and mapping evidence remain intact.
- The optional integration rolling package is withheld by its existing `.9000`
  development-version guard. Stable publication succeeded through the normal
  Release workflow. Existing unrelated PRs 304 and 305 were not merged.

Implementation and publication records include `8b785e4` (September support),
`2facf3b` (harmonizer source merge), `e3b08c7` (reviewed endpoint/toolkit),
`35e0d0c` (endpoint merge), `e2de0aa` (3.0.0 release), and `f3f8603` (withdrawal
evidence). See `final-release.json` for the final artifact and verification IDs.

## Publication checkpoint (2026-09-08 03:49 UTC)

- ComptoxR 2.0.0 and wrapmaint 0.1.0 are published and independently verified.
- envharmonizer 0.1.1 is published after source PR 21 passed CI and merged as
  `2facf3b`. All 12 downloaded payload checksums passed. An unauthenticated
  package download, separate installation, and full database/HTTP checks passed.
- The forced database build selected September, while the initial mapping package
  supported June. Strict matching rejected this mismatch. September support now
  has explicit artifacts, with June recorded as the mapping-evidence release.
  All 139 native code-description pairs are identical. June tables and metadata
  are unchanged. No independent mapping review is claimed.
- Source-only database workflow `34181519666` passed. Published database asset
  `549783704` has 1,250,611 results, builder version 2.0.0, and SHA-256
  `2664e63ab9b6d37fbd8206d1747d7e8f77084897de80f2320c660873ef04c5db`.
  Direct database and fresh localhost Plumber results match for 664 selected rows.
  Explicit harmonization preserves every source column and row; DB hash unchanged.
- Old asset IDs `548521627`, `548521629`, and `464523912` now return HTTP 404.
  Only the last was explicitly deleted; the rolling upload replaced the first two.
  Users' local databases and original checkout changes are preserved. No legacy
  derived database was published. Old workflow `306098499` is now deleted because
  its file was removed; do not restore it.
- Endpoint PR 307 head `e3b08c7` is also on integration. Standard package checks on
  all three operating systems, readiness, generation/toolkit, coverage, and site
  checks passed. Linux/macOS R-devel were cancelled after stale status data showed
  prolonged setup. Logs revealed long DuckDB source compilation; macOS had reached
  package checks. Only cancelled jobs are being rerun in `34181879988`; allow the
  source compilation to complete. Do not cancel based only on the status API.
- Optional integration rolling publication stopped at its existing `.9000`
  version guard because DESCRIPTION is stable 2.0.0. Retain this guard and use the
  normal stable Release workflow. No development artifact was published.
- Remaining: finish the two R-devel jobs; merge PR 307; run normal Release with a
  major bump; verify the final downloaded package and published site; integrate
  this evidence branch and record final commits. Do not hand-edit package versions
  or tags. Original `endpoint-audit.md` and `CONTEXT.md` changes remain untouched.

See `dev/reports/migration/publication.md` and `database-withdrawal.json`.
Earlier pending publication statements below are superseded by this checkpoint.

## Integration checkpoint (2026-09-08)

- envharmonizer v0.1.0 remains published and independently verified. Source
  PR 20 is merged. Original user changes in both initial checkouts are preserved.
- Source-only PR 306 passed all checks and merged as `1f61423b`. Normal Release
  run `34180852761` published ComptoxR 2.0.0 at main commit `b55949c`.
  The downloaded package passed hash, installation, API, and shipped-builder
  checks. SHA-256: `a7b7bae7f4462b7d6fa95b77c6f113a664e756a93ff44b2c18beb1e13b2bd589`.
- Toolkit source commit `aae88f9`, archive SHA-256
  `a9e8ff83f1316b1e3059c63ab84e7aa01567bb7c2156259400bf791781408fe0`.
  Extraction commits `7eeea37` and `a116dee` passed 387-file generator parity
  before endpoint policy changed. Runtime hooks remain local.
- Endpoint commits: `0104cc6` (resolution and production regeneration),
  `67caa04` / `a1b5536` (isolated local clients), `ab755fd` / `31af64e`
  (public input cleanup and evidence), `229f2ab` (formatter parity), through
  `027ee6a` (CI fixes). All are pushed. Worker database tests from `8dbd5d7`
  are included; latest ECOTOX tests are integrated as `2b92e0a` / `1034450`.
- Final local readiness: 4,727 main-lane assertions and 66 state-sensitive
  assertions passed, zero failures, 48 declared skips. Four main-lane warnings
  concern dependencies built under newer R versions. Package check: Status OK.
  Source tarball scan: 1,206 text files; rendered site scan: 504 text files.
  Installed runtime: 336 contract files passed with wrapmaint unavailable.
  Final generation and generated-test freshness checks pass without changes.
- Local inputs and original wrappers are preserved outside the public checkout
  at `C:/Users/sxthi/Documents/ComptoxR-local-clients/migration-516dfd4`.
  The separate installed local alerts package passed mocked HTTP; nine operations
  are supported and eight unsupported operations are reported. No local client
  is published. Fifty-four public dev/staging schemas were removed after hashes
  matched their external copies.
- The reviewed wrapmaint archive is attached to v2.0.0. Forced source-only
  database workflow run `34181519666` is started on main after client verification.
- Remaining order: verify pinned download/install from a clean checkout;
  verify the new database downloads; withdraw only affected old database
  assets. Then integrate and release the endpoint/toolkit branch through normal
  checks and release workflow. Keep old database workflow `306098499` disabled.
- No database asset has been withdrawn. See `database-assets-before.json` for
  exact asset IDs. Do not remove a newly replaced rolling asset by name.

`dev/reports/migration/endpoint-progress.md` contains final local gate details.
The older execution record below describes the earlier lifestage checkpoint;
its pending toolkit/endpoint statements are superseded by this section.

## Current execution (2026-09-07)

envharmonizer v0.1.0 is now published and verified at
https://github.com/seanthimons/envharmonizer-releases/releases/tag/v0.1.0 .
Source remains private at `seanthimons/env-harmonizer`; PR 20 passed CI and
merged as `72a41ae`. The coordinator verified all downloaded payload hashes,
an unauthenticated package download, and a separate-library offline install.
See `dev/reports/migration/lifestage-release.md` for exact evidence.

ECOTOX commits are integrated locally as `a03879c`, `cceb4b7`. After destination
hash/parity approval, 37 transferred files were removed. A full source-only EPA
build has 1,242,356 rows; an installed cross-package example passed on 664 rows.
The unanchored `build.R` exclusion was fixed so source tarballs ship the builder.
Readiness passed 4,851 assertions with 48 skips and no test failures/warnings.
The source tarball passed R CMD check (Status: OK). The installed builder also
built 1,242,356 results and passed the source-only publication guard. Its 13
encoding warnings are recorded in `source-only-installed-warnings.txt`.
Old workflow `306098499` is disabled and had no active runs. No database asset
has been withdrawn. Toolkit parity and endpoint migration are still pending.

- Coordinator: `.worktrees/migration-coordination`, based on `integration`
  `8f055b8`, then fast-forwarded to plans `516dfd4`.
- ECOTOX: `.worktrees/ecotox-source-only`, branch `feat/ecotox-source-only`.
- Toolkit: `.worktrees/schema-toolkit`, branch `feat/schema-toolkit`.
- Harmonizer: `../amos-harmonizer/.worktrees/feat/envharmonizer-lifestage`,
  based on `3872716`. No destination AGENTS.md or CONTRIBUTING.md exists;
  CONTEXT.md was read. The original modified CONTEXT.md remains unchanged.
- Coordinator commits pushed: `aeb1a89` (publication guard, CI preparation,
  build exclusions), `ab04f0a` (frozen baseline reports).
- Coordinator endpoint baseline: 454 passed assertions, 36 skipped tests,
  zero test failures/errors/warnings. See `dev/reports/migration/`.
- Worker-reported baselines awaiting final review: ECOTOX 183 passes;
  AMOS 134 passes; toolkit 425 passes with four warnings.
- `dev/validate_migration_release.R` checks native/derived publication tables,
  a forced same-release rebuild, and the database workflow. No user DB is changed.
- Affected download inventory: `db-latest/ecotox.duckdb`, its version sidecar,
  and `v1.5.0/ecotox.duckdb`; SHA-256 and asset IDs are recorded in
  `dev/reports/migration/database-assets-before.json`. Nothing withdrawn.
- Old database workflow ID `306098499` was disabled after harmonizer
  verification; no old runs were active. New source-only workflow has
  a separate path, `db-ecotox-source-only.yml`; retain the old disabled state.
- Production schema acquisition is frozen locally under
  `.migration-evidence/production`. Alerts and Hazard return 502; existing
  production snapshots must remain until an approved replacement is available.
  No generation policy or endpoint implementation has changed yet.

## Failed approaches during execution

- Fetch encountered a moved `integration-latest` tag and refused to overwrite
  it. Branch baseline remains `8f055b8`; no tag was changed.
- Baseline CSV export initially failed on a testthat list column. The raw RDS
  was preserved, then summarized without rerunning tests.
- Windows R reports four pre-existing locale startup warnings. PowerShell's
  UTF-8 BOM also prevented one temporary report script from parsing; the
  replacement file has no BOM.

The sections below retain the original ownership and dependency rules. Their
planning-era state descriptions do not supersede the execution record above.

## Goal and authoritative documents

Move ECOTOX interpretation into `envharmonizer`, extract reusable API development tools, then enforce production API policy. Read `AGENTS.md`, `CONTRIBUTING.md` and these plans. Requirements are updated directly; no conversation or override document is required.

| Document | Authority and background |
|---|---|
| [lifestage-migration-plan.md](lifestage-migration-plan.md) | AMOS rebrand, evidence/workflow inventory, experimental artifact, source-only ECOTOX, release and database withdrawal. |
| [schema-tooling-extraction-plan.md](schema-tooling-extraction-plan.md) | Development-only toolkit, generator inventory, contracts, catalogue reuse, parity and local generation. |
| [endpoint-migration-plan.md](endpoint-migration-plan.md) | Approved endpoints, configuration/direct readers, export removal, development isolation and artifact checks. |

`endpoint-audit.md` is unchanged, untracked historical user work. Relevant background is now in the tracked endpoint plan. The audit is not required on another device and its old proposals do not control implementation.

## Completed

- Traced both ECOTOX builders, queries, mapping inputs, AMOS artifacts, generators, hooks and CI.
- Confirmed shipped server source `inst/plumber/ecotox/plumber.R`: calls ComptoxR against a local database and requires a matching package version.
- Resolved migration order, destination, scientific status, compatibility, endpoint scope and hook ownership.
- Used parallel document owners to reconcile plans while preserving technical inventories and validation requirements.

## Not yet done

- Run baseline tests and capture fixed outputs, hashes, failures and skips.
- Implement or release migrations; rename AMOS; publish or withdraw assets.
- Run existing-generator comparison and installed catalogue checks.
- Select/check toolkit branding. Public publication is not a migration requirement; CI needs a pinned development dependency.
- Verify source redistribution terms and name availability before publication. `envharmonizer` is selected, not a claim of availability.
- Obtain independent scientific review. This does not block the experimental first artifact.

## Parallel assignments and ownership

Delegation is explicitly requested. Use a coordinator and three workers. Concurrent ComptoxR implementation branches need separate worktrees based on `integration`; read the harmonizer project's own rules before branching there.

| Owner | Assignment | Ownership and limits |
|---|---|---|
| Harmonizer worker | AMOS rebrand, full lifestage transfer, offline artifact and parity | Harmonizer repository only. Preserve modified `CONTEXT.md`. No public release actions. |
| ECOTOX worker | Source-only builders, queries, local Plumber interface and tests/docs | ECOTOX code/build scripts and tests. Leave shared endpoint configuration, package metadata and release workflows to coordinator. |
| Toolkit worker | Baseline, development engine, catalogue reuse and local output | New toolkit and ComptoxR generator adapters/tests. Runtime hooks stay local. No endpoint-policy changes during parity work. |
| Coordinator | Contracts, review, integration, endpoint phase and releases | Shared configuration, metadata, CI/readiness/release files, final checks, publication and withdrawal. |

Workers report changed files, commits, exact checks, failures/skips and blockers. Coordinate shared files before editing. Overlapping generated metadata stays with the coordinator. Remove transferred files only after full path/hash inventory and passing destination parity evidence exist.

## Dependency and release gates

Parallel preparation is allowed. Lifestage is first delivery priority; its release must not wait for the toolkit.

1. Freeze lifestage evidence/output for harmonizer and ECOTOX workers. Toolkit work can proceed independently against fixed schemas and current endpoint behavior.
2. Publish and verify experimental `envharmonizer`, preserving AMOS behavior. No compatibility package: user reports no downstream AMOS users.
3. Release breaking source-only ComptoxR and matching local server; publish verified source-only databases and withdraw affected old public database downloads. Require client updates/server restart. Follow the lifestage plan's detailed sequence. Preserve evidence; do not mutate user databases.
4. Complete installed-toolkit parity and catalogue reuse before switching generation or changing endpoint policy. Toolkit remains development-only; hook execution stays in ComptoxR.
5. Apply endpoint policy against integrated ECOTOX/toolkit changes. Public output uses approved production schemas and shipped Plumber routes. Development output stays local. Release after artifact checks.

Keep endpoint behavior changes out of the toolkit parity diff. Prevent scheduled or old build paths from restoring withdrawn derived database assets.

## Current state

ComptoxR: `C:/Users/sxthi/Documents/ComptoxR`.

- Documentation branch `docs/schema-tooling-extraction-plan`, tracking origin.
- HEAD before reconciliation: `722e2a8`; earlier plans: `b983f41`, `2745f6b`.
- Code baseline before documentation: `8f055b8`; check future drift.
- Pre-existing untracked `endpoint-audit.md`: preserve, do not stage.
- This work changes planning documents only. No runtime baseline is certified.

AMOS: `C:/Users/sxthi/Documents/amos-harmonizer`, currently package `amosharmonizer`.

- Branch `feature/matrix-hierarchy-api`; inspected HEAD `3872716`.
- Pre-existing modified `CONTEXT.md`: preserve. This documentation work does not edit that repository.

## Resume instructions

1. Read all tracked plans and check repository states/rules. Bring reviewed planning commits into implementation workspaces without resetting this checkout.
2. Assign workers and freeze inputs. Use source inventories instead of repeating reconnaissance unless code changed.
3. Establish offline baselines with sourceable R checks. Start with:

   ```r
   devtools::test(filter = 'eco_functions|eco_lifestage|ecotox_vocabulary_drift|cran_tarball_test_paths')
   devtools::test(filter = 'generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts|hooks')
   ```

   Expected: relevant tests pass, or pre-existing failures/skips are recorded with exact errors. A skip is not a pass.
4. In an isolated checkout run `Rscript dev/generate_tests.R --check` and `Rscript dev/check_hook_config.R`. Expected: valid output/configuration and no file changes. Inspect failures before changing the engine.
5. Review each diff and evidence. Run phase-specific installed-package and source-only HTTP/database checks, then broader readiness checks for shared changes.
6. Update this handoff with commits, commands, results and remaining work. Use the normal release workflow; do not manually edit ComptoxR's version or create release tags.

## Code context and warnings

- Reuse `run_generator(spec, pkg_dir)` and ordinary callbacks. No new HTTP framework or plugin registry.
- `run_hook(fn_name, hook_type, data)` stays local. Preserve manual-then-generated pre-hook merge, post-hook semantics, write-back, skip/result and errors. Details are in the toolkit plan.
- Generated helper-call tests can hide later failures. Require independent requests and successful-completion assertions; no broad conformance claims.
- Preserve description key `org_lifestage`, unresolved missing values and missing reproductive flags. Scientific corrections are separate.
- DuckDB paths are not URLs. Direct endpoint readers and diagnostics must use the same configuration as request helpers.
- `https://episuite.dev/api` is user-approved production. Localhost is allowed for shipped Plumber APIs. Substring scans alone cannot decide policy.
- Generators can write/delete files: use isolated output and ownership checks. Do not run cleanup as reconnaissance.
- Add explicit planning-file build exclusions and verify final tarball during implementation.
- Offline checks need no credentials, schema refresh or cassette recording. Check R/dependency/formatter availability first. OpenAPI Generator CLI comparison has not run.

## Failed approaches

No implementation was attempted. Layering conflicting plans was rejected; each source plan is now updated. Earlier public legacy database, retained argument, optional rename and hook-runtime extraction proposals were replaced.

PowerShell did not expand some native `rg` directory globs; use directory arguments and `-g '*.R'`. A shell Markdown write was rejected by the command guard; use a direct file patch.
