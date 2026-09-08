# Handoff: delegated package migrations

**Updated**: 2026-09-07
**Branch**: `feat/migration-coordination`
**Status**: Implementation in progress in isolated worktrees; no releases or withdrawals.

## Current execution (2026-09-07)

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
- Old database workflow ID `306098499` must be disabled after harmonizer
  verification, with active old runs cancelled. New source-only workflow has
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
