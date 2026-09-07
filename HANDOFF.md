# Handoff: API tooling and lifestage migrations

**Generated**: 2026-09-07 17:49 -04:00
**Branch**: `docs/schema-tooling-extraction-plan`
**Status**: Planning complete; implementation not started

## Goal

Extract schema/wrapper generation, offline test generation, and API hooks into a reusable R toolkit. Then apply the production-endpoint policy and move ECOTOX lifestage harmonization into a dedicated data-product package, preferably the existing AMOS project.

The user explicitly asked to explore generalization. The next work must prove reuse with a non-chemical client, not merely move CompTox code into another repository.

## Next-session prompt

> Read this handoff, `AGENTS.md`, `CONTRIBUTING.md`, and the three planning documents linked below. Continue with the schema toolkit migration first. Begin by checking repository state, establishing the existing test/output baseline, and comparing the small neutral-client case with OpenAPI Generator's R/httr2 output. Then implement the smallest reusable engine with a ComptoxR adapter, preserving current behavior. Extract hook execution after generator parity, and prove generalization with the catalogue fixture before switching CI. Keep endpoint-policy changes and lifestage extraction in separate later changes. Use the phase gates in the plans, record actual verification, and update this handoff as work proceeds. Package names and public release decisions remain open; do not treat provisional names or scientific-review claims as settled. Do not repeat the entire reconnaissance unless the implementation has changed.

This prompt is intended for a future implementation session. The current session created plans and this handoff only; it did not execute migrations or publish packages.

## Planning documents: read in this order

| Document | Purpose |
|---|---|
| [schema-tooling-extraction-plan.md](schema-tooling-extraction-plan.md) | Full inventory, reusable boundary, neutral operation record, catalogue fixture, existing-tool comparison, ordered migration, and validation gates. |
| [endpoint-audit.md](endpoint-audit.md) | Production-endpoint policy, server selectors, startup behavior, stage-named wrappers, and artifact inspection. **This file is local and untracked.** |
| [lifestage-migration-plan.md](lifestage-migration-plan.md) | Full workflow transfer, AMOS destination, offline artifact, review status, source-only ECOTOX output, and rollout compatibility. |

The two tracked plans contain detailed file inventories and source citations. Use them rather than rebuilding the inventory from scratch. Their observations refer to the inspected commits, not necessarily a later checkout.

## Completed

- [x] Traced the lifestage workflow through both database builders, local/Plumber query paths, seed, curation, and tests.
- [x] Inspected the AMOS release builder, offline accessors, manifests, and review terminology.
- [x] Traced schema acquisition, wrapper generation, hook configuration/execution, test generation, and CI.
- [x] Added a concrete generalization path and comparison with existing OpenAPI Generator tooling.
- [x] Recorded cross-migration order and per-phase gates.
- [x] Committed and pushed the two new plans; documentation diff checks passed.

## Not Yet Done

- [ ] Run baseline tests and capture generated-output parity fixtures.
- [ ] Run the existing-generator comparison; only its official documentation was inspected.
- [ ] Select/check the toolkit package name and create its project.
- [ ] Implement any toolkit, endpoint, or lifestage migration.
- [ ] Implement the catalogue acceptance fixture and installed-package checks.
- [ ] Resolve endpoint-policy choices and deployed Plumber compatibility.
- [ ] Obtain independent scientific review of lifestage mappings.
- [ ] Rename AMOS, publish replacement artifacts, or coordinate a breaking release.

## Failed Approaches

None. No implementation was attempted. PowerShell did not expand some directory globs passed to `rg`; subsequent searches used directory arguments. Use `rg pattern directory -g '*.R'` where needed.

## Proposed order of operations

### A. Schema toolkit first

1. Freeze schemas, configuration, generated outputs, manual-file hashes, and hook behavior. Run the existing focused suites.
2. Compare the catalogue fixture with OpenAPI Generator R/httr2. Decide whether this toolkit should own rendering or focus on maintenance/checking.
3. Extract the development engine. Keep CompTox service rules, names, fixtures, and request helpers in a local adapter. Require output parity and a no-change second generation pass.
4. Extract the small hook runner with explicit per-client configuration and function lookup. Preserve existing payload, merge order, and errors.
5. Supply a neutral renderer/helper contract and catalogue fixture. Prove reuse without adding client-specific engine branches.
6. Pin the toolkit in CI, validate installed packages, and only then remove the old implementation modules.

**Gate:** existing client behavior remains stable; a second client works through the same engine. Estimated 10-17 working days for extraction, or 13-22 including the general default renderer. These are estimates, not elapsed work.

### B. Endpoint policy second

1. Resolve the EPI production-host classification, stage-named wrapper scope, and runtime configuration contract.
2. Add/test production-default resolution and remove build-dependent startup selection.
3. Migrate server selectors and promote/deprecate/remove affected stage-named wrappers against production schemas.
4. Change client generator policies and snapshots separately from toolkit extraction.
5. Update tests/docs; check the built package and rendered site for prohibited references.

**Gate:** do not mix behavior-preserving toolkit extraction with endpoint-policy changes. The audit estimates 1-3 working days, subject to compatibility decisions. Its exact wrapper counts must be rechecked against the implementation branch.

### C. Lifestage third

1. Freeze the current mappings, evidence, output, and package/database versions; identify consumers.
2. Transfer the complete workflow to the destination, with provenance and domain tests.
3. Establish parity and add explicit offline access plus a versioned artifact.
4. Make the replacement artifact available with its actual review status.
5. Remove automatic derivation from both ECOTOX builders and local/Plumber query paths; retain native code and description.
6. Coordinate client/server/database rollout, retaining a reproducible legacy combination.
7. Rebrand AMOS separately if selected.

**Gate:** replacement before removal; scientific corrections separate from extraction. Estimated 5-9 working days plus 1-3 for a rename, excluding review waiting time. This migration is technically independent and can proceed separately, but delegation was not requested in this session.

## Key decisions and open choices

| Item | Direction or status |
|---|---|
| Toolkit boundary | One R maintenance toolkit; development engine first, hook runtime second. Domain behavior remains in clients. |
| Generalization | Neutral operation records and a small default renderer, proven with the catalogue fixture. No new HTTP framework, class hierarchy, or plugin registry. |
| Toolkit versus harmonizer | Separate packages/projects. They have different users and release reasons. |
| AMOS destination | Recommended, not yet implemented. `envharmonizer` is a provisional name; availability is unchecked. |
| Lifestage scientific status | Packaging and test passes do not establish independent scientific approval. Preserve source, curation, and independent-review status separately. |
| Endpoint policy | Exact EPI hostname classification and stage-wrapper treatment remain unresolved. Do independent extraction work before those choices are needed. |
| Authorization state | Reconnaissance/handoff completed. No package publication, rename, destructive cleanup, PR merge, or deployed service change has occurred. |

## Current state

**Working**: Planning documents are committed and pushed. No runtime behavior was changed in this work.

**Broken**: No new runtime failure was established. Existing tests were not run, so do not describe the baseline as green.

**ComptoxR workspace**: `C:/Users/sxthi/Documents/ComptoxR`.

- Branch: `docs/schema-tooling-extraction-plan`, tracking origin.
- Pre-handoff HEAD: `b983f41` (`docs: assess schema tooling extraction and generalization`).
- Parent planning commit: `2745f6b` (`docs: plan extraction of ECOTOX lifestage harmonization`).
- Code baseline before these plans: `8f055b8`.
- The schema-planning branch includes the lifestage-planning commit. Branch `docs/lifestage-migration-plan` was also pushed earlier.
- Before this handoff, the only uncommitted item was `?? endpoint-audit.md`. It is pre-existing user work. Do not overwrite, delete, or include it in unrelated commits.
- No PR was opened by this session. This handoff is to be committed on the current documentation branch after validation.

**AMOS workspace**: `C:/Users/sxthi/Documents/amos-harmonizer` (relative path `../amos-harmonizer`).

- Package name: `amosharmonizer`.
- Branch: `feature/matrix-hierarchy-api`; HEAD: `3872716`.
- Pre-existing local modification: `CONTEXT.md`. Preserve it. This session only read that project.

A fresh remote checkout will not contain `endpoint-audit.md`. Keep the local file available when handing off to another device, or supply it separately. The two tracked plans and the endpoint summary above remain available, but they do not replace the full audit.

## Files to know

| File or directory | Why it matters |
|---|---|
| `AGENTS.md`, `CONTRIBUTING.md` | Required workflow, simple technical English, branch conventions, R checks, and release rules. |
| `dev/stub_specs.R`, `dev/endpoint_eval/` | Shared generator runner/specs, schema parser, renderer, file protections, and drift detection. |
| `dev/generate_tests.R`, `dev/test_generation/` | Offline test generator and check modes; current scripts use global sourcing. |
| `R/hook_registry.R`, `R/hooks_*.R`, `inst/hook_config*.yml` | General runner mixed with client lookup; separate domain hook code and config. |
| `dev/check_hook_config.R`, `dev/remove_experimental.R` | Hook validation and destructive wrapper cleanup. Do not source/run cleanup as reconnaissance. |
| `.github/workflows/schema-check.yml`, `.github/workflows/cran-readiness.yml` | Current generation and static-test checks; client-owned automation. |
| `R/schema.R`, `R/zzz.R`, `R/z_generic_request.R` | Schema acquisition, endpoint/startup selection, and request transport. |
| `R/eco_lifestage_patch.R`, `dev/lifestage/`, `inst/extdata/ecotox/lifestage_patch_seed.csv` | Full lifestage derivation and evidence. |
| `data-raw/ecotox.R`, `inst/ecotox/ecotox_build.R`, `R/eco_functions.R` | Both build integrations and local/Plumber query contract. |
| `.github/workflows/db-ecotox.yml`, `R/z_db_version.R` | Rolling database publication and rebuild/version behavior. |
| `../amos-harmonizer/scripts/build-release.R`, `R/accessors.R`, `R/validation.R` within that project | Reusable offline table, hash, and release patterns. |

## Code context and important limits

- Existing generator: `run_generator(spec, pkg_dir)`; `api_specs` includes CT, Chemi, and EPI. Reuse ordinary spec lists and callbacks.
- Existing hooks: `run_hook(fn_name, hook_type, data)` supports `pre_request` and `post_response`. Generated wrappers invoke it; transport helpers do not centrally invoke all hooks.
- Preserve manual-then-generated `pre_request` merge/deduplication. `post_response` does not use that same special merge rule.
- Preserve `params` write-back, `skip_request`, post-response result handling, and `comptoxr_*_hook_error` classes through a client adapter.
- Generated tests inspect the wrapper and mock its helper. Their current `try(..., silent = TRUE)` can hide failures after the helper call. Add independent expected requests and successful-completion checks; do not claim wire or response conformance from helper-call tests alone.
- The schema diff classifies added parameter names as non-breaking without requiredness analysis. Public claims need a supported subset and an unknown/review-required outcome.
- Generic generation must not skip valid no-input POST actions, infer pagination solely from a name, resolve chemical identifiers, or switch hosts unless the client policy asks for it.
- Lifestage runtime joins use `org_lifestage`, not a taxon key. Unresolved seed categories may not reach query output; missing reproductive status must not become `FALSE`.
- Old ComptoxR clients require a dictionary. Do not replace rolling DB assets with source-only builds before a compatible client/server rollout and a legacy asset are available.

## Resume instructions

1. Read the linked plans and check `git status --short`, current branch/log, and sibling AMOS state. Preserve user work and account for any changes since the recorded baseline.
2. Start implementation on a dedicated branch from the project-approved base (`integration` per CONTRIBUTING). Make the planning files available from these documentation commits without mixing unrelated changes. Use a separate checkout if required; do not reset the current workspace.
3. Establish the toolkit baseline with fixed local schemas. Create a sourceable R verification script if needed. Start with:

   ```r
   devtools::test(filter = 'generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts|hooks')
   ```

   Expected: relevant existing tests pass or their pre-existing failures are recorded with exact errors. Check skip counts; a skipped test is not a pass.
4. Run `Rscript dev/generate_tests.R --check` and `Rscript dev/check_hook_config.R` in a controlled checkout. Expected: valid generated output/hooks and no file changes. If they fail, inspect the relevant config, emitted wrapper, and test helper before changing the engine.
5. Implement toolkit phase one/two from its plan, using temporary output directories and fixed inputs. Expected: stable signatures and helper arguments, unchanged protected-file hashes, no network, and an idempotent second pass.
6. Continue through the listed gates. Run broader package checks after the installed-toolkit/runtime boundary changes; update this handoff with commits, commands, results, and remaining work.

## Setup required

- Windows/PowerShell workspace. Prefer `rg`; pass directories plus `-g` patterns instead of shell globs that PowerShell does not expand for native tools.
- Check R, package dependencies, and formatter availability before baseline verification. Runtime availability was not tested during planning.
- No credentials are required for the intended offline extraction checks. Do not refresh schemas or re-record cassettes just to establish parity.
- The OpenAPI Generator comparison may require its supported CLI environment. It has not been installed or run as part of this session; isolate its output from the repository.

## Warnings

- Do not run `dev/generate_stubs.R` or the schema workflow casually: generation writes files, and workflow cleanup deletes eligible wrappers first.
- Use the normal release workflow; do not manually edit ComptoxR's DESCRIPTION version or create release tags.
- Use Conventional Branch and Commit names without model/tool attribution. Commit and push coherent work as required by the environment instructions.
- No tests, scientific review, broad OpenAPI conformance, or deployed compatibility have been certified by these planning documents.
