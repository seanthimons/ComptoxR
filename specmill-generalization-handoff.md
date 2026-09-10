# Handoff: generalize wrapmaint for other API clients

Historical plan from before the specmill rename. Use CONTRIBUTING.md and
dev/ENDPOINT_EVAL_UTILS_GUIDE.md for the implemented workflow; the old names below
describe the original planning state.

**Generated**: 2026-09-08 10:30 -04:00
**Branch**: `fix/workflow-production-gaps` (ComptoxR)
**Status**: Initial extraction released. Configuration-driven generalization is not implemented.

## Goal

Move reusable API maintenance code into wrapmaint and replace ComptoxR's
remaining development machinery with a small configuration and ordinary R
callbacks. Preserve existing ComptoxR contracts and prove reuse with a client
that has no chemistry-specific inputs. This handoff records proposed next work;
the current request is to save context, not to implement or release it.

## Completed

- wrapmaint 0.1.0 is an installed development package with a neutral generator,
  schema reader, comparison, fixture generation, file ownership protection,
  hook validation, request checks, and compatibility functions.
- Its source repository is `C:/Users/sxthi/Documents/wrapmaint`, branch
  `feat/schema-toolkit`, commit `aae88f99f6bd355a06d3404fd100b86620609e83`.
  Earlier extraction commit: `d2be109`. No Git remote is configured there.
- The verified archive is attached to ComptoxR's 2.0.0 release:
  https://github.com/seanthimons/ComptoxR/releases/download/v2.0.0/wrapmaint_0.1.0.tar.gz
  SHA-256: `a9e8ff83f1316b1e3059c63ab84e7aa01567bb7c2156259400bf791781408fe0`.
  `dev/toolkit-lock.json` pins this artifact; `dev/install_toolkit.R` checks its
  checksum before installation. Do not replace that immutable archive.
- ComptoxR invokes the installed engine through `dev/toolkit_adapter.R` and
  maintenance scripts. There is no wrapmaint runtime dependency in ComptoxR
  or the generated catalogue client.
- Before endpoint policy changed, the extraction preserved 387 generated files
  at the parsed-code, signature, documentation, and generated-YAML level; 474
  protected runtime/schema/hook hashes were unchanged. These are historical
  migration counts, not the current production endpoint count.
- The recorded toolkit acceptance result was 425 assertions and R CMD check
  Status OK. Catalogue checks use independently written request expectations,
  successful completion, and four intentional faults. Two-client hook isolation,
  offline loading, file boundaries, rollback, and supported schema versions were
  checked. A 2,000-operation case took 18.13 seconds in the recorded environment.
- ComptoxR 3.0.0 ships the subsequent production-only endpoint policy. Current
  generated contract inventory has 336 files. The reduction is an intentional
  endpoint-policy change, not evidence of extraction failure.

Verification above is recorded migration evidence, not a fresh rerun during
this handoff. See `dev/migration-evidence/verify-toolkit.R`,
`generator-parity.R`, `toolkit-render-parity.txt`, `toolkit-protected.txt`,
`toolkit-comparison.md`, and `dev/reports/migration/publication.md`.

## Current State

**Working:** neutral generation with an R list; installed compatibility engine
with ComptoxR-owned policy; production generation and checks in CI.

**Not available:** a YAML/TOML configuration loader, a complete configuration
reference, or one configuration-driven pipeline that replaces all remaining
ComptoxR development implementation. Do not describe these as shipped features.

**Important correction:** the local modules are not all thin shims. At
`bc22753`, `dev/endpoint_eval/07_stub_generation.R` is about 87 KB,
`06_param_parsing.R` about 18 KB, and `04_openapi_parser.R` about 7 KB.
They retain substantive implementation. Other files, such as
`02_path_utils.R`, `03_codebase_search.R`, and `05_file_scaffold.R`, are small
compatibility entry points. Audit definitions and callers before classifying
or deleting a file. Initial extraction parity does not prove full generalization.

The two paths currently coexist:

```text
Neutral: local JSON -> read_operations -> render_operation -> apply_files
ComptoxR: CLI -> toolkit_adapter -> client specs/context + bind_tools
          -> local rendering policy + installed engine -> apply_files
Runtime: generated wrapper -> client request helper and local runtime hooks
```

The original extraction plan explicitly kept client policy local. Moving more
of it to declarative configuration is a follow-up design, not a completed part
of the original migration.

## Actual API and configuration

```r
spec <- list(
  files = '/absolute/path/openapi.json',
  helper = 'request_helper',
  policy_version = 'reviewed-1'
)
wrapmaint::generate_client('/existing/client/root', spec, 'plan')
wrapmaint::generate_client('/existing/client/root', spec, 'apply')
wrapmaint::generate_client('/existing/client/root', spec, 'check')
```

`generate_client(root, spec, mode = c('check', 'plan', 'apply'))` currently
accepts an R list. Schema input is local JSON. The implementation also reads
`policy`, `renderer`, `hooks`, `hook_callback`, and `contracts`; generated
contract tests use further fields such as `package` and `response_fixture`.
Read `R/generation.R`, the test renderer, and catalogue before freezing a full
field reference. Do not infer supported fields from this short example.

The default helper accepts `method`, `path`, `path_params`, `query`, and `body`.
It owns transport and serialization. A `page` parameter is one helper call,
not an automatic pagination loop. Hook stages are ordered `pre_request` and
`post_response`; callbacks handle state, skip/result behavior, and errors.

`bind_tools(group, envir)` rebinds compatibility functions into an explicit
client environment. It does not make the client policy portable by itself.

| Current file | Actual role |
|---|---|
| `dev/toolkit-lock.json` | Development dependency URL, version, checksum and policy version |
| `dev/stub_specs.R` | CT/Chemi/EPI schema selection, names, helper contracts, preparation and coverage |
| `dev/endpoint_eval/` | Mixed policy, substantive implementation, and compatibility entry points |
| `dev/test_generation/` | Mixed client fixtures, test rendering policy, and toolkit entry points |
| `dev/toolkit_adapter.R` | Explicit context, temporary generation, formatting, ownership and manifest |
| `dev/generate_stubs.R`, `dev/generate_tests.R` | Maintainer commands and CI outputs |
| `inst/hook_config.yml` | ComptoxR runtime hook configuration; not a toolkit project config |
| `air.toml` | Formatting only |
| wrapmaint `README.md`, `man/wrapmaint.Rd` | Current user reference; one combined help topic, no full tutorial |
| wrapmaint `tests/catalogue.R`, `inst/catalogue/` | Independent second-client example and request expectations |

## Not Yet Done

1. **Freeze the current production baseline.** Use the integrated workflow/doc
   follow-up when available. Record commit, installed toolkit version, input
   hashes, generated contracts, manual files, hooks, exports, and docs. Do not
   restore the pre-migration staging wrappers to recreate historical counts.
2. **Inventory remaining code and callers.** Trace both generation paths, diff,
   coverage, tests, hook checks, and CI. Mark each definition as reusable engine,
   declarative setting, necessary callback, or redundant compatibility layer.
   Include the large renderer and parameter modules, not just the small shims.
3. **Define one versioned configuration contract.** YAML is the proposed first
   format; it is not implemented or a final field design. Reuse the existing R
   spec internally. Do not add YAML and TOML parsers simultaneously without a
   demonstrated need. Candidate settings: local schema paths, production
   selection, operation naming overrides/prefixes, exclusions, helper names,
   output ownership, hook names, and reviewed fixture values.
4. **Validate configuration before any writes.** Reject unknown fields, wrong
   types, unsupported config versions, conflicting operation names, and unsafe
   paths with useful messages. Resolve paths relative to an explicit root.
   Preserve absent/null/false/zero distinctions. Disable executable YAML tags;
   never evaluate schema text or config strings as R code. Resolve callback
   names only in an explicitly supplied environment.
5. **Move common behavior into wrapmaint.** Translate existing client rules into
   data where possible. Retain ordinary client callbacks where behavior is
   executable. Avoid moving chemistry branches unchanged into a supposedly
   generic engine. No new plugin registry or HTTP framework is needed.
6. **Unify generation, comparison, coverage, tests, and hook validation.** All
   must consume the same resolved operation inventory and configuration. Keep
   unsupported/excluded/manual/generated counts separate. Retain structured
   outputs and thin CI scripts for exit codes and GitHub reporting.
7. **Migrate two clients through the same public interface.** Use ComptoxR and
   the non-chemical catalogue. The second client must work without engine edits
   or a hidden ComptoxR profile. Preserve the existing R-list API where feasible;
   the config loader should feed it rather than create a second engine.
8. **Delete only replaced local implementation.** Remove compatibility files
   after searching every caller and updating scripts, CI, docs, and tests.
   Keep service acquisition/authentication and runtime hooks client-owned.
9. **Write usable documentation.** Add installation, a complete config field
   reference, an end-to-end second-client walkthrough, callback examples,
   supported-schema matrix, diagnostics, check/plan/apply, manual-file protection,
   upgrades/rollback, and the boundary between helper checks and HTTP proof.
10. **Publish and adopt a new toolkit version.** Establish a source remote and
    normal toolkit release process; none is configured in the local source repo.
    Verify the downloaded archive in an isolated library, then update the
    ComptoxR pin. Do not hand-edit ComptoxR's version or automatically cut another
    package release for development-only work.

Proposed convenience interface, **not callable today**:

```r
wrapmaint::generate_client(root = '.', config = 'wrapmaint.yml', mode = 'check')
```

## Acceptance gates for the follow-up

- Current ComptoxR supported wrappers preserve names, formals, request shapes,
  hook order/state, manual files, and generated docs. Any intentional difference
  is separately explained; configuration migration alone should not change them.
- Repeated generation is deterministic; check/plan are read-only; a second apply
  has no changes. Generation works from outside the client working directory.
- Installed toolkit passes `tests/catalogue.R`, `tests/boundaries.R`,
  `tests/schema-versions.R`, `tests/loading.R`, and R CMD check.
- Both clients run without wrapmaint installed or loaded. Loading any package
  does not generate files, make requests, or alter endpoint/session settings.
- Config and schema adversarial checks cover invalid paths/symlinks, name
  collisions, malformed fields, quotes/newlines, local/external/cyclic references,
  unsupported bodies, and missing/default/null values. Failure leaves owned and
  manual output intact; existing interrupted-apply recovery remains available.
- Independent request expectations catch wrong method, path/query/body placement,
  required-input handling and hook-order errors. Test successful return values;
  a captured helper call followed by an error is not a pass. Verify encoding and
  serialization with a deterministic local HTTP server where needed.
- Re-run the recorded large-operation case and report time/memory with environment
  details. Avoid per-operation reparsing and accidental quadratic scans.
- Run ComptoxR generation/test freshness, hook and public-boundary checks, the
  targeted pipeline tests, and rendered documentation checks using the new pin.

## Resume Instructions and setup

1. Read this file, `schema-tooling-extraction-plan.md`, `CONTRIBUTING.md`, and
   each repository's own instructions. Check Git status and remotes again.
2. Check PR 309 before branching from integration. As of this handoff it is open:
   https://github.com/seanthimons/ComptoxR/pull/309
   Implementation `6c0970b` passed all CI checks. Documentation follow-up
   `bc22753` rendered locally; verify its current CI status rather than assuming
   the earlier green checks cover it.
3. Use separate implementation worktrees. The current documentation worktree is
   `C:/Users/sxthi/Documents/ComptoxR/.worktrees/workflow-production-gaps`.
   Its runtime/toolkit changes are already committed. Before this handoff edit,
   it and the wrapmaint source repository were clean.
4. Freeze inputs, then implement the smallest complete configuration path for
   both clients. Do not begin with wholesale deletion or live schema refresh.
5. Start from these existing checks (run from the relevant repository):

   ```r
   source('dev/install_toolkit.R')
   install_toolkit() # Intentional download of the pinned development package.
   devtools::test(filter = 'generate_tests_pipeline|stub_generation|diff_schemas|hooks')
   ```

   ```sh
   Rscript dev/generate_stubs.R --check --rebuild=ct --rebuild=chemi --rebuild=epi
   Rscript dev/generate_tests.R --check
   Rscript dev/check_hook_config.R
   Rscript dev/check_public_api.R
   ```

   Expected: current generated output, valid hooks, no forbidden public inputs,
   and no changes. If not, inspect the pin, Air version, local policy, and baseline
   before changing generated files. Use sourceable R scripts for added checks.

R dependencies and Air 0.9.0 are needed. On this Windows host R is 4.5.1; some
installed dependencies emit newer-build warnings. Setting `LC_ALL=C` avoids
unsupported inherited `C.UTF-8` locale errors; read UTF-8 docs explicitly.
Offline acceptance needs no production credentials or cassette recording.

## Failed Approaches

No YAML/TOML implementation has been attempted. Keeping a large local renderer
was a compatibility decision; calling every remaining module a thin adapter
was inaccurate. File deletion alone cannot complete this generalization.
The original plan's OpenAPI Generator comparison is not established by the
recorded extraction results; do not claim a comparative evaluation was done.

During documentation verification, `pkgdown::build_articles(articles = ...)`
failed with an unused-argument error. Installed pkgdown supports individual
`pkgdown::build_article('articles/development-lifecycle')` calls instead.
Rendered article content and public-boundary scans then passed.

## Key decisions and warnings

- Keep HTTP execution, credentials, pagination behavior, and hook runtime local.
  Config can name a callback; it does not replace executable behavior with YAML.
- Support is a declared subset of OpenAPI 3.0/3.1 and Swagger 2.0, not full
  conformance. YAML project configuration does not imply YAML schema support.
- Production-only applies to public ComptoxR output. Explicit URLs remain
  supported; local development clients stay outside public checkouts. EPI Suite
  at `https://episuite.dev/api` is approved production despite the domain suffix.
- Preserve original user changes: untracked `endpoint-audit.md` in the original
  ComptoxR checkout and modified `CONTEXT.md` in the original harmonizer checkout.
  Do not reset/clean those repositories or alter users' databases/mapping evidence.
- Handoff creation does not require package tests or a release. Review links,
  paths, signatures, hashes and the Markdown diff; preserve prior migration
  evidence in `HANDOFF.md` and `dev/reports/migration/publication.md`.
