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
