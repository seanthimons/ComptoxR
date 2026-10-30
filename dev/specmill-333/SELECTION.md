# Specmill service selection (#333)

Each schema has one file, `apis/<schema>.yml`. Its group key is the Specmill service id
(`chemi_amos`, `ctx_hazard`, ...), and each wrapper is written to its own file, `R/<name>.R`.
Endpoint policy (the GET/POST method list and the banned routes) lives only in `specmill.yml`
`selection`. A group with no `selection` block takes every schema operation that the policy
allows.

## Naming

Names come from the path (`naming: path`), in snake_case with a `ct_`, `chemi_` or `epi_`
prefix. Parameters are not added to names. A POST that shares a path with a GET gets a
`_bulk` suffix. The `names:` block in each file lists every route and its wrapper name. An
entry marked `# why` departs from that default:

- **Path collisions.** Two routes that would get the same path name are told apart by their
  path parameter (`..._by_<param>`).
- **`chemi_classyfire`.** This is a second wrapper for
  `GET /api/amos/get_classification_for_dtxsid/{dtxsid}`. It is the released ClassyFire
  lookup and formats its result with `format_classyfire_result`.

NEWS.md has the full old-to-new name table.

## Operation settings

Every entry under `operations:` keeps a released wrapper's behaviour: server resolver,
response policy, input forms, batching, docs, request arguments and so on. Each entry has a
`# why:` line saying what it keeps. Entries whose wrapper has hooks or extra arguments also
read `inst/hook_config.yml`, which is keyed by wrapper name. Fixed request contracts for
generated tests are stored in `tests/testthat/fixtures/specmill-contracts.rds`. An entry is
keyed by route, or by wrapper name when more than one wrapper shares a route.

## Groups and selections that are not the default

| File | Group | Setting | Why |
| --- | --- | --- | --- |
| `apis/chemi_descriptors.yml` | `chemi_descriptors` | Also loads `chemi_rdkit_prod.json`; `selection.exclude: ^/api/rdkit`; group `defaults.server` | The aggregate descriptor wrappers fall back to RDKit routes. The schema has to be loaded for those routes to resolve, but the RDKit operations themselves belong to `apis/chemi_rdkit.yml`. Routed siblings take their server from group defaults. |
| `apis/chemi_amos.yml` | `chemi_classyfire` | `selection.include` of the one ClassyFire route | This is a second wrapper for a route that `chemi_amos` already owns (see Naming). |
| `apis/pubchem.yml` | `pubchem` | `selection.include` of three operations | The schema is the first-party reviewed overlay `schema/pubchem-reviewed.json`. Only the three reviewed operations are wrapped. Selecting every operation would also pick up three unreviewed POST routes. |

## Deferrals

Specmill's manifest defers ten operations until their production schemas are fixed. The
reasons are recorded in `.specmill/manifest.json`:

- `chemi_amos`: six POST routes
- `chemi_chet`: `GET /chemicals/chemical_DL`
- `chemi_resolver`: `POST /api/resolver/getsimilaritylist`
- `chemi_services`: `preflight` and `universalpreflight`

## Unresolved schema contracts (#328)

Gaps between the production schemas and what Specmill can generate:

- **Deferred operations.** The ten operations above stay deferred, and each one retries automatically when its schema fingerprint changes. Resolver `getsimilaritylist` is also tracked upstream as specmill#165. The `preflight` routes need multipart upload support (specmill#28).
- **No production schema.** `ct_related()` and `ct_similar()` call legacy dashboard routes that no production schema describes. They are hand-written and call `.ct_request()` directly. PubChem has no production schema, so it is generated from the first-party overlay `schema/pubchem-reviewed.json`.
- **Relative or missing schema servers.** Many chemi and EPI schemas give either a relative server URL or a Swagger `host` without a usable origin. Specmill reports this as "requires a recorded origin or explicit base URL override". This is not a defect: generated wrappers resolve the base URL at runtime from the `chemi_burl`/`epi_burl` settings, which `chemi_server()` and `epi_server()` set.

## What is still outside Specmill (#328)

- **Hand-written code.** Client utilities (`ct_api_key`, `chemi_server`, `epi_server`), the runtime hooks (`R/hooks_*.R`, `inst/hook_config.yml`), response and input policies, and `ct_related`/`ct_similar`. Specmill records the hashes of hooks and callbacks in `.specmill/manifest.json`, so edit them and then run `dev/generate_specmill.R --apply`.
- **`dev/generate_tests.R`.** This is the last legacy generator. It writes offline contract tests only for exported wrappers whose tests Specmill doesn't generate. Today it generates `test-chemi_services_convert.R` and `test-chemi_services_collated_report.R` from `test_args:` in `inst/hook_config.yml`, and skips two wrappers that have manual tests. CI runs its `--check`. `stub_specs.R`, `chemi_endpoint_eval.R` and `generic_request()` are gone.
