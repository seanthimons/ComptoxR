# Codebase Structure

**Analysis Date:** 2026-02-12

## Directory Layout

```
ComptoxR/
├── R/                         # Source code (371 files)
│   ├── z_generic_request.R    # Core request templates
│   ├── zzz.R                  # Package initialization and config
│   ├── ct_*.R                 # CompTox Dashboard API wrappers (~90 files)
│   ├── chemi_*.R              # Cheminformatics API wrappers (~120 files)
│   ├── cc_*.R                 # Common Chemistry API wrappers (4 files)
│   ├── epi_*.R                # EPI Suite API wrappers (1 file)
│   ├── eco_*.R                # ECOTOX API wrappers (not present yet)
│   ├── chemi_resolver_*.R     # Identifier resolution functions (~25 files)
│   ├── util_*.R               # Utility functions (4 files)
│   ├── extract_*.R            # Data extraction factories (2 files)
│   ├── data.R                 # Dataset documentation
│   ├── mappings.R             # Property ID mappings
│   ├── schema.R               # API schema functions
│   ├── misc_functions.R       # Miscellaneous helpers
│   ├── package_sitrep.R       # Package status reporting
│   └── utils-pipe.R           # magrittr pipe re-export
│
├── tests/testthat/            # Test suite
│   ├── helper-vcr.R           # VCR cassette configuration
│   ├── helper-api.R           # API test helpers
│   ├── helper-pipeline.R      # Pipeline/integration test helpers
│   ├── setup.R                # Global test setup
│   ├── test-*.R               # Individual test files (~90 files)
│   ├── fixtures/              # VCR cassettes (YAML files with recorded responses)
│   └── _snaps/                # Snapshot test data
│
├── data/                      # Package datasets (binary .rda files)
│   ├── testing_chemicals.rda
│   ├── pt.rda                 # Periodic table
│   ├── property_ids.rda       # CompTox property IDs
│   ├── toxprint_dict.rda      # ToxPrint chemotypes
│   ├── toxprint_ID_key.rda
│   ├── std_spec.rda           # Standard test species
│   ├── inv_spec.rda           # Invasive species
│   ├── threat_spec.rda        # Threatened species
│   ├── toxvaldb_sourcedict.rda # ToxValDB source rankings
│   ├── genra_engine.rda       # GenRA function endpoints
│   ├── cust_pal.rda           # Custom color palettes
│   ├── cheminformatics_hazard_pal.rda
│   └── reach.rda              # REACH data reference
│
├── schema/                    # API schema references
│   └── *.json                 # Downloaded API schemas (reference only)
│
├── man/                       # Generated documentation (roxygen)
│   └── *.Rd                   # Help files (auto-generated from R comments)
│
├── .github/workflows/         # CI/CD workflows
│   └── *.yml                  # GitHub Actions
│
├── .planning/                 # Planning documents
│   ├── codebase/              # Architecture/structure docs
│   ├── milestones/            # Project milestones
│   ├── phases/                # Implementation phases
│   └── todos/                 # Task tracking
│
├── DESCRIPTION                # Package metadata
├── NAMESPACE                  # Exported functions and imports
├── README.md                  # User documentation
├── NEWS.md                    # Changelog
└── codecov.yml                # Code coverage configuration
```

## Directory Purposes

**R/ - Source Code:**
- Purpose: All user-facing and internal functions
- Contains: API wrappers, request templates, utilities, data transformations
- Key files: `z_generic_request.R` (templates), `zzz.R` (init), individual wrapper files

**tests/testthat/ - Test Suite:**
- Purpose: Comprehensive test coverage for all API wrappers
- Contains: Unit tests, integration tests, E2E tests with VCR cassettes
- Key files: `setup.R` (global config), `helper-*.R` (utilities), `fixtures/` (recorded responses)

**data/ - Package Data:**
- Purpose: Bundle reference data used by package functions
- Contains: Pre-computed lookup tables, periodic table, species lists, property mappings
- Key files: All `.rda` files, loaded on package attachment

**schema/ - API Documentation:**
- Purpose: Reference copies of API schemas for development
- Contains: Downloaded JSON schemas from CompTox and Cheminformatics APIs
- Key files: Auto-generated, not typically edited manually

**man/ - Help Documentation:**
- Purpose: Generated R help files for all exported functions
- Contains: `.Rd` files auto-generated from roxygen2 comments in R code
- Key files: Auto-generated via `devtools::document()`

**.github/workflows/ - CI/CD:**
- Purpose: Automated build, test, and release workflows
- Contains: GitHub Actions YAML files
- Key files: Release workflows, test triggers

**.planning/ - Project Planning:**
- Purpose: Track development progress, phases, milestones, and codebase analysis
- Contains: Architecture docs (ARCHITECTURE.md, STRUCTURE.md), phase tracking, milestone records
- Key files: `.planning/codebase/` contains GSD documentation

## Key File Locations

**Entry Points:**
- `R/zzz.R` (lines 528-602): `.onAttach()` and `.onLoad()` package initialization
- `R/z_generic_request.R`: `generic_request()` and `generic_chemi_request()` templates (ALL requests flow through here)
- No `R/main.R` or explicit entry point - functions are called directly by users

**Configuration:**
- `R/zzz.R` (lines 213-407): Server configuration functions (`ctx_server()`, `chemi_server()`, etc.)
- `R/zzz.R` (lines 408-507): Debug/verbose mode configuration
- `tests/testthat/setup.R`: Test environment configuration (API keys, server URLs)

**Core Logic:**
- `R/z_generic_request.R` (lines 43-300): `generic_request()` - Primary request template for CompTox/EPI/ECOTOX
- `R/z_generic_request.R` (lines 404-545): `generic_chemi_request()` - Cheminformatics-specific template
- `R/z_generic_request.R` (lines 547+): `generic_cc_request()` - Common Chemistry template

**Utilities:**
- `R/util_cas.R`: CASRN validation logic
- `R/util_classyfire.R`: ClassyFire classification helpers
- `R/extract_mol_formula.R`: Molecular formula extraction factory
- `R/chemi_resolver_lookup.R`: Chemical identifier resolution (starting point for resolvers)

**Testing:**
- `tests/testthat/helper-vcr.R`: VCR cassette configuration (sanitizes API keys)
- `tests/testthat/helper-api.R`: API-specific test utilities
- `tests/testthat/helper-pipeline.R`: E2E pipeline test helpers
- `tests/testthat/fixtures/`: Recorded HTTP responses as YAML files (one cassette per test function)

**Package Metadata:**
- `DESCRIPTION`: Version (1.4.0), dependencies, authors
- `NAMESPACE`: Exported functions (via @export in roxygen comments)
- `R/data.R`: Documentation for bundled datasets

## Naming Conventions

**Files:**
- Wrapper files: `{api}_{domain}.R` (e.g., `ct_hazard.R`, `chemi_toxprint.R`, `cc_search.R`)
- Utility files: `util_{feature}.R` (e.g., `util_cas.R`)
- Resolver files: `chemi_resolver_{function}.R` (e.g., `chemi_resolver_lookup.R`)
- Extract files: `extract_{data}.R` (e.g., `extract_mol_formula.R`)
- Initialization file: `zzz.R` (forces package-level functions to load last)
- Generic file: `z_generic_request.R` (underscore prefix, loads before specific wrappers)

**Directories:**
- API wrapper groups: `R/` contains all functions (no subdirectories)
- Test groups: `tests/testthat/` flat structure with `test-{function}.R` pattern
- Data: `data/` contains only binary `.rda` files
- Workflows: `.github/workflows/` follows GitHub convention

## Where to Add New Code

**New CompTox Dashboard API Wrapper:**
- Primary code: `R/ct_{endpoint_name}.R`
- Tests: `tests/testthat/test-ct_{endpoint_name}.R`
- Pattern: Call `generic_request()` with appropriate endpoint, method, batch_limit
- Example: `R/ct_hazard.R` (9 lines) - wrapper functions are typically very short

**New Cheminformatics API Wrapper:**
- Primary code: `R/chemi_{endpoint_name}.R`
- Tests: `tests/testthat/test-chemi_{endpoint_name}.R`
- Pattern: Call `generic_chemi_request()` with endpoint, options, and sid_label parameters
- Example: `R/chemi_hazard.R` (33 lines)

**New Resolver Function:**
- Primary code: `R/chemi_resolver_{function_name}.R`
- Tests: `tests/testthat/test-chemi_resolver_{function_name}.R`
- Pattern: Typically call `generic_request()` with Cheminformatics server URL
- Example: `R/chemi_resolver_lookup.R` (37 lines)

**Utilities:**
- Shared helpers: `R/util_{feature}.R`
- Place near related functions if closely tied to one API
- Add roxygen comments and @export if user-facing
- Keep internal helpers in same file as primary function if only used there

**Data/Reference Files:**
- New package datasets: Save as binary `.rda` in `data/` directory
- Documentation: Add entry to `R/data.R` with roxygen comments describing the dataset
- Generation scripts: Place in `data-raw/` (if it exists) for reproducibility

## Special Directories

**tests/testthat/fixtures/:**
- Purpose: Store recorded HTTP responses (VCR cassettes) as YAML files
- Generated: Automatically on first test run (requires valid API key)
- Committed: Yes - committed to git after sanitization (API keys replaced with `<<<API_KEY>>>`)
- Pattern: One cassette file per test function (e.g., `test-ct_hazard.yml`)
- Note: Delete cassettes and re-run to force fresh recording from production APIs

**data-raw/:**
- Purpose: Scripts to generate/update package data from source
- Generated: Not in repo (exists in development only)
- Committed: No
- Pattern: R scripts that create `.rda` files via `usethis::use_data()`

**schema/:**
- Purpose: Reference copies of API schemas for development
- Generated: Via `ct_schema()` function to download latest schemas
- Committed: Not typically (reference only, can be regenerated)
- Pattern: Downloaded JSON files named after endpoints

**.planning/codebase/**
- Purpose: Architecture and coding convention documentation
- Generated: Via `/gsd:map-codebase` GSD command
- Committed: Yes
- Contains: ARCHITECTURE.md, STRUCTURE.md, CONVENTIONS.md, TESTING.md, STACK.md, INTEGRATIONS.md, CONCERNS.md

## R File Organization Principles

1. **No Subdirectories:** All R source files in single `R/` directory (R package convention)
2. **Alphabetical**: Files listed alphabetically, but loaded in order determined by dependencies (roxygen handles exports)
3. **One Function per File (mostly):** Each wrapper file typically contains one exported function and zero or more internal helpers
4. **Generic Functions First:** `z_generic_request.R` loaded before specific wrappers (naming forces this)
5. **Package Init Last:** `zzz.R` loaded last (naming convention)

## Import/Export Flow

**External Imports (in DESCRIPTION):**
- `httr2` - HTTP requests
- `dplyr`, `tidyr` - Data manipulation
- `purrr` - Functional programming
- `stringr`, `stringi` - String operations
- `cli` - User messaging
- `rlang` - Expression handling
- `jsonlite` - JSON parsing
- `magrittr` - Pipe operator

**Exports (in NAMESPACE, via @export):**
- All `ct_*()` functions (CompTox Dashboard wrappers)
- All `chemi_*()` functions (Cheminformatics wrappers)
- All `cc_*()` functions (Common Chemistry wrappers)
- All `epi_*()` functions (EPI Suite wrappers)
- All `chemi_resolver_*()` functions (Identifier resolvers)
- All `util_*()` functions (Utilities marked @export)
- Server configuration functions: `ctx_server()`, `chemi_server()`, `epi_server()`, `eco_server()`, `cc_server()`
- Debug functions: `run_debug()`, `run_verbose()`, `batch_limit()`
- Setup function: `run_setup()`

**Internal Functions (not exported):**
- `generic_request()` - Actually exported (@export directive) for advanced use
- `generic_chemi_request()` - Actually exported (@export directive)
- Helper functions with names like `ct_api_key()`, `clean_unicode()`, etc.
- Factory functions like `create_formula_extractor_final()`, `create_compound_classifier()`

---

*Structure analysis: 2026-02-12*
