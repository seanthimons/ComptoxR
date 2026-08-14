# PRD: Reseed ECOTOX lifestage patch for release `ecotox_ascii_06_11_2026`

## Context

A fresh install fails with **"Release mismatch in lifestage patch seed."** The pre-built
database and the shipped package disagree on the ECOTOX release:

| Artifact | ECOTOX release |
|---|---|
| `db-latest` → `ecotox.duckdb` (built 2026-07-02) | `ecotox_ascii_06_11_2026.zip` |
| Installed `ComptoxR` (1.5.0 rolling / 1.5.1) → `inst/extdata/ecotox/lifestage_patch_seed.csv` | `ecotox_ascii_03_12_2026.zip` |
| `dev/lifestage/source/lifestage_baseline.csv` | `ecotox_ascii_03_12_2026.zip` |

The lifestage patch requires the seed's `ecotox_release` to be `identical()` to the
DB's `_metadata.ecotox_release`. The pre-built DB moved to the **June 11** dump; every
shipped package still carries the **March 12** seed. No package build with a June seed
exists — this is a maintainer publishing gap, not an end-user error.

The mismatch guard (`R/eco_lifestage_patch.R:1136`) exists specifically to catch the case
where a newer ECOTOX release introduced lifestage vocabulary the seed does not cover.

## Goal

Determine whether `ecotox_ascii_06_11_2026` introduced **new uncovered lifestage terms**,
and produce a release-matched `lifestage_patch_seed.csv` so a fresh install works cleanly.

## Success criteria

1. A definitive answer: does June 11 add any lifestage terms absent from the March baseline?
2. If **no new terms**: `lifestage_patch_seed.csv` (and `source/lifestage_baseline.csv`) are
   restamped to `ecotox_ascii_06_11_2026.zip`, and a fresh `.eco_patch_lifestage()` run
   against the June 11 DB completes without the mismatch abort.
3. If **new terms**: they are resolved/curated, the seed is rebuilt, and
   `Rscript -e "devtools::test(filter='eco_lifestage')"` passes.
4. All work on a dedicated branch in a worktree — **the current checkout is untouched**.

## Constraints & environment

- **Do not touch the current working tree.** Create a git worktree in a sibling directory
  (e.g. `../ComptoxR-lifestage-reseed/`), branched from the current feature tip
  (`feat/schema-stage-provenance-and-server-swap`) — not from a stale base.
- R 4.5.1 at `C:\Program Files\R\R-4.5.1\bin\Rscript.exe`.
- June 11 `ecotox.duckdb` is already installed at
  `tools::R_user_dir("ComptoxR","data")/ecotox.duckdb`. Do **not** re-download or rebuild it.
- The **only** shipped lifestage artifact is `inst/extdata/ecotox/lifestage_patch_seed.csv`.
  Everything under `dev/lifestage/` is maintainer-only input, not installed.
- Never commit to `main`. No git tags. No Claude/agent attribution in commits.

## Plan

### Phase 0 — Cheap probe (no network, ~1 min) — GO/NO-GO GATE

Compare the distinct lifestage terms in the June 11 DB against the committed March baseline.
This alone answers the user's question.

```r
"C:/Program Files/R/R-4.5.1/bin/Rscript.exe" -e '
  library(DBI)
  p <- file.path(tools::R_user_dir("ComptoxR","data"), "ecotox.duckdb")
  con <- dbConnect(duckdb::duckdb(), p, read_only = TRUE)
  meta <- dbReadTable(con, "_metadata")
  stopifnot(meta$value[meta$key=="ecotox_release"] == "ecotox_ascii_06_11_2026.zip")
  db_terms <- dbGetQuery(con, "SELECT DISTINCT description FROM lifestage_codes ORDER BY description")$description
  dbDisconnect(con, shutdown = TRUE)
  base <- read.csv("dev/lifestage/source/lifestage_baseline.csv", check.names = FALSE)
  new_terms <- setdiff(db_terms, unique(base$org_lifestage))
  dropped   <- setdiff(unique(base$org_lifestage), db_terms)
  cat("DB terms:", length(db_terms), "| baseline terms:", length(unique(base$org_lifestage)), "\n")
  cat("NEW in June 11 (", length(new_terms), "):\n", paste(new_terms, collapse="\n"), "\n\n", sep="")
  cat("DROPPED since March (", length(dropped), "):\n", paste(dropped, collapse="\n"), "\n", sep="")
'
```

- **Verify:** the printed list of new terms.
- If `new_terms` is **empty** → skip to Phase 2A (trivial restamp).
- If `new_terms` is **non-empty** → these are the candidate uncovered lifestages; go to Phase 1.

Record the full new/dropped lists in the final report either way.

### Phase 1 — Full live refresh (only if Phase 0 found new terms; ~15-20 min, needs network)

Re-resolve the June 11 term set through the 6-source pipeline and surface what cannot be
auto-resolved.

```
Rscript dev/lifestage/refresh_baseline.R
```

- Needs network for OLS4, NVS, Wikidata, AGROVOC; `BIOPORTAL_API_KEY` is optional
  (graceful degradation). If the environment has no network, **stop and report** — do not
  fake results.
- Regenerates `source/lifestage_baseline.csv` (now stamped June 11) + `source/lifestage_derivation.csv`,
  and writes `dev/lifestage/lifestage_resolution_review.csv`.
- **Verify:** capture the printed coverage line (`N resolved, N ambiguous, N unresolved`)
  and the `needs_review` warning list.

Then attempt the seed rebuild:

```
Rscript dev/lifestage/rebuild_lifestage_patch_seed.R
```

- This **aborts** if any new unresolved term is missing from
  `dev/lifestage/curation/lifestage_curation_queue.csv`. **That abort list is the concrete
  set of uncovered lifestages requiring a curation decision.**
- For each, add a row to the curation queue with an appropriate `proposed_action`
  (`accept_unresolved`, `requery`, `force_candidate`, `force_unresolved`, `change_derivation`) —
  see `dev/lifestage/README.md` for field requirements. Do **not** invent ontology IDs;
  prefer `accept_unresolved` / `force_unresolved` with reviewer notes when a confident
  mapping is not available, and flag those for human sign-off in the report.
- Re-run `rebuild_lifestage_patch_seed.R` until it writes the seed cleanly.

### Phase 2 — Materialize & validate

**2A (no new terms — trivial restamp):** update the `ecotox_release` value to
`ecotox_ascii_06_11_2026.zip` in both `dev/lifestage/source/lifestage_baseline.csv` and,
via a clean `Rscript dev/lifestage/rebuild_lifestage_patch_seed.R` run, in
`inst/extdata/ecotox/lifestage_patch_seed.csv`. Regenerate the seed through the script —
do **not** hand-edit the shipped CSV's release column in isolation.

**2B (both paths converge):** patch a local copy and run tests.

```r
devtools::load_all(".")
.eco_patch_lifestage(refresh = "baseline")   # must NOT hit the mismatch abort
```
```
Rscript -e "devtools::test(filter='eco_lifestage')"
```

- **Verify:** `.eco_patch_lifestage()` completes; `lifestage_dictionary` + `lifestage_review`
  materialize; the eco_lifestage test filter passes.
- Run `air format` + `jarl check` on any edited R (only `refresh_baseline.R` output CSVs and
  curation queue are expected to change — no R source edits should be needed).

### Phase 3 — Land

- Commit the regenerated `inst/extdata/ecotox/lifestage_patch_seed.csv`, the refreshed
  `dev/lifestage/source/*` CSVs, and any `curation/lifestage_curation_queue.csv` additions.
  Conventional commit, e.g. `fix(lifestage): reseed patch for ecotox_ascii_06_11_2026`.
- Open a PR against the integration branch (per the repo's feature→integration→main model).
- **Do not** run the DB or package publish workflows — that is a separate maintainer step.

## Out of scope

- Downloading or rebuilding `ecotox.duckdb`.
- Publishing `db-latest` / `package-latest`, cutting a release, or bumping DESCRIPTION.
- Rolling the DB back to a March build (a valid alternative fix, but not this task).
- The `COMPTOXR_ECOTOX_ALLOW_PATCH_SEED_REUSE` escape hatch — this PRD produces a real
  release-matched seed instead.

## Deliverable report

State plainly: (1) how many new/dropped lifestage terms June 11 introduced, (2) whether any
were genuinely uncovered and how each was curated, (3) test results, (4) the branch/PR, and
(5) any curation decisions that need human sign-off before merge.
