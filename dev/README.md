# dev/

Maintainer scripts and the configuration they read. Run from the package root.
`dev/` is excluded from the built package (`.Rbuildignore`).

## Specmill generation

- `install_specmill.R` + `specmill-lock.json`: install and verify the pinned Specmill toolkit (`verify_specmill()`); the library lives in the ignored `specmill-pilot/artifacts/`.
- `generate_specmill.R`: plan, apply or check wrappers generated from `specmill.yml` and `apis/*.yml`.
- `specmill_callbacks.R`, `specmill_pubchem_callbacks.R`: generation callbacks listed in `specmill.yml`.
- `specmill-333/`: `SELECTION.md` (the `apis/` layout, keep-or-convert record, unresolved contracts and what is still outside Specmill) and `verify.R` (opt-out discovery check, CI).
- `specmill-342/`: `verify.R`, `emit.R`, `adoption.json` (native helper adoption check, CI).
- `check_specmill_fixes.R`: acceptance checks for specmill#100-#102 after re-pinning.
- `freeze_production_schemas.R`: download approved production schemas into `.migration-evidence/production`.
- `generate_local_client.R`, `verify_local_client.R`, `LOCAL_CLIENTS.md`: generate and verify a local, non-public client package.

## Tests

- `TESTING_GUIDE.md`: test lanes and the wrapper test rubric.
- `generate_tests.R` + `test_generation/`: generate and check offline wrapper contract tests.
- `detect_test_gaps.R`: report wrappers without tests (schema-check workflow).
- `unit_test_readiness_audit.R`, `reports/unit_test_readiness_audit.json`, `export_test_exclusions.json`, `vcr_test_classification.json`: test inventory audit and its inputs.
- `record_cassettes.R`, `rerecord_cassettes.R`: record VCR cassettes live (needs `ctx_api_key`).
- `check_cassette_health.R`: validate committed cassettes.
- `cran_readiness.R`: CRAN-safe test and audit run.

## Checks, build and release

- `check_hook_config.R`: validate `inst/hook_config.yml`.
- `check_public_api.R`: guard that public code and docs only use production APIs.
- `probe_api_compatibility.R`: live API compatibility probe (workflow).
- `coverage.yml` + `update_coverage.R`: schema coverage badges (`--apply` to write).
- `db_smoke_check.R`: smoke-test built DSSTox/ECOTOX/ToxVal databases (workflows).
- `build.R`: local pre-release steps (document, find missing globals).
- `build_testing_chemicals.R`: refresh `data/testing_chemicals.rda`.
- `normalize_news.R`: normalise `NEWS.md` during release.
- `checkpoint.R`, `load_packages.R`: personal session bootstrap (schema hash checkpoint, package loader).
