# ECOTOX lifestage migration assessment and plan

## Executive summary

**Estimated effort: L (5-9 working days), plus 1-3 days for the AMOS rename.** Independent scientific review and downstream adoption need separate time. These are planning estimates for one maintainer, not measured delivery times.

Move the full lifestage derivation workflow into a dedicated harmonization R package. Remove automatic lifestage derivation from the ComptoxR ECOTOX build and query paths. Keep the original ECOTOX code and description. Users who need the derived fields must call the harmonization package explicitly and select a versioned data release.

**Confirmed destination: rename `amosharmonizer` directly to `envharmonizer`, with the identity change in a separate commit from the workflow transfer.** Its offline tables, source snapshots, mapping decisions, release manifest, and content hashes provide a useful starting point. Keep AMOS and ECOTOX rules and review records separate within that package. Do not build a general ontology framework.

Confirmed package name: **`envharmonizer`**; use repository name `env-harmonizer` and title "Versioned Environmental Data Harmonization". Preserve existing AMOS functions and data. No downstream users require a compatibility package; do not create one. Check name availability and the publication route as release preparation, without reopening the agreed package boundary.

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

No upstream ontology service or published release was refreshed. This plan describes the local implementation. Verify source license terms and name availability before publication. Freeze the inspected ontology inputs for parity; do not refresh versions during extraction.

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
| `R/eco_functions.R:283-478` | `eco_results()` exposes `lifestage_details`; local and Plumber paths use the output selector. Default results contain `harmonized_life_stage` and `reproductive_stage`. | Define a source-only result contract for both paths and remove `lifestage_details` from the public signature and request body in the breaking release. |
| `R/eco_functions.R:753-846` | Metadata enrichment joins native codes to descriptions, then joins `lifestage_dictionary`. Validation requires that dictionary. | Keep the native code-description join. Remove the derived join and its schema requirement. |
| `inst/plumber/ecotox/plumber.R` | Shipped localhost server calls ComptoxR against a local database and requires a matching package version. | Test the source-only result contract with the updated client and server; require restart after upgrade. |
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

The current Plumber client sends `lifestage_details` and selects output columns locally; its compact selector removes `organism_lifestage`. The shipped server is `inst/plumber/ecotox/plumber.R`: it calls local ComptoxR functions against a local database and requires a matching package version. The user controls this localhost deployment. Update client and server together, remove the request flag, preserve both source fields, and require a server restart after upgrade. No old-server compatibility layer is required. Test HTTP requests as well as direct database queries.

## Destination decision

Rename AMOS directly to `envharmonizer` and keep both domains in that package. Its existing offline release pattern is the selected foundation. Keep AMOS and ECOTOX rules, source releases, and review records separate. A new lifestage-only package, deferred rename, and compatibility package are not part of this migration. Current AMOS imports include Arrow and PDF tools; retain them unless they prevent installation or extraction.

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

Implement these agreed new APIs (they do not exist yet):

- `lifestage_dictionary(ecotox_release)` returns the embedded mapping for an explicit ECOTOX release.
- `harmonize_lifestage(x, ecotox_release)` takes a result data frame with `org_lifestage`, preserves all input rows and their order, and adds derived fields plus mapping provenance. Preserve `organism_lifestage` when supplied. Reject existing derived output columns instead of silently replacing them.
- Reuse `release_metadata()` for artifact identity and add a small `lifestage_review(ecotox_release)` accessor for unresolved decisions and evidence.

Use the existing description-based mapping key for the first release. Enforce uniqueness per ECOTOX release and description before joining. Match distinct descriptions once, then join back; never call a provider or scan the whole dictionary separately for each result row.

Release mismatch must stop with a clear error. Missing or new descriptions remain unmatched with an explicit status and missing derived values; they must not acquire a guessed category. The artifact build must stop on unaccounted vocabulary drift until a curator records its disposition. This must no longer stop the base ECOTOX build.

Keep review state separate from `source_match_status`. For example, `resolved` describes a match, not independent approval. Carry artifact version and review status in portable output columns, with source and rule details available through the dictionary and manifest. Do not rely only on R attributes that CSV export will discard.

No automatic download, hidden update to "latest", runtime fuzzy match, or mutation of the user's ECOTOX database is needed. Transfer the existing DB patch workflow as maintainer/legacy support, but use a data-frame join for normal users. Test any retained patch operation on a temporary database copy.

## Artifact and review contract

Publish the following as one immutable, versioned release set:

| Product | Required content |
|---|---|
| R source package | Offline accessors and installed RDS tables, with generated help. |
| Data files | Dictionary, seed/decisions needed to reproduce it, and review output; use the existing AMOS CSV/Parquet writer. |
| Manifest | Package version, artifact/schema/rule versions, ECOTOX release, source snapshot identifiers and hashes, mapping hashes, source commit, artifact checksums, and domain-specific review status. |
| Review report | Method scope, reviewers, dates, disagreements, decisions, unresolved cases, and coverage by term and record usage where counts are available. |
| Citation and attribution | Named authors/curators, version citation, source attribution, and verified redistribution terms for each included source. Do not inherit the AMOS data license without checking the new sources. |

Separate reproducible table-content hashes from build timestamps. Two builds from identical pinned inputs must have identical normalized table hashes. File checksums identify the actual published files. Validate serialized types and missing values across RDS, CSV, and Parquet.

Publish the preserved mapping as an experimental release before releasing ComptoxR derivation removal or withdrawing public database assets. Use the statement: **"Experimental mappings; not independently reviewed. Users must assess suitability for their analysis."** Independent review is not a condition for this first release. Require independent domain review before claiming that the lifestage method is scientifically reviewed. Review the seven-category reduction, reproductive semantics, taxon limits, forced choices, and unresolved policy, not just ontology IDs. Have reviewers assess a fixed input set before seeing the original decisions where practical; record and resolve disagreements. Set acceptance criteria before measuring agreement or error rates.

The initial parity test is not independent validation: its expected values come from the implementation being moved. The current AMOS builder also distinguishes its CONCERT gate from broad validation. A passed AMOS gate must not imply approval of ECOTOX lifestage mappings.

## Ordered migration checklist

### 1. Freeze the baseline and contracts (0.5-1 day)

- Record source commits, file hashes, seed release, rule inputs, and representative default/detailed query outputs. Include missing and unresolved terms.
- Inventory every tracked lifestage file, its callers, untracked maintainer inputs, and any external scripts or services that use private helpers. Copy only required, sanitized inputs; preserve historical evidence separately.
- Inventory in-repository consumers of both derived columns and `lifestage_details`, including the shipped Plumber service and examples. Require client updates; do not add an old-client or old-server support path.
- Freeze the agreed destination and public source-only schema: `envharmonizer`, with native fields `organism_lifestage` and `org_lifestage` in ComptoxR.
- **Gate:** a fixed parity dataset and a complete transfer inventory exist; no current data or mapping has been changed.

### 2. Rename AMOS and transfer the complete workflow (2.5-5.5 days)

- Rename AMOS directly to `envharmonizer` in a separate commit. Update DESCRIPTION identity, namespace references, `system.file()` lookups, docs, installation instructions, CI, and release paths. Preserve domain-specific AMOS function names, data identifiers, results, and hashes. Do not create a compatibility package.
- Record old-to-new package and artifact identities. Test installation and existing AMOS behavior under the new name.
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
- **Gate:** published replacement package and versioned artifacts, verified checksums and serialization, reproducible tables, usable installed package, and explicit experimental/not-independently-reviewed status. Record this evidence before releasing ComptoxR removal or withdrawing downloads.

### 4. Remove automatic ECOTOX derivation (1-2 days)

- Remove harmonization materialization, loaders, and drift handlers from both ECOTOX builders. Preserve `lifestage_codes` and other ECOTOX enrichment.
- Remove the dictionary requirement and derived join from `eco_results()`. Keep native code-description output. Ignore old derived tables in existing databases; do not drop users' tables or edit their files.
- Apply the same source-only schema to direct database queries and the shipped localhost Plumber service. Update and test both together with matching ComptoxR versions. Require a restart after upgrade; do not support old-server responses.
- Remove `lifestage_details` completely from the public signature, internal calls, request body, and documentation. Remove its now-unused validation and derived-output selection logic. Test that named calls supplying the removed argument fail. Document the argument and default-column removals as breaking changes, including the shifted position of `con` for positional callers.
- Move harmonization drift reporting and curation instructions to the destination. Keep ordinary ECOTOX build failures blocking publication.
- Remove the seed and transferred lifestage implementation from ComptoxR after destination parity passes. Update affected tests, readiness lists, help, and release notes through the normal release process.
- **Gate:** new and old databases work without the derived dictionary, and neither default path returns either derived column.

### 5. Coordinate the transition (1-1.5 days)

- Make a versioned destination artifact available before the ComptoxR breaking release.
- Publish a before/after migration example: query ECOTOX with ComptoxR, obtain its recorded release ID, then call the external harmonizer with that ID. Test the example against the installed packages.
- Inventory affected public database downloads and their sidecars, including rolling and versioned assets. Preserve mapping evidence, hashes, source history, and scientific decisions in `envharmonizer`. Do not publish a legacy derived database asset or delete users' local databases.
- After the harmonizer replacement is published and verified, release the breaking ComptoxR update through the normal workflow, publish the source-only database, then withdraw the inventoried old public database assets and their sidecars. Preserve unrelated release assets. Require client updates and a local Plumber restart; old clients are not supported against the replacement database. Verify current downloads contain no derived tables and withdrawn assets are no longer available. Prevent scheduled or older build workflows from republishing derived databases.
- Force the first source-only rebuild even when the ECOTOX release ID is unchanged. Check downloader and build-gate behavior so it cannot mistake different builder schemas for identical artifacts. Use the existing workflow `force` input and build-version mechanism where sufficient; add a schema marker only if required by a failed replacement test.
- **Gate:** the updated client, matching local server, old local databases, and new source-only databases pass the source-only tests; the explicit harmonization example passes. The migration notice names both removed derived fields, the removed argument, required updates, and server restart. Record publication and withdrawal evidence.

### Parallel work and release dependencies

The harmonizer transfer and source-only ComptoxR preparation can run in parallel in separate repositories or worktrees after the baseline and output contract are fixed. A coordinator owns integration, shared files, publication, and asset withdrawal. Preparation does not permit early release: publish and verify `envharmonizer` before releasing derivation removal or withdrawing downloads.

Lifestage is the first migration priority. Toolkit preparation can run independently, but toolkit parity must pass before endpoint-policy migration. Hook execution remains in ComptoxR. Coordinate later endpoint edits to `R/eco_functions.R` with the integrated source-only work, including its direct `eco_burl` reader and database-path routing. See `HANDOFF.md` for file ownership and the endpoint plan for configuration behavior.

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
| Migration and release | New clients work with old local and new source-only DBs; removed-argument calls fail; local HTTP matches direct results after restart; same-source-release rebuilds are forced. Published replacement checksums match, old public derived DB assets are withdrawn, and scheduled builds cannot restore them. |
| Scale | A large fixture with repeated descriptions does not multiply rows or cause per-row matching/provider work. Measure the changed join, not unrelated pipeline work. |
| AMOS regression | Existing AMOS tests and table hashes remain unchanged when adding lifestage. Repeat relevant installed-package checks after the direct rename. |

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
| Old clients download new source-only rolling DB | Require updates in the breaking-release notice. Publish and verify the harmonizer first, then release the client and source-only DB and withdraw old derived downloads. No public legacy DB remains. |
| Existing source terms have redistribution restrictions | Verify authoritative terms for each actual source before publishing transferred evidence. |
| Rename changes package identity | No downstream compatibility package is required. Rename directly in a separate commit, preserve AMOS behavior, and verify installed-package access. |

The estimated effort covers extraction, parity, offline artifacts, and the coordinated ComptoxR change. It excludes journal submission, reviewer waiting time, an ontology redesign, retroactive re-analysis of user studies, and an unbounded downstream audit. Missing pinned inputs or publication access can extend the schedule; ownership of the shipped localhost server is settled.

## Assessment validation

The original assessment checked local source, build scripts, tests, and the AMOS release implementation. This revision checks the agreed decisions against the existing assessment, current ECOTOX result and shipped Plumber code, and database workflow. A documentation diff check passed. Runtime tests were not run because this change edits only a planning document. All programmatic gates above are future implementation requirements, not claimed results.
