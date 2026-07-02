# ECOTOX Lifestage Data Maintenance

This directory contains maintainer-only inputs, provenance, and scripts for the
lifestage patch data shipped with ComptoxR.

End users install one ECOTOX lifestage artifact:

```
inst/extdata/ecotox/lifestage_patch_seed.csv
```

That seed is release-matched and materializes `lifestage_dictionary` plus
`lifestage_review` in a local ECOTOX DuckDB. Live ontology/provider resolution is
not an end-user patch path.

## Layout

| Path | Purpose |
|------|---------|
| `source/` | Maintainer source CSVs used to rebuild the seed |
| `provenance/` | Generated evidence and adjudication CSVs |
| `curation/lifestage_curation_queue.csv` | Human review queue for unresolved or disputed lifestages |
| `rebuild_lifestage_patch_seed.R` | Rebuilds the installed seed from source and curation inputs |
| `refresh_baseline.R` | Maintainer-only live/provider refresh for a new ECOTOX release |

## Normal Curation Workflow

1. Edit `dev/lifestage/curation/lifestage_curation_queue.csv`.
2. Run:
   ```
   Rscript dev/lifestage/rebuild_lifestage_patch_seed.R
   ```
3. Review the unresolved summary printed by the script.
4. Patch a local database with:
   ```r
   devtools::load_all(".")
   .eco_patch_lifestage(refresh = "baseline")
   ```
5. Run the lifestage tests:
   ```
   Rscript -e "devtools::test(filter='eco_lifestage')"
   ```

The rebuild script fails if new unresolved terms are absent from the curation
queue, if queue actions use unknown values, if `force_candidate` rows lack source
and derivation fields, or if unresolved decisions lack reviewer notes.

## Queue Actions

Allowed `proposed_action` values:

- `accept_unresolved`
- `requery`
- `force_candidate`
- `force_unresolved`
- `change_derivation`

Use `requery` for terms that need a future provider refresh before policy is
final. Use `force_candidate` only when the source ontology ID, label,
harmonized stage, and reproductive flag are known.

## Release Refresh

For a new ECOTOX release, maintainers can run `refresh_baseline.R` to regenerate
`dev/lifestage/source/lifestage_baseline.csv` and derivation proposals. After
curation, run `rebuild_lifestage_patch_seed.R` to produce the only installed
package CSV.
