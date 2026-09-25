# Specmill public API client rebuild (#325)

Work stays on `feat/specmill-migration-pilot`. Deletion experiments run only in
detached worktrees under the ignored `dev/specmill-pilot/artifacts/rebuild-<commit>/`.
Toolkit pin: specmill `f41eeb9bae628eeb1f0fee16227f5ee8373a7ae2`, archive SHA-256
`b2d3eecdb82d7dfd4fc1944197f4f4df904a0b032afb1756951cf7b2c7c8299d`. Air 0.11.0.

## Preservation inventory (#326)

`Rscript dev/specmill-rebuild/inventory.R` parses every top-level definition in
`R/` and writes [inventory.json](inventory.json): file, export status, category,
review reason, mapped operation, lifecycle badge, and deparsed formals. It also
writes [removal-allowlist.json](removal-allowlist.json), which lists whole files
with SHA-256 hashes.

| Export category | Exports |
| --- | ---: |
| generated (specmill-owned) | 101 |
| retained_mapped (fixed contract, existing implementation) | 4 |
| unmapped_wrapper (open review in #310–#314) | 246 |
| runtime (request helpers, hook registry/hooks, startup, server setters) | 20 |
| sidecar (DSSTox/ECOTOX/ToxVal local databases) | 26 |
| utility | 11 |
| re-exported `%>%` | 1 |
| **Total** | **409** |

The inventory categorizes exports by source file and mapping, not by name
prefix. As a result, `chemi_server()` and `epi_server()` are classified as
runtime, not endpoint wrappers. They are two of the 248 functions in #310 and
stay retained as runtime configuration. The other 246 functions remain open for
review.

The allowlist is derived from the generated operation mappings and the specmill
manifest. It contains the 93 whole files that hold the 101 generated wrappers.
A file is allowlisted only if every top-level definition in it is generated.
The script stops if a generated file has a retained or unaccounted neighbor.
The three retained files (`R/ct_chemical_detail_search.R`,
`R/ct_chemical_list_all.R`, and `R/chemi_search.R`) are excluded.

Preservation check: after rebuilding in the worktree, `git status --porcelain`
must be empty. That compares every tracked file byte for byte, including runtime
code, hooks, sidecars, `man/`, `NAMESPACE`, tests, fixtures, and the manifest.
Because the files are identical, exports, signatures, documentation, and
lifecycle badges are unchanged.

## Rehearsal of the existing 101 wrappers (#327)

`Rscript dev/specmill-rebuild/rehearse.R` (clean committed checkout) does the following:

1. Creates a detached worktree at `HEAD` and links the pinned toolkit library.
2. Checks each allowlisted file hash, then deletes exactly those 93 files.
3. Runs `dev/generate_specmill.R --apply`, then `--apply` again, then `--check`.
   After each step, `git status` must show no difference.

Result at `71ca1678`: 93 files removed and 101 operations regenerated. All three
steps were byte-identical. The planner printed the existing informational
relative-server-URL notes; they are not diagnostics.

Runtime verification of the rebuilt worktree, installed into
`artifacts/rebuild-library`:

```bash
COMPTOXR_CRAN_SAFE_TESTS=true NOT_CRAN=false Rscript -e 'testthat::test_local(filter="^(contract-.*|generic_request_edge|hooks_stage_server|chemi_search|ct_chemical_list_all_hooks)$", stop_on_failure=TRUE)'
Rscript dev/specmill-full/verify-runtime.R artifacts/before-library artifacts/rebuild-library artifacts/rebuild-runtime
```

The fixed contract, request-edge, and hook tests all passed. All 459 installed-client
localhost cases passed against the original `4fd720b9` client, with no candidate
failures. No output was promoted: the rebuilt files are identical to the branch.

Rollback: revert the `dev/specmill-rebuild/` commits. The package is untouched.
