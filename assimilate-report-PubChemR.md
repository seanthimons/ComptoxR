# Assimilate Report: PubChemR
Direction: Chemical / physical properties endpoints
Source: https://github.com/selcukorkmaz/PubChemR
Date: 2025-03-25

## Current Repo Profile (ComptoxR)
R package wrapping USEPA CompTox Dashboard APIs. Uses `generic_request()` / `generic_chemi_request()` centralized templates with httr2, automatic batching, API key auth, tibble output. Functions follow `ct_*` / `chemi_*` naming. Already has `ct_chemical_property_experimental()` and `ct_chemical_property_predicted()` for CompTox properties.

## Source Repo Profile (PubChemR)
R package wrapping PubChem PUG REST/PUG View APIs. Uses S3 class hierarchy (`PubChemInstance` → typed subclasses), httr + RJSONIO, two-tier caching (memory + disk), rate limiting, async polling. `get_properties()` is the main properties endpoint. 39 predefined chemical/physical properties available via PUG REST. v3.0.0 adds analysis layer (activity matrices, cross-domain joins, sparse matrix support).

## Architecture Delta
| Dimension | ComptoxR | PubChemR |
|-----------|----------|----------|
| HTTP lib | httr2 | httr |
| Templates | Centralized `generic_request()` | Per-function with shared `pc_collect_instances()` |
| Auth | API key header | None (PubChem is public) |
| Batching | POST body with configurable `batch_limit` | Auto-detect by namespace, 100-item chunks |
| Caching | None (session env for compiled objects) | Two-tier memory + disk, 24h TTL |
| Output | Tibble (tidy=TRUE) or list | Custom S3 classes with `retrieve()` extractors |
| Properties | CompTox experimental + predicted endpoints | PubChem 39 computed properties |

**Key barrier:** Different API backends (EPA CompTox vs NCBI PubChem), different auth models, different response structures. Code cannot be directly ported — but the **data** and **patterns** are highly complementary.

## Findings (ranked by practical value)

### 1. [HIGH] PubChem Property Retrieval — New Data Source for ComptoxR
- **What**: `get_properties()` provides 39 chemical/physical properties (MolecularWeight, XLogP, TPSA, HBondDonorCount, Complexity, Volume3D, etc.) for any compound identifiable by CID, name, SMILES, InChI, or formula. These are PubChem-computed properties, complementing CompTox's experimental and OPERA-predicted values.
- **Where**: `R/get_properties.R`, `R/00_globals.R` (property_map function, lines 80-171)
- **Extractability**: Adapt
- **Effort**: Medium
- **Why it is useful**: ComptoxR users working with DTXSIDs could cross-reference PubChem properties for compounds. PubChem has broader chemical coverage than CompTox (~116M vs ~1M compounds). Properties like TPSA, Complexity, 3D descriptors are not available from CompTox endpoints.
- **How to adapt**:
  1. Create `pc_properties()` function using ComptoxR's `generic_request()` pattern but targeting PubChem's PUG REST API (`https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/{namespace}/{id}/property/{props}/JSON`)
  2. No auth needed (public API)
  3. Accept DTXSID input, resolve to CID via PubChem name search or maintain a DTXSID→CID mapping
  4. Port the 39-property list from `property_map()` as a validation lookup
  5. Return tibble matching ComptoxR conventions

### 2. [HIGH] Property Name Fuzzy Matching System
- **What**: `property_map()` accepts user-friendly partial names and resolves them to exact PubChem property names using four match modes: `"match"` (exact), `"contain"` (substring), `"start"` (prefix), `"end"` (suffix), plus `"all"` for everything. Case-insensitive option available.
- **Where**: `R/00_globals.R:80-171`, `R/get_properties.R:157-162`
- **Extractability**: Direct port
- **Effort**: Low
- **Why it is useful**: ComptoxR's property functions require exact property names. A fuzzy matcher would improve UX — e.g., `ct_chemical_property_experimental("molecular")` could auto-resolve to all molecular-weight-related properties.
- **How to adapt**: Extract the `property_map()` function, adapt the property list to CompTox's experimental/predicted property names (obtainable from the API schema), wire it into `ct_chemical_property_experimental()` and `ct_chemical_property_predicted()` as an optional convenience layer.

### 3. [HIGH] Two-Tier Response Caching
- **What**: In-memory + on-disk caching with TTL validation, MD5-hashed cache keys, and configurable eviction. Reduces redundant API calls dramatically for iterative workflows.
- **Where**: `R/pc_api.R:297-341` (cache get/set/clear/info), `R/pc_api.R:272-295` (config)
- **Extractability**: Adapt
- **Effort**: Medium
- **Why it is useful**: ComptoxR has no response caching. Users doing iterative analysis re-hit the CompTox API unnecessarily. A cache layer in `generic_request()` would be a significant quality-of-life improvement, especially given CompTox's rate limits.
- **How to adapt**:
  1. Add a `.ComptoxRCache` environment for memory cache
  2. Use `tools::md5sum()` or `digest::digest()` for cache keys based on endpoint + query + params
  3. Store RDS files in `tempdir()/ComptoxR_cache/`
  4. Add `cache_ttl` parameter to `generic_request()` (default 24h, 0 to disable)
  5. Check cache before making HTTP request

### 4. [MEDIUM] Rate Limiting / Throttling
- **What**: `pc_throttle()` enforces minimum interval between requests (1/rate_limit seconds). Tracks last request time, sleeps if needed.
- **Where**: `R/pc_api.R:161-175`
- **Extractability**: Direct port
- **Effort**: Low
- **Why it is useful**: ComptoxR's batching helps but doesn't throttle. Heavy users can get rate-limited by EPA. A simple throttle in `generic_request()` would prevent 429 errors.
- **How to adapt**: Add a `last_request_time` tracker in `.ComptoxREnv`, check/sleep before each `httr2::req_perform()` call. ~15 lines of code.

### 5. [MEDIUM] Batch Decomposition Pattern
- **What**: `pc_decompose_batch()` splits a batch response back into per-identifier results, recognizing three response structures (compounds, property tables, information lists). Enables per-ID error tracking even in bulk requests.
- **Where**: `R/internal_utils.R:263-325`
- **Extractability**: Inspiration
- **Effort**: Medium
- **Why it is useful**: ComptoxR's `generic_request()` returns bulk results as a single tibble. Per-ID error tracking (which IDs failed in a batch?) is not surfaced. Adapting this pattern would improve debugging for users with mixed-validity input lists.
- **How to adapt**: After batch POST, compare returned DTXSIDs against input to identify missing/failed IDs. Log warnings per failed ID rather than silent omission.

### 6. [MEDIUM] PubChem Compound → Property Pipeline for Cross-Database Enrichment
- **What**: PubChemR's workflow vignettes demonstrate a compound-to-properties pipeline: resolve names → get CIDs → batch properties → model matrix. The `pc_model_matrix()` function converts property tibbles to numeric matrices ready for ML.
- **Where**: `vignettes/pubchemr-workflow.Rmd`, `R/pc_phase4.R`
- **Extractability**: Inspiration
- **Effort**: High
- **Why it is useful**: A `ct_enrich_pubchem()` function could take DTXSIDs, resolve to PubChem CIDs, fetch PubChem properties, and merge with CompTox data — giving users a single call to build enriched chemical feature tables.
- **How to adapt**: This is a higher-level integration. Would require DTXSID↔CID mapping (via `ct_similar()` or PubChem name search) plus the property retrieval from Finding #1.

### 7. [MEDIUM] Structured Error Objects
- **What**: All failures return normalized error objects with `Code`, `Message`, `Details`, `ErrorClass`, `Status`. Per-ID failure tracking preserves request provenance.
- **Where**: `R/internal_utils.R:26-71`
- **Extractability**: Inspiration
- **Effort**: Low
- **Why it is useful**: ComptoxR uses cli warnings/messages but doesn't return structured error metadata in results. Adding a `.errors` attribute to returned tibbles would help users diagnose batch failures programmatically.
- **How to adapt**: In `generic_request()`, when a batch returns partial results, attach an `errors` attribute listing failed query items with HTTP status and message.

### 8. [LOW] 39-Property Canonical List as Package Data
- **What**: Hardcoded vector of 39 PubChem property names with groupings (molecular descriptors, stereo counts, 3D features).
- **Where**: `R/00_globals.R:80-117`
- **Extractability**: Data only
- **Effort**: Low
- **Why it is useful**: Useful reference for documentation or validation if ComptoxR adds PubChem integration. Could be stored in `data-raw/` as a lookup table mapping PubChem property names to human-readable labels and categories.
- **How to adapt**: Copy the property list, add it to `data-raw/pubchem_properties.R`, generate a `pubchem_properties` internal dataset.

### 9. [LOW] Async Polling Pattern
- **What**: `pc_submit()` → `pc_poll()` with exponential backoff for long-running similarity/substructure searches. Returns `PubChemAsyncQuery` with `listkey` for status polling.
- **Where**: `R/pc_phase3.R`
- **Extractability**: Inspiration
- **Effort**: High
- **Why it is useful**: Some CompTox endpoints (bulk hazard, bulk bioactivity) can be slow. An async pattern could improve UX for large queries.
- **How to adapt**: Not practical for current CompTox API which doesn't support async. File for future reference only.

### 10. [LOW] PUG View Section Extraction
- **What**: `get_pug_view()` retrieves hierarchical annotation data with recursive section traversal. `get_biological_test_results()` extracts specific sections by heading match.
- **Where**: `R/get_pug_view.R`, `R/get_biological_test_results.R`
- **Extractability**: Inspiration
- **Effort**: High
- **Why it is useful**: PUG View provides experimental property data (melting point, boiling point, density from depositors) that PUG REST properties don't include. Could complement CompTox experimental properties.
- **How to adapt**: Would require a separate PUG View integration — high effort for marginal gain since CompTox already has experimental properties.

## Quick Wins
- **Property name fuzzy matcher** (~30 lines): Port `property_map()` logic, wire into existing CompTox property functions for friendlier UX
- **Rate limiter** (~15 lines): Add throttle to `generic_request()` to prevent 429s
- **39-property lookup table** (~5 min): Copy property list to `data-raw/` for reference/documentation
- **Failed-ID tracking** (~20 lines): Compare batch output DTXSIDs against input, warn on missing

## Not Worth It
- **S3 class hierarchy** (PubChemInstance/PubChemInstanceList): ComptoxR returns tibbles directly — adding wrapper classes would break existing API and add complexity for no gain
- **httr migration**: PubChemR uses httr; ComptoxR already uses httr2 which is superior. No reason to regress.
- **Phase 4 analysis layer** (activity matrices, model matrices): Highly PubChem-specific. ComptoxR users can use existing R modeling packages directly on tibble output.
- **Disk caching with RDS**: Adds filesystem side effects. Memory-only caching is simpler and sufficient for most sessions. Consider disk cache only if users request persistence across sessions.
- **PUG View integration**: Different API entirely (PubChem, not CompTox). High effort, niche use case.
