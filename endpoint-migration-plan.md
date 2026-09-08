# Production endpoint migration plan

## Status and decisions

This is the authoritative endpoint implementation plan. It preserves the useful
findings from the local `endpoint-audit.md` and replaces its open policy choices.
The original audit is untracked user work; do not edit it or require it for a
fresh checkout. Inventory counts below are baseline observations, not release
assertions. Check them again on the implementation branch.

- Ship production operations and the shipped local Plumber APIs.
- `https://episuite.dev/api` is the approved EPI Suite production base. Its
  `.dev` suffix is not a reason to reject it.
- Keep explicit user URL configuration. Remove built-in non-production addresses
  and numeric staging/development selector modes in the breaking release.
- Remove stage-only exports without a production equivalent. Do not retain
  warning-only or error-only wrapper stubs. Regenerate production equivalents
  from approved production schemas and document replacement names.
- Keep development schemas, configured addresses, generated wrappers, tests,
  and metadata in an isolated local package directory outside the public checkout.
  Do not publish a development client package or copy its output into ComptoxR.
- Keep hook execution in ComptoxR. The development toolkit is not a runtime
  dependency.

The lifestage migration has the first release gate. Toolkit extraction may be
prepared in parallel, but its installed-package parity gate must pass before
endpoint generation policy changes. Integrate endpoint changes against the
source-only ECOTOX contract. See `HANDOFF.md` for ownership and release order.

## Background and inventory

The request layer already uses `httr2` and accepts environment-variable names or
literal URLs. No new HTTP library or configuration class is needed. The original
audit estimated 1-3 working days for endpoint work; schema comparison and broad
validation can increase this estimate.

| Area | Current implementation and required treatment |
|---|---|
| Selectors in `R/zzz.R` | `ctx_server()` and `chemi_server()` contain production and non-production choices, including commented constants. Remove the latter. Keep `epi_server()` production behavior. |
| Local selectors in `R/zzz.R` | `eco_server()` and `toxval_server()` select database paths, localhost Plumber, and browser sites. Preserve local database selection, custom paths, `url_only`, and localhost modes. Remove development choices. Public browser links are not REST API defaults. |
| Startup in `R/zzz.R` | `.onLoad()` selects CT/Cheminformatics non-production defaults for undated source builds and production for dated builds. Remove the date branch and endpoint environment mutation. |
| Generic transport in `R/z_generic_request.R` | `generic_request()`, `generic_chemi_request()`, `generic_search_request()`, and `generic_pubchem_request()` repeat environment lookup. Route them through shared resolution. Preserve exported signatures and literal URLs. |
| Direct readers | Diagnostics in `R/zzz.R` and routing, connection, and HTTP paths in `R/eco_functions.R` and `R/tox_functions.R` read environment variables directly. Update all readers before stopping startup initialization. |
| Stage hook | `R/hooks_stage_server.R` builds its stage map by calling `chemi_server(2/3, url_only = TRUE)`. Generated configuration from `dev/stub_specs.R` invokes it. Remove public stage enforcement and fallback metadata before removing numeric modes, or retained wrappers will fail before requests. |
| Dashboard calls | `R/ct_similar.R` and `R/ct_related.R` use distinct literal production bases. Preserve their service-specific paths. |
| Public wrappers | The audit found 31 `_staging`/`_development` exports: three staging and 28 development wrappers, with matching source and help files. They use `chemi_burl`; absence of embedded hosts does not make these production operations. |
| Payload fields | Two AMOS wrappers have a `base_url` API payload field. Do not mistake it for transport configuration. |
| Other selectors | `np_server()` and `pubchem_server()` also participate in endpoint configuration. Include them in shared-default and diagnostic checks. |

Eight CT snapshots were identified in `schema/`: the bioactivity, chemical,
exposure, and hazard schemas, each with `-staging.json` and `-dev.json` variants.
Move any needed local inputs outside the public checkout before removing those
non-production snapshots. Inspect generation configuration and build-ignored
scripts for other embedded non-production addresses. `dev/` and `schema/` are
build-ignored, but that does not satisfy the public-checkout policy.

The original scan found no matching non-production address in `inst/`, `data/`,
vignettes, README, `_pkgdown.yml`, GitHub Actions, cassettes, or snapshots outside
the identified schemas. Treat this as historical evidence; inspect final output
again. Existing planning prose includes host references in
`.planning/codebase/ARCHITECTURE.md` and
`.planning/research/ISSUE_169_CHEMINFORMATICS_API_DOCUMENTATION.md`. Remove actual
non-production addresses from current public files without deleting useful
technical history. Do not copy those addresses into this plan.

## Configuration and interface contract

Use one small internal lookup shared by transport and direct readers. For standard
service keys, use the package option, then the existing lowercase environment
variable, then the approved default. Preserve these environment names:
`ctx_burl`, `chemi_burl`, `epi_burl`, `eco_burl`, `toxval_burl`, `np_burl`, and
`pubchem_burl`. Use corresponding `ComptoxR.<key>` options, for example
`ComptoxR.ctx_burl`. Do not introduce uppercase replacement environment variables.

An unset option and an unset or empty environment variable use the next source.
A supplied invalid option must fail clearly rather than silently select a
different service. Validate URL values as one non-empty HTTP(S) string before
request construction. Explicit literal `server` URLs bypass standard-key lookup;
preserve existing custom environment-key support. Do not expose credentials in
diagnostic output.

Keep database-path resolution separate from URL validation. ECOTOX and ToxVal
default to their existing local database path helpers; existing path options
remain valid. Route explicit URLs as HTTP requests and paths as database access.
Do not restrict explicit URL overrides to a built-in host list. Close stale
database connections when the effective database target changes, including a
change made through options or environment variables. A `url_only = TRUE` lookup
must not mutate configuration or close connections.

Keep existing approved production and local numeric choices. Removed numeric
development choices must give a clear configuration error with option/environment
guidance. Selector setters continue to set their existing environment variables;
document that a package option takes precedence. Resetting a selector clears its
environment setting and returns to effective option/default resolution.

The ECOTOX server is shipped at `inst/plumber/ecotox/plumber.R`. It wraps package
functions over a local database and requires the matching ComptoxR version.
Update the package and server together and require a restart after upgrade.
There is no external server discovery or old-server compatibility layer. Keep
source code and description in ECOTOX HTTP results, as in local results.

## Implementation sequence

1. Record current commits, export inventory, and test baseline. Read production
   schemas from authoritative approved inputs and compare operation membership,
   methods, and paths. Preserve user changes and use a branch from `integration`.
2. After toolkit parity, configure public generation with only approved production
   schemas and shipped Plumber routes. Local development acquisition and generation
   must use explicit external input/output roots and explicit URL configuration.
3. Add shared resolution and change all generic and direct readers together.
   Remove startup endpoint mutation only after those paths use effective defaults.
4. Remove embedded non-production constants and selector choices. Preserve local
   database and Plumber behavior, EPI, and distinct production service paths.
5. Compare every stage-named export with production. Remove old stage exports and
   their owned generated tests/help; generate production replacements where valid.
   Preserve manually owned code and tests. Do not remove files by suffix alone.
   Stop emitting public `enforce_stage_server` configuration and its stage/fallback
   metadata. Remove obsolete public call sites and the hook once no callers remain.
   Keep the general hook runner and domain hooks. Local development clients use
   their explicit configured URL without automatic host fallback; do not retain
   calls to removed numeric modes in their adapter.
6. Remove current-tree non-production inputs and addresses after their local
   replacements work. Use reserved example hosts in mocked configuration tests.
7. Update roxygen and configuration guidance, regenerate help, and review generated
   changes. Record breaking modes, removed names, replacements, configuration
   precedence, and server restart instructions for release notes. Follow the
   existing release workflow; do not hand-edit `DESCRIPTION` version or create tags.
8. Run the checks below, then integrate through the coordinator. Add explicit build
   exclusions for internal root planning documents as part of documentation work.

## Validation and release gates

Use deterministic mocks; routine tests must not contact development services or
re-record cassettes. Named-host test locations from the audit are
`tests/testthat/setup.R`, `test-exported_utility_contracts.R`,
`test-chemi_descriptor_contracts.R`, `test-chemi_descriptor_smiles_hooks.R`,
`test-probe_api_function.R`, and `test-tox_functions.R` under `tests/testthat/`.
Also check `test-hooks_stage_server.R` for assumptions about removed selectors.
Keep valid EPI and localhost expectations; replace only non-production constants.

Required cases:

- Each standard service: option/environment/default precedence, missing values,
  invalid values, explicit literal URLs, and existing custom environment keys.
- Clean source and dated builds: identical approved defaults, no endpoint
  environment mutation, and usable diagnostics without pre-set variables.
- ECOTOX/ToxVal: default and custom database paths, localhost calls, configured
  URL overrides, connection switches, reset behavior, and side-effect-free lookup.
- Local ECOTOX and matching localhost server: the same source-only lifestage
  fields. No request or public argument named `lifestage_details` remains.
- Production regeneration: no unsupported operation export, manual files
  preserved, and an identical second run makes no changes.
- Retained hook-enabled wrappers: production and explicit URL requests succeed
  without calling removed numeric selectors or switching to another host. No
  generated public configuration references the removed stage hook.
- Public package and site: no known non-production addresses or development-only
  operations. Scan the expanded source tarball and rendered pkgdown site, including
  source links and help. Inspect broad matches such as staging/dev labels, `.dev`,
  and localhost as review candidates; do not reject approved EPI or local Plumber.

Run focused tests first from a sourceable R validation script:

```r
devtools::test(filter = 'generic_request|generic_chemi_request|exported_utility_contracts|package_sitrep|chemi_descriptor|probe_api_function|hooks_stage_server|eco_connection|tox_connection|eco_functions|tox_functions')
```

Then run `devtools::test()` and `Rscript dev/cran_readiness.R` because startup and
shared transport affect the package broadly. Run documentation generation only
when roxygen changes. Record failures, skips, unavailable dependencies, and artifact
scan results. If fixtures change for a justified reason, run existing cassette
safety checks and verify redaction before commit.

The coordinator owns final integration and release. Existing user configurations
can intentionally override production; show effective settings in diagnostics.
This migration does not rewrite git history, tags, or historical source releases.
Withdrawal of derived ECOTOX database downloads is governed separately by the
lifestage plan and must not remove unrelated assets.
