# Feature Research

**Domain:** Source-backed ontology resolution pipeline for R package (ComptoxR v2.4)
**Researched:** 2026-04-22
**Confidence:** HIGH (APIs verified via live calls; R patterns verified against official docs)

---

## API Behavior Reference

This section documents verified API behavior for OLS4 and NERC NVS, grounding all feature
decisions in actual response schemas.

### OLS4 Search API

**Base URL:** `https://www.ebi.ac.uk/ols4/api/search`
**Confidence:** HIGH — verified via live API calls during research.

**Search parameters (query string):**

| Parameter | Type | Description |
|-----------|------|-------------|
| `q` | string | Search term (required) |
| `ontology` | string | Comma-separated ontology IDs, e.g. `uberon` or `po` |
| `rows` | integer | Result count, default 10 |
| `start` | integer | Pagination offset |
| `exact` | string | `"on"` for exact label match |
| `type` | string | `"class"`, `"property"`, `"individual"`, or `"ontology"` |
| `queryFields` | string | Comma-separated: `label,synonym,description,short_form,obo_id,annotations,logical_description,iri` |
| `fieldList` | string | Comma-separated fields to return |
| `isDefiningOntology` | boolean | Filter to terms natively defined in the specified ontology |

**Response envelope (Solr-style JSON):**

```json
{
  "responseHeader": { "status": 0, "QTime": 2 },
  "response": {
    "numFound": 67,
    "start": 0,
    "docs": [ ... ]
  },
  "facet_counts": {
    "facet_fields": {
      "isDefiningOntology": ["true", 388, "false", 90],
      "isObsolete": ["false", 478, "true", 0],
      "ontologyId": [...],
      "type": [...]
    }
  }
}
```

**Per-document fields in `response.docs[]`:**

| Field | Type | Notes |
|-------|------|-------|
| `iri` | string | Full OBO IRI, e.g. `http://purl.obolibrary.org/obo/UBERON_0000069` |
| `obo_id` | string | Compact ID, e.g. `UBERON:0000069` — **use as `source_term_id`** |
| `short_form` | string | Underscore form, e.g. `UBERON_0000069` |
| `label` | string | Human-readable label — **use as `source_term_label`** |
| `description` | array of strings | Definitions — take `[0]` as `source_term_definition` |
| `ontology_name` | string | Lowercase, e.g. `"uberon"` |
| `ontology_prefix` | string | Uppercase, e.g. `"UBERON"` |
| `type` | string | Usually `"class"` |
| `exact_synonyms` | array of strings | Optional; use as alias surface for scoring |
| `narrow_synonyms` | array of strings | Optional |
| `broad_synonyms` | array of strings | Optional |
| `related_synonyms` | array of strings | Optional |

**Important caveats:**
- `isDefiningOntology` and `isObsolete` appear only in `facet_counts`, not in individual docs.
  Filter obsolete terms by checking `facet_counts.facet_fields.isObsolete` or rely on the
  known issue that `isObsolete: false` items dominate UBERON/PO results (verified: 0 obsolete
  in 478-result UBERON adult stage search).
- OLS4 uses Solr/Lucene relevance scoring — exact label matches are NOT guaranteed to rank
  first. A known bug causes specific subclasses to rank above the parent exact-match term.
  Custom scoring over the returned candidates is required (as implemented in
  `.eco_lifestage_score_text()`).
- The `/api/select` endpoint is tuned for autocomplete; `/api/search` is the correct choice
  for batch resolution.

**Verified UBERON lifestage `obo_id` mappings:**

| UBERON term | obo_id | label |
|------------|--------|-------|
| Larval stage | `UBERON:0000069` | larval stage |
| Juvenile stage | `UBERON:0034919` | juvenile stage |
| Sexually immature stage | `UBERON:0000112` | sexually immature stage |
| Post-juvenile adult stage | `UBERON:0000113` | post-juvenile adult stage |
| Fully formed stage | `UBERON:0000066` | fully formed stage |
| Amphibian larval stage | `UBERON:0004728` | amphibian larval stage |

### NERC NVS BODC S11 API

**Collection URL:** `https://vocab.nerc.ac.uk/collection/S11/current/`
**SPARQL endpoint:** `https://vocab.nerc.ac.uk/sparql/sparql`
**Confidence:** HIGH — verified via live collection fetch and JSON-LD term inspection.

**Preferred programmatic access: SPARQL (implemented)**

The REST collection endpoint returns all ~130 S11 terms as JSON-LD when queried with
`Accept: application/ld+json`. However, the SPARQL endpoint provides structured, filterable
access and is what the implementation (`.eco_lifestage_nvs_index()`) correctly uses.

**SPARQL query pattern (as implemented):**

```sparql
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
SELECT ?term ?label ?altLabel ?definition WHERE {
  ?term a skos:Concept ; skos:prefLabel ?label .
  OPTIONAL { ?term skos:altLabel ?altLabel }
  OPTIONAL { ?term skos:definition ?definition }
  FILTER(REGEX(STR(?term), '^http://vocab.nerc.ac.uk/collection/S11/current/S[0-9]+/$'))
}
```

SPARQL response format: `application/sparql-results+json` — returns `results.bindings[]`
where each binding has fields with `{ "value": "..." }` structure.

**Per-term fields from JSON-LD (verified via `S1130` nauplius):**

| SKOS field | JSON-LD key | Maps to |
|------------|-------------|---------|
| Term URI | `@id` | Parsed for `source_term_id` (e.g. `S1130`) |
| Notation | `skos:notation` | e.g. `SDN:S11::S1130` |
| Preferred label | `skos:prefLabel` | `source_term_label` |
| Alternative label | `skos:altLabel` | alias surface for scoring |
| Definition | `skos:definition` | `source_term_definition` |
| Status | `skos:note` | `"accepted"` or `"deprecated"` |
| Deprecated | `owl:deprecated` | filter out deprecated terms |
| OWL sameAs | `owl:sameAs` | cross-reference to UBERON (e.g. `UBERON_0014406` for nauplius) |
| isReplacedBy | `dc:isReplacedBy` | redirect deprecated term |

**S11 vocabulary scope:** ~130 terms covering aquatic and marine organism development stages.
Includes nauplii (N1-N6 sub-stages), copepodite stages (C1-C5), megalopa, zoea, pluteus,
auricularia, doliolaria, cercaria, fish larvae (preflexion, flexion, postflexion), embryo,
juvenile, adult, immature, pup, smolt.

**Important caveat:** S11 is specialized for marine biology. Terrestrial insect, amphibian,
and plant development stages are not well covered — UBERON and PO fill those gaps.
The `owl:sameAs` field links S11 terms to UBERON IRIs, confirming semantic alignment.

### In-Place DuckDB Table Replacement Pattern

**Pattern (verified, DuckDB-recommended):**

```r
# DBI::dbWriteTable with overwrite = TRUE replaces the table in-place
DBI::dbWriteTable(con, "lifestage_dictionary", materialized$dictionary, overwrite = TRUE)

# Or via SQL (DuckDB "friendly SQL" pattern):
DBI::dbExecute(con, "CREATE OR REPLACE TABLE lifestage_dictionary AS SELECT ...")
```

`CREATE OR REPLACE TABLE` is DuckDB's preferred idiomatic form over
`DROP TABLE IF EXISTS` + `CREATE TABLE`. `DBI::dbWriteTable(..., overwrite = TRUE)` is the
R-level equivalent.

**Connection hygiene requirement:** DuckDB allows only one read-write connection at a time.
The `.eco_close_con()` call before opening read-write is required to avoid "Database already
in use" errors. Calling it again on exit ensures the cached read-only handle is refreshed.

### Release-Scoped Cache Pattern (R Packages)

**Pattern (verified against CRAN best practices):**

```r
# CRAN-compliant persistent cache location
cache_dir <- tools::R_user_dir("ComptoxR", "cache")
cache_path <- file.path(cache_dir, paste0("ecotox_lifestage_", safe_release, ".csv"))
```

`tools::R_user_dir()` is the modern (R >= 4.0) CRAN-preferred alternative to `rappdirs`.
Encoding the ECOTOX release identifier in the filename provides automatic cache invalidation
when the database release changes. CSV format (not RDS) ensures the cache is readable without
R and can be inspected/edited manually.

**Test compliance:** During `R CMD check`, redirect the cache to `tempdir()` to prevent
writing to the user's real cache directory.

### Baseline CSV Pattern (R Packages)

**Pattern (verified against R Packages book and real-world packages):**

```r
# At install time: inst/extdata/ecotox/lifestage_baseline.csv ships with package
# At runtime: system.file() resolves the installed path
system.file("extdata", "ecotox", "lifestage_baseline.csv",
            package = "ComptoxR", mustWork = FALSE)
```

Files in `inst/extdata/` are installed to the top-level package directory and accessed via
`system.file()`. This is the canonical pattern used by `palmerpenguins`, `gapminder`, and
data packages throughout the tidyverse ecosystem.

---

## Feature Landscape

### Table Stakes (Users/Maintainers Expect These)

Features that the v2.4 milestone cannot ship without. Missing any of these = the replacement
is not a real improvement over v2.3.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Source-backed `source_term_id`, `source_term_label`, `source_ontology` columns in `lifestage_dictionary` | Replacement of cosmetic v2.3 `ontology_id` with actual provider-issued identifiers | MEDIUM | Requires OLS4 + NVS lookups; already implemented in `eco_lifestage_patch.R` |
| `eco_results()` returns new lifestage columns without `ontology_id` | API contract change; v2.3 `ontology_id` was fake provenance | LOW | Join change in `R/eco_functions.R` |
| `lifestage_dictionary` contains only source-backed rows | No regex-derived entries in canonical table | LOW | Enforced by derivation map gate in `.eco_lifestage_materialize_tables()` |
| `lifestage_review` quarantine for ambiguous and unresolved terms | Downstream users need to know what didn't resolve | LOW | Already schema-defined; populated by materialization logic |
| Hard-blocking build gate for unmapped terms | Pipeline must not silently drop lifestage data | LOW | Preserve existing gate behavior; gate checks `lifestage_dictionary` completeness |
| `lifestage_baseline.csv` committed to `inst/extdata/ecotox/` | Cold-start capability; CI does not need live API access | MEDIUM | CSV must cover all distinct `lifestage_codes.description` for one ECOTOX release |
| `lifestage_derivation.csv` committed to `inst/extdata/ecotox/` | Maps `source_ontology + source_term_id` to `harmonized_life_stage`, `reproductive_stage`, `derivation_source` | MEDIUM | Curated manually; drives derived field population |
| Release-scoped user cache at `tools::R_user_dir("ComptoxR", "cache")` | Prevents live API calls on every build; CRAN-compliant location | LOW | Filename encodes ECOTOX release; automatically invalidated on release change |
| Shared helper layer in `R/eco_lifestage_patch.R` | Both build script and patch path must use identical resolver logic | LOW | Already implemented; build script section 16 must call these helpers |
| Section 16 identical in `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R` | Build correctness; divergence creates subtle bugs | LOW | Copy must remain verbatim; validate in CI if possible |
| 13-column `lifestage_dictionary` schema stable | Downstream joins in `eco_results()` depend on exact column names | LOW | Schema locked in `.eco_lifestage_dictionary_schema()` |
| `_metadata` patched with `lifestage_patch_*` keys after patch | Auditable provenance of when and how lifestage tables were built | LOW | 4 keys: `applied_at`, `release`, `method`, `version` |

### Differentiators (What Makes v2.4 Better than v2.3)

Features that distinguish source-backed resolution from the regex-first v2.3 approach.
Not all are strictly required for correctness, but they provide meaningful value.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `.eco_patch_lifestage()` internal patch function | Existing DB can be updated without full ECOTOX rebuild (hours saved) | MEDIUM | Internal dot-function only; signature and behavior documented in PLAN2.md |
| Four refresh modes (`auto`, `cache`, `baseline`, `live`) | Researchers can choose speed vs. freshness explicitly; CI uses `"baseline"` for reproducibility, live dev uses `"live"` | MEDIUM | Implemented in `.eco_lifestage_load_seed_cache()`; modes cascade correctly |
| Three-provider resolution (UBERON + PO + NVS S11) | Coverage across animal development (UBERON), plant development (PO), and marine biology (S11) | MEDIUM | OLS4 handles UBERON and PO; SPARQL handles S11; providers combined before scoring |
| Score-based candidate ranking (100/90/75 tiers) | Explicit, testable scoring logic — no magic regex; reviewers can audit why a term resolved | LOW | Implemented in `.eco_lifestage_score_text()` and `.eco_lifestage_rank_candidates()` |
| `source_match_status` field (`resolved`/`ambiguous`/`unresolved`) | Users can filter `lifestage_dictionary` by confidence level | LOW | Status is schema-encoded; drives quarantine vs. dictionary split |
| `source_match_method` field | Full audit trail: was this from OLS4 search, NVS SPARQL, or cache? | LOW | Carried through all stages |
| `candidate_rank` and `candidate_score` in cache schema | Enables post-hoc analysis of why ambiguous terms didn't resolve | LOW | Stored in user cache CSV; not exposed in final `lifestage_dictionary` |
| NVS `owl:sameAs` cross-reference to UBERON | S11 terms link to UBERON IRIs — confirms semantic alignment when both providers agree | LOW | Present in JSON-LD but not currently extracted; low priority for v2.4 |
| Session-level NVS index cache (`.ComptoxREnv`) | Fetches S11 full collection once per session, not once per term | LOW | Implemented in `.eco_lifestage_nvs_index()`; refreshable via `refresh = TRUE` |

### Anti-Features (Scope Creep to Reject)

| Anti-Feature | Why Requested | Why Problematic | Alternative |
|--------------|---------------|-----------------|-------------|
| Regex over raw ECOTOX terms in canonical output | Seems like a quick fallback for unresolved terms | Violates source-backed provenance guarantee; produces false confidence | Put unresolved terms in `lifestage_review` with `review_status = "unresolved"` |
| Exported patch function (`.eco_patch_lifestage()` as public API) | Users want to trigger patches themselves | Exposes internal DB path assumptions; hard to document safely; breaks if DB schema changes | Keep internal; document in CLAUDE.md for maintainers |
| Live API call per term during `eco_results()` query | Seems like fresh data | Catastrophic latency — `eco_results()` runs SQL joins, not per-row R code | All resolution happens at build/patch time; query-time is join-only |
| Storing resolved terms in `sysdata.rda` | Fast startup, no file I/O | Binary blobs are unauditable, fail for users on different ECOTOX releases, and break baseline CSV pattern | Use `inst/extdata/ecotox/lifestage_baseline.csv` + user cache CSV |
| OLS4 `isDefiningOntology=true` filter in search query | Seems cleaner to only get UBERON-native terms | The facet data confirms it's not a per-doc field filter — it filters via Solr facets, not as a doc-level query parameter. Using `ontology=uberon` is sufficient. Also, imported terms may still be relevant | Restrict by `ontology=uberon` (or `po`); score by label match rather than provenance filter |
| Parallel HTTP requests to OLS4/NVS | Faster batch resolution | OLS4 rate limits are not published; parallel requests risk transient 503s that poison cache; sequential with retry is safe | Sequential with `httr2::req_retry()` is sufficient for the ~200-term ECOTOX lifestage vocabulary |
| Cross-release cache reuse | Avoid re-fetching for similar releases | ECOTOX adds/renames terms between releases; cross-release cache silently omits new terms | Strict release scoping enforced by `.eco_lifestage_validate_cache()` |
| Full test suite with VCR cassettes for provider lookups | Seems like good coverage | VCR cassettes for OLS4 and NVS SPARQL are large and brittle against schema changes; provider APIs are external | Use `testthat::with_mocked_bindings()` for unit tests; keep live smoke checks in `dev/lifestage/` |
| `ontology_id` alias column kept for backwards compat | Existing user code may reference it | v2.3 `ontology_id` was a fabricated manual entry — aliasing fake data perpetuates the problem | Remove immediately; document breaking change in NEWS.md |

---

## Feature Dependencies

```
lifestage_baseline.csv (inst/extdata)
    └──seeds──> user cache CSV (tools::R_user_dir)
                    └──feeds──> .eco_lifestage_materialize_tables()
                                    |
                    OLS4 search ────┤ (live fallback when cache/baseline miss)
                    NVS SPARQL ─────┘
                                    |
                                    v
                         cache rows (scored, ranked)
                                    |
                         ┌──────────┴────────────┐
                         v                        v
              .eco_lifestage_derive_fields()   lifestage_review
              (requires lifestage_derivation.csv)
                         |
                         v
              lifestage_dictionary (DuckDB)
                         |
                         v
              eco_results() join ──> 8 lifestage columns exposed

.eco_patch_lifestage()
    └──wraps──> .eco_lifestage_materialize_tables()
                    └──same logic as build script section 16

Build script section 16 (data-raw/ecotox.R)
    └──must be identical to──> inst/ecotox/ecotox_build.R section 16
```

### Dependency Notes

- **`lifestage_baseline.csv` must exist before build/patch works without live API:** The baseline
  seeds the user cache on first run. Without it, cold-start always requires network access.

- **`lifestage_derivation.csv` must exist before any term enters `lifestage_dictionary`:** Resolved
  terms without a derivation mapping entry are quarantined to `lifestage_review` with
  `review_status = "needs_derivation"`. The derivation map is the sole source of
  `harmonized_life_stage` and `reproductive_stage`.

- **`.eco_patch_lifestage()` requires `_metadata.ecotox_release` key:** The patch function reads
  the installed release from `_metadata`. If the DB was built without this key (impossible
  with current build scripts, but worth guarding), the patch aborts.

- **`eco_results()` join requires `lifestage_dictionary` with v2.4 schema:** The v2.3 5-column
  schema is incompatible. Purge and rebuild required before `eco_results()` works with new columns.

- **NVS SPARQL index is session-cached in `.ComptoxREnv`:** The first call per session fetches
  all ~130 S11 terms. Subsequent calls for different terms use the in-memory index. This means
  `.eco_lifestage_query_nvs()` is free after the first call but has a cold-start cost (~1-2s).

---

## MVP Definition

This is a replacing-existing-feature milestone, not a greenfield project. "MVP" means the
minimum needed to ship a correct replacement that removes v2.3's fake provenance.

### Launch With (v2.4.0)

- [x] Tear out v2.3 regex classifier and manual `ontology_id` from `lifestage_dictionary`
- [x] `R/eco_lifestage_patch.R` shared helper layer (already implemented)
- [ ] `inst/extdata/ecotox/lifestage_baseline.csv` covering current ECOTOX release
- [ ] `inst/extdata/ecotox/lifestage_derivation.csv` with curated `harmonized_life_stage` mappings
- [ ] Build script section 16 replaced in both `data-raw/ecotox.R` and `inst/ecotox/ecotox_build.R`
- [ ] `eco_results()` updated: new 8 lifestage columns, `ontology_id` removed
- [ ] Existing tests updated for new column schema
- [ ] `devtools::check()` passes (0 errors, 0 warnings on new code)

### Add After Validation (v2.4.x)

- [ ] Mocked provider adapter tests (CI-safe unit tests with `testthat::with_mocked_bindings()`)
- [ ] `ontology_id` removal documented in `NEWS.md` as breaking change
- [ ] `dev/lifestage/validate_lifestage.R` updated for new column layout
- [ ] `dev/lifestage/confirm_gate.R` updated to verify patch-path

### Future Consideration (v2.5+)

- [ ] NVS `owl:sameAs` → UBERON cross-reference extraction (triangulation confidence boost)
- [ ] Public patch API (only if user demand surfaces — currently internal-only by design)
- [ ] SPARQL-based OLS4 queries for structured ancestor traversal (currently overkill)

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Remove v2.3 regex / fake `ontology_id` | HIGH | LOW (delete code) | P1 |
| `lifestage_baseline.csv` committed | HIGH | MEDIUM (curate data) | P1 |
| `lifestage_derivation.csv` committed | HIGH | MEDIUM (curate data) | P1 |
| Build script section 16 replacement | HIGH | LOW (call helpers) | P1 |
| `eco_results()` column update | HIGH | LOW (join change) | P1 |
| `.eco_patch_lifestage()` internal function | HIGH | LOW (already written) | P1 |
| Mocked provider tests | MEDIUM | MEDIUM (test setup) | P2 |
| NEWS.md breaking change documentation | MEDIUM | LOW | P2 |
| NVS `owl:sameAs` extraction | LOW | LOW | P3 |
| Public patch API | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Required for v2.4.0 correctness
- P2: Required for v2.4 quality gates
- P3: Nice to have, future milestone

---

## Scoring and Matching Implementation Notes

The scoring approach in `.eco_lifestage_score_text()` implements the plan's tier structure:

| Score | Condition | `candidate_reason` |
|-------|-----------|-------------------|
| 100 | Strict normalized exact match (lowercase + whitespace) | `exact_normalized_label` |
| 90 | Loose normalized exact match (punctuation + plural stripped) | `punctuation_plural_normalized_label` |
| 75 | Boundary or token containment match | `boundary_match` or `token_match` |
| 0 | No match at 75+ threshold | `no_candidate_ge75` or `no_provider_candidates` |

**Status assignment:**
- `"resolved"`: top score >= 90 AND exactly one candidate at that score
- `"ambiguous"`: multiple candidates >= 75, or top < 90
- `"unresolved"`: no candidate >= 75

**OLS4-specific hazard:** Because OLS4 returns Solr-ranked results (not exact-match-first),
the scoring layer must evaluate all returned candidates — not just the top result. The
implementation scores all docs and then applies the tier logic. This is correct.

**NVS-specific hazard:** The SPARQL endpoint aggregates `altLabel` values as separate bindings.
The `GROUP_CONCAT` approach used in `.eco_lifestage_nvs_index()` (via R's `summarise +
paste`) correctly collapses multiple altLabel rows into a pipe-separated string.
The index is fetched once and scored locally — no per-term SPARQL query.

---

## Sources

- OLS4 live API verified: `https://www.ebi.ac.uk/ols4/api/search` (queries executed 2026-04-22)
- OLS4 architecture: [OLS4: A new Ontology Lookup Service — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC12094816/)
- OLS4 GitHub source: [EBISPOT/ols4](https://github.com/EBISPOT/ols4)
- OLS4 scoring bug (misleading results): [GitHub Issue #860](https://github.com/EBISPOT/ols4/issues/860)
- ols-py Python client (response schema reference): [ahida-development/ols-py](https://github.com/ahida-development/ols-py)
- NVS S11 collection: `https://vocab.nerc.ac.uk/collection/S11/current/` (fetched 2026-04-22)
- NVS S11 term S1130 (nauplius) JSON-LD: verified fields `skos:prefLabel`, `skos:altLabel`, `skos:definition`, `owl:sameAs`
- NVS SPARQL endpoint: `https://vocab.nerc.ac.uk/sparql/`
- NVS documentation: [BODC Web Services](https://www.bodc.ac.uk/resources/products/web_services/vocab/)
- NVS GitHub: [nvs-vocabs/S11](https://github.com/nvs-vocabs/S11)
- DuckDB friendly SQL (`CREATE OR REPLACE TABLE`): [DuckDB Friendly SQL docs](https://duckdb.org/docs/current/sql/dialect/friendly_sql)
- R package caching with `tools::R_user_dir`: [R-hub blog: Caching results](https://blog.r-hub.io/2021/07/30/cache/)
- R package `inst/extdata` baseline pattern: [R Packages (2e): Data](https://r-pkgs.org/data.html)
- pkgcache cache directory pattern: [pkgcache on CRAN](https://cran.r-project.org/package=pkgcache)
- Implementation ground truth: `R/eco_lifestage_patch.R` (ComptoxR, as of 2026-04-22)

---

*Feature research for: ComptoxR v2.4 source-backed lifestage resolution*
*Researched: 2026-04-22*
