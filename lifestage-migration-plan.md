# ECOTOX lifestage migration assessment and plan

## Executive summary

**Estimated effort: L (5-9 working days), plus 1-3 days if the AMOS package is renamed.** Independent scientific review and downstream adoption need separate time. These are planning estimates for one maintainer, not measured delivery times.

Move the full lifestage derivation workflow into a dedicated harmonization R package. Remove automatic lifestage derivation from the ComptoxR ECOTOX build and query paths. Keep the original ECOTOX code and description. Users who need the derived fields must call the harmonization package explicitly and select a versioned data release.

**Recommended destination: extend `amosharmonizer`, then rebrand it in a separate change.** Its offline tables, source snapshots, mapping decisions, release manifest, and content hashes provide a useful starting point. Keep AMOS and ECOTOX rules and review records separate within that package. Do not build a general ontology framework.

Working name: **`envharmonizer`**, with repository name `env-harmonizer` and title "Versioned Environmental Data Harmonization". This is a proposal only. Package, repository, and name availability have not been checked. Alternatives are `ecochemharmonizer` and `envcrosswalk`. Select the name before a public rename, but do not make naming a condition for the initial extraction.

## Why make this change?

The concern is valid: users can receive an author-derived category as part of a normal ECOTOX query without taking a separate step to use that interpretation. An explicit package call makes the source of the interpretation easier to see, cite, reproduce, and decline.

However, a package boundary does not establish scientific approval. A source ontology can support a term match without supporting the later reduction to seven categories or the reproductive flag. Passing tests establishes software behavior. It does not establish biological validity. Existing use of the column is also not evidence that the method is invalid.

Treat these as three separate records:

1. **Source evidence:** the original ECOTOX value and the ontology concept used.
2. **Curation decision:** who selected the match and derived category, with reasons and a date.
3. **Independent scientific review:** who assessed the method and mappings, what they assessed, and the outcome. Journal peer review, if obtained, is a separate publication record.

Do not describe the current lifestage release as independently reviewed without evidence. Preserve its current behavior as a clearly marked legacy baseline. Release it for reproducibility with an explicit review status. Scientific corrections must be separate, documented mapping changes.

## Scope and evidence

This is a plan only. No runtime, data, CI, or AMOS files were changed.

Local evidence examined on 2026-09-07:

- ComptoxR commit `8f055b8`, initially on `integration`; `CONTRIBUTING.md` and `endpoint-audit.md` supplied the workflow and assessment format.
- The local `../amos-harmonizer` checkout at commit `3872716`: README, DESCRIPTION, release builder, accessors, hash helpers, release manifest, data-license document, and check workflow.
- AMOS `CONTEXT.md` has a pre-existing local edit. Its review terminology is useful context, but it is not treated as proof of a released review policy.
- `endpoint-audit.md` was already untracked. Leave it unchanged and outside this plan's commit.

No upstream ontology service or published release was refreshed. This plan describes the local implementation. Source license terms, current ontology versions, actual downstream usage, and name availability must be verified before migration or publication where relevant.

Success means: the new package reproduces the frozen mapping, provides an offline artifact with provenance, and owns all future curation; ComptoxR builds and queries ECOTOX without that package or its derived tables; existing users have a tested migration route.

## Inventory

| Location | Current behavior | Planned action |
|---|---|---|
| `R/eco_lifestage_patch.R` | About 2,700 lines cover seed/cache schemas, provider queries, scoring, taxon routing, derivation, review tables, and DuckDB patching. Uses `.ComptoxREnv`, ComptoxR cache paths, package lookup, and configuration names. | Transfer the full workflow and its evidence. Change ownership-specific paths and dependencies. Keep provider refresh and DB maintenance outside the new public lookup API. |
| `inst/extdata/ecotox/lifestage_patch_seed.csv` | Installed, release-scoped seed with match evidence and derived fields. | Freeze and transfer. Publish from the new package; remove from the future ComptoxR package. |
| `dev/lifestage/source/` | Baseline, audit, derivation, aliases, curated candidates, forced-unresolved rules, domain patterns, taxon routes, and ontology priorities. | Transfer all inputs with hashes and source history. |
| `dev/lifestage/curation/` and `dev/lifestage/provenance/` | Review queue, taxon intersections, semantic adjudication, and curated exceptions. | Transfer all decisions and evidence. Preserve unknown or absent reviewer identity as unknown. |
| `dev/lifestage/*.R` and README | Refresh, rebuild, probes, ranking, taxon and semantic reports, patch checks, and old phase validation scripts. | Transfer active scripts and documentation. Preserve old phase scripts as historical material; do not delete their evidence or run destructive maintenance during migration. |
| `data-raw/ecotox.R:87,1073,1202` | Loads shared helpers, materializes dictionary/review tables, and reports typed vocabulary drift. | Remove the harmonization steps and their loader/error coupling. Keep native ECOTOX data import. |
| `inst/ecotox/ecotox_build.R:87,1072,1201` | Installed build script repeats the same integration. | Make the equivalent removal and test the installed path. Editing only `data-raw/` is insufficient. |
| `R/eco_functions.R:283-478` | `eco_results()` exposes `lifestage_details`; local and Plumber paths use the output selector. Default results contain `harmonized_life_stage` and `reproductive_stage`. | Define a source-only result contract for both paths and retire the derived-field argument with a clear migration error. |
| `R/eco_functions.R:753-846` | Metadata enrichment joins native codes to descriptions, then joins `lifestage_dictionary`. Validation requires that dictionary. | Keep the native code-description join. Remove the derived join and its schema requirement. |
| `man/eco_results.Rd` | Documents compact and detailed derived output. | Update roxygen and regenerate help when the implementation changes. |
| `.github/workflows/db-ecotox.yml` | Builds the database, opens a vocabulary-drift issue on failure, then uploads rolling DB assets. | Move lifestage drift reporting to harmonizer maintenance. Preserve failure handling for real ECOTOX build errors. |
| `tests/testthat/test-eco_lifestage_gate.R`, `test-eco_lifestage_data.R` | Provider, cache, curation, materialization, patch, and query contracts. | Move domain tests; retain and rewrite ComptoxR query/build integration tests. |
| `tests/testthat/test-ecotox_vocabulary_drift.R` | Tests drift conditions, reports, and build integration. | Move mapping drift checks. Replace pipeline coupling checks with source-only build checks. |
| `tests/testthat/test-eco_functions.R`, `test-cran_tarball_test_paths.R`, `dev/cran_readiness.R`, test guides | Query assertions and readiness configuration refer to the lifestage implementation. | Update only affected assertions, test paths, and instructions. |

The `lifestage` field in `R/tox_functions.R` belongs to ToxVal. It is not this ECOTOX derivation and must remain unchanged. Do not remove all occurrences of the word "lifestage".

## Current coupling and meaning

The current flow is:

```text
Provider evidence + policy CSVs + curation
  -> installed patch seed
  -> ECOTOX builder or local patch
  -> lifestage_dictionary + lifestage_review in DuckDB
  -> eco_results() metadata join
  -> default derived columns
```

`.eco_lifestage_materialize_tables()` uses release-scoped terms, rejects missing vocabulary, selects the first ranked resolved candidate per description, and retains unresolved or incomplete derivations in review output. The dictionary join uses `org_lifestage`, not a taxon key. Taxon context is used in curation and routing; it is not a per-result taxon-aware join. Preserve this behavior during extraction. A future change to taxon-specific result mappings needs separate scientific and API review.

The seed, dictionary, and review table are different products. An unresolved seed row with `Other/Unknown` does not imply that the current query returns that category: rows excluded from the dictionary can yield missing derived values after the left join. Likewise, a missing reproductive flag must not become `FALSE` during migration. Test the observable output, not just seed equality.

The Plumber path sends `lifestage_details` to the server and then selects output columns locally. Its deployed server implementation and users were not inspected. Locate them before changing the wire contract. A client-only change cannot prove server compatibility.

## Destination decision

| Option | Benefit | Cost | Assessment |
|---|---|---|---|
| Extend AMOS, then rename | Reuses offline accessors, manifests, hashes, review files, and table writer. One harmonization project to maintain. | Broader package scope; current imports include Arrow and PDF tools; rename affects AMOS consumers. | Recommended if the same maintainers own both domains. |
| New lifestage-only R package | Small domain boundary and independent release schedule. No AMOS rename. | Separate package maintenance and release setup; some small release helpers must be copied or adapted. | Use if ownership differs or AMOS dependency cost is unacceptable. |
| Move helpers but keep automatic ComptoxR enrichment | Small consumer change. | Users still receive the interpretation by default; base builds still depend on curation. | Does not meet the proposed boundary. |

The local AMOS project embeds RDS tables and writes CSV/Parquet artifacts under `artifacts/v<version>`. Its builder records input, table-content, and artifact hashes. This is a release-building pattern, not proof of an automated publication path: the inspected `.github/workflows/` contains an R CMD check workflow only.

Reuse its table writer, accessor pattern, and manifest conventions. Add an ECOTOX build entry point that can run from pinned lifestage inputs without an AMOS network refresh or PDF cache. Do not require both domains to refresh together. Keep separate source releases, rule versions, and review status within the shared package release.

AMOS currently suggests ComptoxR and pins it in `Remotes` for its maintenance needs. Keep the dependency direction explicit: ComptoxR must not import the new harmonizer. Offline lifestage access must not load ComptoxR or contact providers. A broad dependency cleanup is a separate task unless it prevents package installation or extraction.

## Minimal target design

```text
ComptoxR: ECOTOX data -> source code + source description

Harmonizer maintainers:
  pinned evidence + rules + decisions -> checked, versioned artifact

User, by explicit choice:
  ComptoxR results + matching artifact -> derived fields + provenance
```

Proposed API names are illustrative, not existing functions:

- `lifestage_dictionary(ecotox_release)` returns the embedded mapping for an explicit ECOTOX release.
- `harmonize_lifestage(x, ecotox_release)` takes a result data frame with `org_lifestage`, preserves all input rows and their order, and adds derived fields plus mapping provenance. Preserve `organism_lifestage` when supplied. Reject existing derived output columns instead of silently replacing them.
- Reuse `release_metadata()` for artifact identity and add a small `lifestage_review()` accessor for unresolved decisions and evidence.

Use the existing description-based mapping key for the first release. Enforce uniqueness per ECOTOX release and description before joining. Match distinct descriptions once, then join back; never call a provider or scan the whole dictionary separately for each result row.

Release mismatch must stop with a clear error. Missing or new descriptions remain unmatched with an explicit status and missing derived values; they must not acquire a guessed category. The artifact build must stop on unaccounted vocabulary drift until a curator records its disposition. This must no longer stop the base ECOTOX build.

Keep review state separate from `source_match_status`. For example, `resolved` describes a match, not independent approval. Carry artifact version and review status in portable output columns, with source and rule details available through the dictionary and manifest. Do not rely only on R attributes that CSV export will discard.

No automatic download, hidden update to "latest", runtime fuzzy match, or mutation of the user's ECOTOX database is needed. Transfer the existing DB patch workflow as maintainer/legacy support, but use a data-frame join for normal users. Test any retained patch operation on a temporary database copy.

## Artifact and review contract

Publish the following as one immutable, versioned release set:

| Product | Required content |
|---|---|
| R source package | Offline accessors and installed RDS tables, with generated help. |
| Data files | Dictionary, seed/decisions needed to reproduce it, and review output; use the AMOS CSV/Parquet writer if merged. |
| Manifest | Package version, artifact/schema/rule versions, ECOTOX release, source snapshot identifiers and hashes, mapping hashes, source commit, artifact checksums, and domain-specific review status. |
| Review report | Method scope, reviewers, dates, disagreements, decisions, unresolved cases, and coverage by term and record usage where counts are available. |
| Citation and attribution | Named authors/curators, version citation, source attribution, and verified redistribution terms for each included source. Do not inherit the AMOS data license without checking the new sources. |

Separate reproducible table-content hashes from build timestamps. Two builds from identical pinned inputs must have identical normalized table hashes. File checksums identify the actual published files. Validate serialized types and missing values across RDS, CSV, and Parquet.

Use a draft or clearly marked provisional release for the preserved legacy mapping. Require independent domain review before claiming that the lifestage method is scientifically reviewed. Review the seven-category reduction, reproductive semantics, taxon limits, forced choices, and unresolved policy, not just ontology IDs. Have reviewers assess a fixed input set before seeing the original decisions where practical; record and resolve disagreements. Set acceptance criteria before measuring agreement or error rates.

The initial parity test is not independent validation: its expected values come from the implementation being moved. The current AMOS builder also distinguishes its CONCERT gate from broad validation. A passed AMOS gate must not imply approval of ECOTOX lifestage mappings.

## Ordered migration checklist

### 1. Freeze the baseline and identify users (0.5-1 day)

- Record source commits, file hashes, seed release, rule inputs, and representative default/detailed query outputs. Include missing and unresolved terms.
- Inventory every tracked lifestage file, its callers, untracked maintainer inputs, and any external scripts or services that use private helpers. Copy only required, sanitized inputs; preserve historical evidence separately.
- Find consumers of both derived columns and `lifestage_details`, including the Plumber service and stored analyses. Record the ComptoxR package and database versions they require.
- Confirm destination ownership and the public source-only schema. Recommended native fields: `organism_lifestage` and `org_lifestage`.
- **Gate:** a fixed parity dataset and a complete transfer inventory exist; no current data or mapping has been changed.

### 2. Transfer the complete workflow (1.5-2.5 days)

- Copy runtime derivation helpers, source and policy CSVs, decisions, evidence, refresh/build scripts, and domain tests to a dedicated lifestage area in the destination.
- Record original paths and commits in a migration manifest so evidence remains traceable without rewriting repository history.
- Replace ComptoxR-specific package paths, environment storage, cache names, and helper dependencies. Pass explicit release/input values where possible. Never load the old package's private namespace for normal operation.
- Make maintenance scripts callable through functions from an interactive R session, with thin command-line entry points.
- Preserve existing mapping decisions and quarantine behavior. Separate old destructive DB scripts from routine release generation.
- **Gate:** the destination can produce the same dictionary and review content from fixed local inputs without the ComptoxR lifestage file or live provider calls.

### 3. Add explicit access and build artifacts (1-2 days)

- Add the offline accessors and checked result join described above. Retain all source columns.
- Reuse AMOS release helpers and add domain-specific manifest and review records. Do not reuse its AMOS-specific validation gate for lifestage.
- Build a source tarball and data artifacts. Install the tarball in a clean R library and test from outside either checkout.
- Add publication steps using the destination's chosen release process. Verify the exact uploaded files against the manifest; do not replace an existing version's files.
- **Gate:** reproducible tables, verified serialization, usable installed package, and an explicit provisional/reviewed status. Publication must not imply review that has not occurred.

### 4. Remove automatic ECOTOX derivation (1-2 days)

- Remove harmonization materialization, loaders, and drift handlers from both ECOTOX builders. Preserve `lifestage_codes` and other ECOTOX enrichment.
- Remove the dictionary requirement and derived join from `eco_results()`. Keep native code-description output. Ignore old derived tables in existing databases; do not drop users' tables or edit their files.
- Apply the same source-only schema to local and Plumber results. For an older server response, remove only known derived fields and verify raw fields are present. Fail clearly if a supported response cannot provide the source contract.
- Retain the existing argument position during transition: default `lifestage_details = FALSE` yields source-only output; explicit `TRUE` fails with the external-package migration instruction. Remove the argument in a later breaking release. This default-column removal is itself a breaking change and must be released as such.
- Move harmonization drift reporting and curation instructions to the destination. Keep ordinary ECOTOX build failures blocking publication.
- Remove the seed and transferred lifestage implementation from ComptoxR after destination parity passes. Update affected tests, readiness lists, help, and release notes through the normal release process.
- **Gate:** new and old databases work without the derived dictionary, and neither default path returns either derived column.

### 5. Coordinate the transition (1-1.5 days)

- Make a versioned destination artifact available before the ComptoxR breaking release.
- Publish a before/after migration example: query ECOTOX with ComptoxR, obtain its recorded release ID, then call the external harmonizer with that ID. Test the example against the installed packages.
- Freeze the old package/database combination for users reproducing existing analyses. Record checksums and retrieval instructions; do not rewrite old releases to hide past behavior.
- Coordinate the Plumber server deployment and database rollout. New source-only DBs will fail with old clients that require a dictionary. Provide a versioned legacy DB asset and explicit client/DB compatibility instructions before replacing a rolling asset.
- A source-only rebuild can have the same ECOTOX release ID. Check downloader and build-gate behavior so it cannot mistake different builder schemas for identical artifacts. Use the existing force/build-version mechanism where sufficient; add a schema marker only if required.
- **Gate:** supported client/server/database combinations and the explicit harmonization example pass; the migration notice names both removed fields and the argument change.

### 6. Rebrand AMOS, if selected (additional 1-3 days)

- Check the proposed name and inventory consumers such as CONCERT before changing package identity.
- Change DESCRIPTION identity, namespace references, `system.file()` lookups, docs, installation instructions, CI, and release paths in a separate change. Preserve domain-specific AMOS function names and data identifiers.
- Record old-to-new package and artifact identities. Test downstream installation and AMOS table parity. Do not assume a repository redirect fixes R calls such as `amosharmonizer::amos_methods()`.
- Keep the old package release available. Update consumers explicitly; add a temporary compatibility package only if identified users require it.
- **Gate:** existing AMOS behavior and lifestage behavior both pass under the chosen name. No AMOS scientific decisions change as part of a rename.

## Validation plan

Use existing testthat patterns and fixed local fixtures. No live API calls or cassette refresh is needed for extraction.

| Check | Required result |
|---|---|
| Baseline parity | Identical dictionary/review values, field types, missingness, and derived query outputs for the frozen release; only new provenance columns may differ. |
| Join safety | Empty input, repeated terms, missing descriptions, unknown terms, and duplicate mapping keys behave as specified. Input row count/order and source columns remain intact. |
| Meaning preservation | Unresolved seed values are not promoted into resolved output. Missing reproductive status remains missing. Taxon context does not silently change the join key. |
| Release isolation | Wrong ECOTOX release stops. A missing mapping artifact cannot affect a ComptoxR query or base DB build. New vocabulary blocks only the harmonization artifact gate. |
| Installed package | Accessors work from outside the repo with no provider access, local cache, `.Renviron` secrets, or private ComptoxR helpers. |
| Artifact integrity | Two builds have equal normalized table hashes; serialized types/NA values round-trip; checksums match published files. |
| ECOTOX integration | Both builders and local/Plumber query paths return the source-only contract. Test databases with absent, present, and stale derived tables. |
| Migration compatibility | Old clients use the documented legacy DB; new clients work with supported old/new DBs; same-source-release rebuilds are detected or explicitly forced. |
| Scale | A large fixture with repeated descriptions does not multiply rows or cause per-row matching/provider work. Measure the changed join, not unrelated pipeline work. |
| AMOS regression | Existing AMOS tests and table hashes remain unchanged when adding lifestage. Repeat relevant installed-package checks after any rename. |

Start with `devtools::test(filter = 'eco_functions|eco_lifestage|ecotox_vocabulary_drift|cran_tarball_test_paths')` in ComptoxR while the old tests still exist, then use the retained/replacement tests after transfer. Run the moved lifestage tests in the destination. Run package checks on both source tarballs because installed files, dependency boundaries, and the public output contract change. Use `source('dev/cran_readiness.R')` for ComptoxR's final readiness check where its environment requirements are met.

## Risks and decisions

| Risk or open decision | Response |
|---|---|
| Users lose a column on upgrade | Treat removal of both derived columns as breaking; release the replacement first and provide an explicit conversion example. |
| Package branding implies scientific endorsement | Separate match, curation, independent review, and publication status in metadata and prose. |
| A "wholesale" move loses evidence or old workflows | Use a path/hash transfer inventory; retain historical scripts and inputs with provenance even when they are not part of normal runtime. |
| Scientific corrections get mixed into extraction | Freeze behavior first. Review and release corrections separately with a mapping change report. |
| Shared package requires AMOS caches to build ECOTOX artifacts | Use a dedicated lifestage build entry point and domain-specific inputs. |
| New ECOTOX release lacks reviewed mappings | Ship the source data independently; mark or block only the harmonization release. |
| Old clients download new source-only rolling DB | Stage package, server, and DB rollout; keep an immutable legacy DB and test compatibility. |
| Existing source terms have redistribution restrictions | Verify authoritative terms for each actual source before publishing transferred evidence. |
| Rename spreads work to AMOS consumers | Make it a separate step; defer it if it delays the data-boundary fix. |

The estimated effort covers extraction, parity, offline artifacts, and the coordinated ComptoxR change. It excludes journal submission, reviewer waiting time, an ontology redesign, retroactive re-analysis of user studies, and an unbounded downstream audit. Unknown service ownership or missing pinned inputs can extend the schedule.

## Assessment validation

Checked this plan against the local source, build scripts, tests, and AMOS release implementation. Runtime tests were not run because this change adds only a planning document. All programmatic gates above are future implementation requirements, not claimed results.
