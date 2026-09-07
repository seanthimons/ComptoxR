# Schema, test generation, and hook extraction assessment

## Executive summary

**Feasible, with substantial separation work. Estimated effort: L, 10-17 working days for one maintainer.** A useful developer-tool package can come first in about 5-8 days. The complete estimate includes hook runtime extraction, a second consumer fixture, installed-package checks, and ComptoxR migration. It excludes full OpenAPI conformance and a general HTTP client library.

**For a general package that new users can use with a supplied default renderer, allow 13-22 days total.** The additional 3-5 days cover a neutral request mapping, removal of implicit service policies, and the broader second-client acceptance cases below. These estimates need confirmation during the first extraction step.

The reusable product is an **R API wrapper maintenance toolkit**: read schema snapshots, identify operations, compare changes, generate wrappers and offline tests, preserve manual code, and validate configured hook calls. The existing modules already provide much of that process. However, they also embed CompTox naming, chemical inputs, request helpers, stage selection, response fixtures, and repository paths.

**Recommendation: one new package, extracted in two steps.** First move the development tools and keep ComptoxR's runtime unchanged. Then move the small, general hook runner into the same package, with per-client configuration and function lookup. Keep chemical and service-specific hook functions in ComptoxR. Do not combine this toolkit with the proposed environmental harmonization package: their users, runtime needs, and release reasons differ.

A separate package is justified if another client can use this process with a small configuration and ordinary R callbacks. A second synthetic client is a release gate. If that client requires new chemistry-specific branches in the engine, the extraction is not complete. A package rename alone would only relocate the coupling.

## Scope, assumptions, and success criteria

Reconnaissance used the local ComptoxR tree at commit `2745f6b`, including `CONTRIBUTING.md`, the generator modules, representative generated wrappers, runtime hooks, test helpers, schema diff, and GitHub workflows. This document follows the assessment style of `endpoint-audit.md`. The existing untracked audit remains unchanged.

"Hooks" here means `pre_request` and `post_response` hooks used by API wrappers, including their YAML configuration, generated invocation code, and validation script. Git pre-commit hooks and agent hooks are outside scope.

Success means:

- ComptoxR can regenerate the same supported wrapper contracts and offline tests using an installed toolkit from outside its checkout.
- Generated files keep their current public function names, parameters, request behavior, and hook order unless a separate change is documented.
- A second client with no chemical identifiers can generate, install, and test a wrapper with both hook stages.
- Tool installation and loading cause no network requests, file generation, client package loading, or changes to global configuration.
- The package documents the schema constructs and test guarantees it actually supports.

This is a feasibility assessment, not a full implementation audit or conformance test. No generator, schema refresh, cleanup script, or live endpoint was run for this document.

## Current end-to-end process

```text
Service schema downloaders in R/schema.R
  -> schema/*.json snapshots
  -> schema-check.yml canonicalization, hashes, and diff report
  -> removal of eligible experimental wrappers
  -> dev/generate_stubs.R + dev/stub_specs.R
     -> endpoint_eval modules
     -> R wrappers + generated stage-hook YAML
  -> roxygen documentation
  -> gap inventory + generated offline helper-call tests
  -> static generated-test check + coverage reports
  -> repository-owned update PR

At runtime:
generated wrapper -> configured pre-request hooks
                  -> ComptoxR request helper
                  -> configured post-response hooks -> result
```

Hooks execute in generated wrappers, not centrally in `generic_request()`. Moving only the registry does not move the generated request-state construction or write-back behavior. Moving the generator alone does not remove runtime hook dependencies.

`dev/stub_specs.R` already separates a shared `run_generator()` from `ct_spec`, `chemi_spec`, and `epi_spec`. Coverage uses those same specifications. This is the best starting point. Despite being described as sourceable, it attaches packages, sources modules, and loads the hook registry into the sourcing environment; it is not a clean installed-package API yet.

## File and ownership inventory

| Current location | Role and coupling | Destination |
|---|---|---|
| `R/schema.R` | CT/Chemi/EPI schema acquisition; service-specific endpoints and selectors, `here` paths, and environment changes. | Keep service discovery and authentication in ComptoxR maintenance. Toolkit accepts local documents; a small explicit-URL downloader can follow only if needed. |
| `dev/endpoint_eval/01_schema_resolution.R` | Swagger/OpenAPI version detection, references, body properties, schema-file selection. | Move general parsing and resolution with an explicit support matrix. Keep service selection policy in client specs. |
| `dev/endpoint_eval/02_path_utils.R`, `03_codebase_search.R`, `06_param_parsing.R`, `08_drift_detection.R` | Route normalization, source search, parameter parsing, and wrapper drift. | Move general operations. Pass root, naming rules, helper contracts, and exclusions explicitly. |
| `dev/endpoint_eval/04_openapi_parser.R` | Operation and body metadata plus pagination detection. | Move parser; retain service pagination patterns as client data. |
| `dev/endpoint_eval/00_config.R` | Shared helpers mixed with Chemical schema patterns, EPA pagination rules, and exclusions. | Split by ownership. Chemical patterns and endpoint exclusions remain in ComptoxR. |
| `dev/endpoint_eval/07_stub_generation.R` | About 2,560 lines of rendering, signature overrides, hook state, request templates, resolver behavior, and API branches. | Move common rendering; move CompTox request policies to a client adapter. This is the largest extraction task. |
| `dev/endpoint_eval/05_file_scaffold.R` and `dev/remove_experimental.R` | Write/append protections and deliberate removal of experimental exports. | General file-ownership checks can move. Keep the decision to remove a family in the client workflow. Never make deletion an implicit package-load action. |
| `dev/stub_specs.R` | Shared runner, collision handling, stage-contract comparison, API naming, prepare/finalize steps, generated stage YAML, coverage. | Move runner and reusable comparison; retain `ct`/`chemi`/`epi` specs and endpoint policy in ComptoxR. |
| `dev/generate_stubs.R` | Top-level generation, formatting, logs, reports, and GitHub outputs. | Replace with a thin client script calling toolkit functions. |
| `dev/test_generation/00_config.R` through `06_static_validation.R` | Export inventory, wrapper AST inspection, example values, rendering, file ownership, static checks. | Move engine. Supply target package, helper names, test values, and response fixtures from the client. |
| `dev/test_generation/07_token_preflight.R` | CompTox token checks for live cassette recording. | Keep in ComptoxR. It is not part of offline test generation. |
| `dev/generate_tests.R` | CLI modes, build/check process, global module sourcing, GitHub summaries. | Preserve CLI entry point as a thin adapter; engine functions must also be callable interactively. |
| `tests/testthat/helper-generated-contracts.R` | Package loading, mocked chemical responses, resolver stand-ins. | Keep chemical fixtures local. Generalize only the small harness required by another client. |
| `dev/detect_test_gaps.R`, `dev/calculate_coverage.R`, `dev/diff_schemas.R` | Inventory/coverage and schema change reports, with repository and service assumptions. | Move calculations and structured results; keep badges, output paths, baseline policy, and GitHub output writing local. |
| `R/hook_registry.R` | YAML merge, lazy config cache, ordered runner, error wrapping; hard-coded ComptoxR namespace and paths. | Move merge/runner logic in step two. Keep a thin local adapter and client-owned cache if needed for compatibility. |
| `inst/hook_config.yml`, `inst/hook_config_generated.yml` | Manual request/output policy plus generated stage support and fallback metadata. | Remain client-owned data. Toolkit reads explicit paths/configuration and emits the generated portion. |
| `R/hooks_*.R` | Chemical resolution, descriptors, hazard/list/property/EPI/WebTEST transforms, validation, and server fallback. | Keep domain behavior in ComptoxR. Do not transfer it into generic hook execution. |
| `dev/check_hook_config.R` | Sources hook files; checks hook names, parsed formals, emitted stages, and request templates. | Move validation functions; retain a client CLI and explicit hook environment. |
| `.github/workflows/schema-check.yml`, `cran-readiness.yml` | Refresh, destructive rebuild selection, test freshness check, reports, release credentials, PR creation. | Remain repository orchestration; call a pinned toolkit version. No PR or credential machinery in the R core. |

The endpoint modules, test-generation modules, `stub_specs.R`, and `diff_schemas.R` together exceed 8,000 lines before runtime hooks and tests. This is not a small file move. The table identifies candidates, not a claim that each whole file is portable.

## Findings that control feasibility

### 1. Schema parsing supports a subset

`detect_schema_version()` recognizes Swagger `2.*` and OpenAPI `3.*`. That recognition does not establish conformance across those versions. Reference resolution has a depth limit of three by default and can return partial data for circular references. Existing tests cover selected `oneOf` bodies and deliberately block free-form object bodies and unsupported variants.

Publish a tested feature matrix, including version, parameter location, local references, body shape, composition, media type, and unsupported behavior. Unhandled constructs must produce a useful diagnostic or a protected manual-wrapper entry. Do not turn a partial parse into a claim that an operation is fully implemented.

OpenAPI parameters include identity by name and location, requiredness, and serialization rules; request bodies and responses have separate structures. Preserve these distinctions in the supported operation record. Do not infer broad support from successful parsing of `paths`. See the [OpenAPI 3.0.3 specification](https://spec.openapis.org/oas/v3.0.3.html#parameter-object).

### 2. The renderer embeds the client request model

Generation switches between `generic_request()` and `generic_chemi_request()`, supplies CompTox server keys, detects Chemical records, and can generate identifier-resolution calls. EPI has its own server/auth and raw-response behavior. Templates and YAML can also override signatures and request construction.

Keep that request model in a ComptoxR adapter. Reuse the existing spec-list pattern and ordinary R functions; do not add a class system or a general template language. The toolkit should accept a supported operation record and a client renderer/request mapping. It should not invent a replacement for the mature HTTP helpers as part of extraction.

### 3. Generated tests are primarily helper-call contracts

`dev/test_generation/01_inventory.R` starts from exported R functions. `02_wrapper_metadata.R` inspects their calls. `04_renderer.R` mocks the named helper and asserts captured arguments. Thus much of the expected behavior comes from the same wrapper being tested, rather than an independent interpretation of the upstream schema.

The rendered test currently catches the wrapper result with `try(..., silent = TRUE)`, then asserts that a helper call was captured. A failure after that helper call can therefore escape detection by this template. Some dynamic arguments receive only presence/permissive shape checks. The chemical response fixture also cannot represent arbitrary APIs.

Keep the existing generated tests as regression coverage, but name them accurately. Do not advertise response validation, transport validation, or proof of schema conformance. Before the first public toolkit release, add a small independent fixture with manually specified expected method/path/body and assert successful wrapper completion. Test a deliberate post-response failure to prove it fails the check. Do not generate those expected values by re-reading the wrapper under test.

When the runner moves packages, keep request-helper mocks in the target client's namespace, where the wrapper resolves them. Moving `.package` to the toolkit would mock the wrong binding. This follows [testthat's binding-mocking guidance](https://testthat.r-lib.org/reference/local_mocked_bindings.html).

### 4. Hook state is an interface that must be preserved

The existing merge uses `utils::modifyList(manual, generated)`, then specially combines and deduplicates `pre_request` in manual-then-generated order. It does not apply that same special merge to `post_response`. Preserve this behavior and test it before considering a policy change.

Pre-hooks receive state that includes `params`; generated code handles parameter write-back and `skip_request`/`result`. Request-template paths can also carry request state. Post-hooks receive the result and parameter context, and can return a final value rather than another state list. The runner injects function/stage metadata into list values and wraps failures in stage-specific `comptoxr_*_hook_error` conditions.

A generic runner must receive configuration and an explicit hook lookup environment or named function list. It must not search another client's namespace or share one global registry across installed clients. A thin ComptoxR adapter can preserve current error classes, cache behavior, and `run_hook()` calls. Test two clients that use the same wrapper and hook names.

### 5. File ownership is part of the product

The test scaffold recognizes generated headers, protects manual tests, and removes obsolete or legacy generated tests. Wrapper cleanup uses roxygen lifecycle and stage tags to protect stable/mixed/untagged files. These are useful safeguards, but package extraction must preserve their exact scope.

The current workflow deletes eligible experimental wrappers before generation. The new process should render into a temporary directory, parse and validate all output, and only then apply a reviewed file list. Limit writes/removals to resolved paths inside the supplied target root and files owned by that generator. Preserve manual blocks and protected lifecycle files. On failure, leave the previous usable output intact.

Changing the generated header during extraction can make old generated files look manual or obsolete. Recognize the old header explicitly in the transition; do not use a broad file-name match to assume ownership.

### 6. Reports need bounded claims

`classify_param_change()` in `dev/diff_schemas.R` treats removed parameter names as breaking and added names as non-breaking. That is not sufficient for general API compatibility: an added required input needs different treatment. Type, enum, requiredness, serialization, and response changes also need explicit coverage or an "unknown/review required" result. The OpenAPI [Parameter Object](https://spec.openapis.org/oas/v3.0.3.html#parameter-object) defines the requiredness and location information that a supported comparison must retain.

Keep existing counts for ComptoxR comparison during extraction, but do not publish them as a universal breaking-change classifier. Expose structured findings with reasons and a declared support scope.

Coverage and generation currently share service specs. Preserve that strength. Report unsupported, excluded, protected/manual, generated, and checked operations separately so exclusions cannot inflate a claim of complete API support.

## Minimal package design

One package is sufficient. Use a working label, "API wrapper toolkit", until a package name is selected and checked.

Illustrative public functions, not current APIs:

| Function | Purpose |
|---|---|
| `read_operations(files, policy)` | Return the existing endpoint-table style of operation records plus unsupported diagnostics. |
| `compare_operations(old, new)` | Return bounded structural change findings. |
| `generate_client(root, spec, mode = 'check')` | Render/validate wrappers, hook metadata, and tests; `plan` lists changes and `apply` writes validated owned files. Reuse existing generation stages internally. |
| `validate_hooks(config, wrappers, hooks)` | Check names, supported stages, signatures, and generated call sites without making API requests. |
| `run_hooks(config, hooks, function_name, stage, data)` | Execute an ordered chain with client-supplied lookup and compatible error handling. Added in step two. |

Use explicit `root`, input paths, target package, and spec values. Return structured results; client CLI scripts translate them into exit codes, reports, or `GITHUB_OUTPUT`. Replace repeated source-file parsing with one per-run inventory passed to the consumers. For example, the current hook checker reparses R files for each configured wrapper; that cost grows with both wrapper count and file count.

Keep the normal hook runtime small. Its imports need only the dependencies actually used there. Generator-only packages such as roxygen2/testthat and the generation data tools can be checked when generation functions are called. Do not require `library(tidyverse)` to run an installed client hook. Audit actual package calls before assigning DESCRIPTION dependencies; do not copy ComptoxR's DESCRIPTION wholesale.

Generated clients keep their R wrappers, documentation, hooks, and tests in their own repository. Before runtime extraction, the toolkit is a pinned development dependency. After runtime extraction, ComptoxR imports the toolkit's compatible runtime API. The toolkit must never depend on ComptoxR. Pin the generator release in CI and record its version, input hashes, and client policy version in a small generation manifest.

YAML defaults and request-template expressions are maintainer-authored code, not untrusted schema data. Do not evaluate remote examples or descriptions as R expressions. Escape external strings when emitting code/docs, parse output before writing it, and resolve hook names only in the explicitly supplied environment. Test quotes, backticks, newlines, non-syntactic parameter names, invalid paths, and cyclic references at these boundaries.

## Concrete path to generalization

### Product position and existing tools

OpenAPI Generator already supplies an R client generator with an `httr2` library option and configurable package/naming settings. A new package should not assume that generating an R client is an unmet need. Its documented feature matrix also has limits, so a replacement decision needs a fixture comparison, not a feature-name comparison. See the [official R generator documentation](https://openapi-generator.tech/docs/generators/r/).

The stronger product hypothesis is **safe maintenance of an existing R API package**: keep its public function names and manual code, regenerate supported operations, check request contracts, and preserve explicit hook customizations. That hypothesis comes from the local implementation; competitive advantage has not been demonstrated by running other tools.

Compare these paths during step one:

| Path | Suitable use | Decision test |
|---|---|---|
| Use OpenAPI Generator directly | New client without an established ComptoxR-style public API. | Generate the small neutral fixture with its R/httr2 option and inspect output, tests, and customization requirements. |
| Extract this toolkit | Existing procedural R client with local request helpers, manual functions, and configured pre/post hooks. | Preserve the frozen ComptoxR contracts and maintain the neutral client without engine edits. |
| Extract maintenance/checking only; reuse another renderer | Existing generator output already meets client needs. | If the fixture comparison shows no benefit from our rendering, keep inventories, ownership checks, and hook validation instead of maintaining another renderer. |

Use httr2 for HTTP construction and execution if the neutral client needs a transport helper. Its own guidance describes the request/helper structure of an R API package. Do not add retries, OAuth, connection pools, or transport classes to this extraction. See [Wrapping APIs with httr2](https://httr2.r-lib.org/articles/wrapping-apis.html).

### A neutral operation record, based on what already exists

`openapi_to_spec()` already returns a tibble with method, route, descriptions, separate path/query/body metadata, body schema, response information, and pagination metadata. Reuse this representation. Generalization needs a few clear ownership changes, not a second parser model.

| Record part | General contract | Change from current behavior |
|---|---|---|
| Identity | Source document ID + method + path; keep source `operationId` separately. | Do not use function name as operation identity. Keep ComptoxR's current name mapping as explicit compatibility policy. |
| Parameters | Structured records keyed by location and original name; preserve type, requiredness, default presence/value, enum, and supported serialization fields. | Comma-separated name strings can remain reports, but cannot be the source of truth. Distinguish no default from an explicit null default. |
| Body | Requiredness, content type, shape, and the supported source schema/reference. | Remove `needs_resolver` from generic parsing. A ComptoxR adapter can annotate Chemical resolution afterward. |
| Response | Declared status/content metadata and retained schema/reference. | Retention supports docs and diagnostics; it does not promise runtime response validation. Client controls final R shape. |
| Provenance | Source hash, schema version, and explicit source variant if supplied. | `prod/staging/dev` is a client choice, not a mandatory generic concept. |
| Support | Supported, unsupported, or manual; reasons include the source operation and construct. | Missing metadata must not silently become a successful GET wrapper for `/unknown`. |

For the first neutral renderer, support the fixture-defined subset: scalar path/query parameters, explicit JSON object/array bodies, local supported references, and ordinary responses. Retain existing ComptoxR cases through its adapter. Report headers, cookies, serialization styles, remote references, recursive composition, multipart, or other constructs as unsupported wherever no tested implementation exists. Do not claim to support or reject an entire OpenAPI version solely from its version string.

### Defaults that must become explicit policies

These are concrete portability blockers found in the current code:

- `CHEMICAL_SCHEMA_PATTERNS`, `needs_resolver`, and chemical example values are domain policy. The general engine must not identify every `query` as a DTXSID.
- Pagination inference uses EPA route and parameter patterns. Retain it as an optional client policy; a parameter named `page` alone must not create an automatic multi-request loop.
- Preprocessing excludes service route patterns. The generic default must retain operations and report exclusions only when a client explicitly supplies them.
- `render_endpoint_stubs()` treats certain POST operations without input as empty and skips them. A generic API can have a valid no-argument action endpoint. Test that case and move the existing skip rule into the ComptoxR policy.
- `stubgen_build_request_template()` only permits `generic_request` and `generic_chemi_request`. Replace the hard-coded list with the client's declared helper contract. Do not accept arbitrary names from downloaded schemas.
- Stage collapse and fallback select public/staging/development behavior. Keep generic comparison of variants separate from client permission to change the server. No neutral wrapper should switch hosts because another schema variant contains its operation.
- Global reference/generation tracking environments must be scoped or reset per input/run. Two documents can reuse `#/components/schemas/Item` for different objects. They must never share a resolved definition just because the reference text matches.

### A small client interface with a useful default

Allow a new client to supply a package name, source snapshots, one request helper, and optional naming/fixture/hook overrides. Supply one general renderer for that declared request-helper shape; users should not have to write a renderer for every endpoint. Keep ComptoxR's existing specialized renderer as the compatibility adapter while common cases are separated.

The neutral helper can accept `method`, `path`, `path_params`, `query`, and `body`. The client owns base URL, authentication, HTTP execution, and response parsing. The first renderer supplies only supported parameter/media shapes. Unsupported shapes need an explicit manual wrapper or a separately tested extension. This is a function-call contract, not a new transport library.

Prefer a supported, unique `operationId` for neutral names. Otherwise use a deterministic method/path name and check collisions. Store reviewed name overrides so adding an operation does not rename an existing export. Continue using the current collision rules for ComptoxR until its parity checks pass.

Test-value selection should use a reviewed override, then a suitable schema example/default/enum, then a type-based fixture for the supported subset. Validate the choice against the constraints the toolkit supports. If no valid input can be constructed, report the missing fixture; do not guess a chemical identifier or emit a vacuous passing test.

Normal hook configuration remains an ordered list of local function names. Preserve the existing client payload during migration. New clients receive a documented state containing input parameters and optional skip/result information; post-hooks can return a final value. Do not expose an arbitrary event bus. Authentication and pagination continue to belong to the request helper unless the client deliberately implements them in a hook.

### Second-client acceptance example: a local catalogue API

Use a synthetic package with a small checked-in schema and a mocked helper. No public endpoint, account, or credentials are needed. This is a proposed acceptance fixture; it has not been implemented during reconnaissance.

| Operation or change | What it proves |
|---|---|
| `GET /items/{item_id}` with optional `language` | Separate path and query values; no identifier resolver; stable function name. |
| `POST /items` with a required JSON object | Explicit body shape and required field fixtures; no chemical-record assumption. |
| `POST /refresh` with no input | A valid action operation is not removed by the old empty-POST policy. The mocked helper must be called with POST. |
| `GET /items` with optional `page` | One call by default. Pagination is activated only by a declared client policy. |
| Pre-hook normalizes an input; post-hook extracts a field | Ordered custom behavior works without a renderer branch for this API. |
| Same hook names in this package and ComptoxR | Lookup/configuration remain isolated. |
| Added required query parameter | Diff reports review/breakage for the supported contract; generated test inputs update; existing names stay stable. |
| Two documents with an `Item` reference and different definitions | Reference identity includes the source document. |
| Unsupported body/serialization case | Clear diagnostic and no destructive replacement of a working manual function. |

For each generated wrapper, compare its call to a manually written expected method/path/parameter/body record. Include one transport-level fixture using a captured or mocked httr2 request to check URL encoding and JSON placement; helper-call assertions alone cannot establish wire behavior. Keep that check independent of the generated wrapper parser. An intentional wrong method, missing required value, wrong body, and failing post-hook must each produce a failure.

**Generalization gate:** the catalogue package uses the default renderer plus a small helper/configuration; there are no catalogue-specific branches in toolkit code. ComptoxR uses the same engine with its retained adapter. Run generation twice, install both clients, and verify manual-file hashes and runtime behavior. Record adapter size and repeated renderer logic as evidence; do not call the product general if the second client merely supplies a replacement generator of its own.

### Delivery choice

Target generalization in the first design, but deliver through ComptoxR parity first. Add the default neutral renderer and the full catalogue fixture as the additional 3-5 day milestone within steps two and four. A real second consumer can follow after that; synthetic reuse proves the boundary, not market demand or compatibility with every API.

If the existing-generator comparison wins, the reusable maintenance/checking package is still a useful result. If preserving the old renderer requires service policy inside the common parser, keep those branches in the ComptoxR adapter and narrow the advertised subset rather than expanding the toolkit indefinitely.

## Ordered migration plan and effort

### 1. Freeze and define contracts (1-2 days)

- Freeze schema/config inputs and generator version. Inventory current wrappers, exports, generated tests, manual exclusions, hook config, and reports.
- Capture representative cases: CT GET/query collision; object and alternative POST bodies; Chemi resolution; multi-stage conflicts; EPI raw output; WebTEST request template; no-parameter operations; manual and stable files.
- Establish expected signatures, helper arguments, hook order/output, and protected-file hashes. Run the existing relevant suites before changing code.
- **Gate:** fixed expected results exist and the required subset of schema behavior is documented. Record existing failures instead of treating them as extraction regressions.

### 2. Extract development engine with ComptoxR as first client (4-6 days)

- Package parsing, inventories, rendering, scaffold checks, test-generation functions, and report calculations. Reuse the current modules and spec-list interface.
- Keep service naming, exclusions, request helpers, stage policy, chemical fixtures, manual hook config, and callbacks in a sourceable ComptoxR adapter.
- Replace global sourcing/state and `here` assumptions with installed functions and explicit inputs. Keep thin `dev/` entry points so maintainer commands continue to work.
- Render in isolation and compare against the frozen output before applying any change. Review necessary formatting differences separately from behavior.
- **Gate:** same supported wrapper/test contracts, stable generated names, protected files untouched, and a second generation pass produces no changes. This completes the useful developer-tool milestone in an estimated 5-8 days total.

### 3. Extract the hook runtime (1-2 days)

- Move configuration merge and ordered execution with explicit client lookup. Keep domain hooks and request-state builders in the client adapter/generated wrappers.
- Retain a small ComptoxR `run_hook()` adapter to preserve call sites and error contracts. Update config loading to use the client package's installed paths.
- Test manual/generated merge, parameter write-back, skip, post-response transformations, errors, empty chains, and two-client isolation.
- **Gate:** installed wrappers behave the same with only the declared runtime dependency; neither client can use the other's hook functions accidentally.

### 4. Prove reuse and honest test coverage (2-4 days)

- Create one small non-chemical test package with a local schema, a local request helper, and pre/post hooks. No live service is needed.
- Generate, install, and test it from a directory outside either repository. Keep its fixture small enough to inspect by hand.
- Add the independent request expectations and successful-completion check described above. Require unsupported schema features and inconclusive diffs to be reported clearly.
- Test malformed input, deletion containment, manual file protection, interrupted generation, deterministic operation naming, and repeated schema references. Measure the large-input path with a repeated-operation fixture.
- **Gate:** no CompTox-specific imports, strings, or branch edits are needed for the second client; intentional request and post-hook faults fail the tests.

### 5. Switch CI and release (2-3 days)

- Install a pinned toolkit release in schema maintenance and readiness jobs. Keep download secrets, schedule, report publication, and PR creation in ComptoxR workflows.
- Preserve existing wrapper lifecycle protection. Replace delete-first generation with validated output application. Keep manual code and existing cassettes untouched.
- Make generation, test freshness, and hook validation required checks for a generated update. The inspected workflows invoke generated-test checking, but no invocation of `dev/check_hook_config.R` was found in `.github/workflows/`; wire that gate explicitly.
- Update developer docs, relevant test-path/readiness checks, and package dependencies. Remove old implementation modules only after installed-toolkit parity passes.
- Build/check both package tarballs and run the generated client suite. Record the generator/runtime compatibility range and provide rollback by pinning the previous toolkit and generated output.
- **Gate:** a clean checkout can produce and validate an update without local source-path fallbacks; ordinary installed clients need no development tools or credentials.

## Targeted verification inventory

| Existing check or area | Keep or move |
|---|---|
| `test-generate_tests_pipeline.R` | Move generic inventory/render/scaffold tests; retain chemical example/exclusion cases as client integration tests. |
| `test-stub_generation_call_shape.R` | Split generic request/body tests from WebTEST/descriptor/resolver policy tests; preserve all current cases. |
| `test-stub_generation_multischema.R` | Move generic deterministic naming/default tests; retain Chemi stage and committed-tree assertions locally. |
| `test-diff_schemas_counts.R` | Preserve accounting checks and add required-parameter/unknown classification cases for the public contract. |
| `test-hooks_stage_server.R`, `test-hooks_hazard.R`, `test-hooks_compound.R`, `test-hooks-webtest.R`, descriptor/list hook suites | Retain domain behavior in ComptoxR. Move only general runner tests. |
| `dev/check_hook_config.R` | Keep client command; test the new validation functions and call it in generated-update CI. |
| `dev/generate_tests.R --check` | Retain compatibility command and verify it remains read-only. Check no changes before and after. |
| Package build paths and tarball checks | Update tests that assume `dev/endpoint_eval` or `dev/test_generation` exist; run installed-toolkit tests instead of silently skipping. |

Do not re-record cassettes for this extraction. Existing mocked and synthetic tests cover the intended changes. Because generated output and runtime dependencies cross module boundaries, final package checks and the complete offline client suite are justified after focused checks pass.

## Main risks and decisions

| Risk | Level | Control |
|---|---|---|
| CompTox rules remain hidden inside a supposedly general engine | High | Small second-client gate; client-supplied request mapping, fixtures, naming, and stage policy. |
| Generator updates change hundreds of public wrappers | High | Pinned inputs/version; signature and request parity; no unrelated endpoint-policy changes. |
| Cleanup removes manual or usable files before a failure | High | Render/validate before applying; owned-file list, bounded paths, protected hashes. |
| Generated tests repeat the implementation's mistake or hide post-hook failure | High | Independent fixed expected requests plus an asserted successful result; explicit limits on test claims. |
| Hook namespace/cache or merge semantics change | High | Per-client state, local compatibility adapter, ordered-chain and error tests. |
| Schema parsing/diff report overstates support | High | Tested subset, explicit unsupported/unknown outcomes, no generic compatibility guarantee. |
| Toolkit adds development dependency cost to every client load | Medium | Small runtime path; generation-only dependencies loaded only by maintenance functions. |
| Endpoint policy work conflicts with stage-fallback hooks | Medium | Coordinate with `endpoint-audit.md`; host/environment rules remain client-owned and change separately. |
| Generation differs with formatter/tool versions | Medium | Pin formatting tools or compare parsed R structure where appropriate; keep signatures/docs separately checked. |

The smallest useful release is the development engine with a ComptoxR adapter. Do not add a new transport layer, full schema validator, plugin registry, template DSL, web dashboard, or multiple packages to reach that milestone. Extend supported schema behavior when a real client requires it and a fixture can define the expected result.

## Reconnaissance validation

Validated the assessment by reading the local source and tests and tracing the workflow commands. Consulted the official OpenAPI and testthat documents for the external contracts cited above. No runtime tests were run: this change adds a planning document only, and sourcing the current generator or cleanup entry points would change files. The implementation gates in this plan are proposed checks, not reported passes.
