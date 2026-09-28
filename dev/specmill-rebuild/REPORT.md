# Specmill public API client rebuild (#325)

Work stays on `feat/specmill-migration-pilot`. Deletion experiments run only in
detached worktrees under the ignored `dev/specmill-pilot/artifacts/rebuild-<commit>/`.
Toolkit pin: specmill v0.1.8 `2df2657b7f3576ef7af8072c21ed6b1f6aa9ce8c`, archive SHA-256
`6085d39a0d02822fabd870916e697065294f597238592c51bccaea2fc05b8091`. Air 0.11.0.

## Preservation inventory (#326)

`Rscript dev/specmill-rebuild/inventory.R` parses every top-level definition in
`R/` and writes [inventory.json](inventory.json): file, export status, category,
review reason, mapped operation, lifecycle badge, and deparsed formals. It also
writes [removal-allowlist.json](removal-allowlist.json), which lists whole files
with SHA-256 hashes.

| Export category | Exports |
| --- | ---: |
| generated (specmill-owned) | 225 |
| retained_mapped (fixed contract, existing implementation) | 4 |
| unmapped_wrapper (retained with recorded reason, #310–#314) | 122 |
| runtime (request helpers, hook registry/hooks, startup, server setters) | 20 |
| sidecar (DSSTox/ECOTOX/ToxVal local databases) | 26 |
| utility | 11 |
| re-exported `%>%` | 1 |
| **Total** | **409** |

The inventory categorizes exports by source file and mapping, not by name
prefix. As a result, `chemi_server()` and `epi_server()` are classified as
runtime, not endpoint wrappers. They are two of the 248 functions in #310 and
stay retained as runtime configuration. Counts are after the three adopted waves
below; the original tranche was 101 generated and 246 unmapped.

The allowlist is derived from the generated operation mappings and the specmill
manifest. It now contains the 204 whole files that hold the 225 generated wrappers
(originally 93 files for 101 wrappers).
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

## Specmill v0.1.6 and stable generation (#310)

The toolkit is pinned to v0.1.6, which fixes stable-wrapper generation.
Stable wrappers are generated normally, and the badge comes from the mapping
(`docs: {lifecycle: ...}`). Nothing is marked `implementation: existing`,
nothing was badged by hand, and no generated file was edited. Re-running the
schema audit at 0.1.6 gave the same 53 parser blockers and 102 fixture failures
as 0.1.4. Only the CHET collision reason text changed, and it now has more
detail. The re-audit output was not committed.

v0.1.8 renders data-literal defaults and examples as plain R
([seanthimons/specmill#53](https://github.com/seanthimons/specmill/issues/53))
and adds `propose_mappings()` and `verify_adoption()`
([seanthimons/specmill#54](https://github.com/seanthimons/specmill/issues/54)).
Re-pinning changed no generated wrapper: `--apply` only updated the manifest's
`toolkit_version`, and the 204-file rehearsal stayed byte-identical.

## Generation waves (#310, #311, #314)

`Rscript dev/specmill-rebuild/wave.R <name>` screens every unmapped export and
stages mechanical candidates in a detached worktree. It stops if the generated
wrappers change any roxygen output. `dev/specmill-rebuild/verify-wave.sh <name>`
does the rest:

- retires superseded legacy tests;
- re-runs `--check`;
- installs the candidate;
- runs the contract, request-edge, and hook tests;
- compares the installed original `4fd720b9` client with the candidate on localhost.

A wave is adopted only when all of the following hold:

- generation is idempotent;
- roxygen, `man/`, `NAMESPACE`, and lifecycle lines are unchanged;
- formals are identical;
- the before/after interfaces are equal;
- there are zero candidate failures.

| Wave | Operations | Localhost cases | Commit |
| --- | ---: | ---: | --- |
| hazard-pilot | 5 | 489 | `77de2d69` |
| stable-batch | 67 | 834 | `0fb6f4d5` |
| options-batch | 52 | 1015 | `b851a6cd` |
| vector-examples | 14 | 1099 | `30a4dc49` |
| hooks | 5 | 1113 | `b5bccc97` |

The options-batch wave covers wrappers with an optional `options <- list();
if (!is.null(x)) options$k <- x` prelude, which is mapped to specmill
`compact_object`. Each candidate is called with the option inputs omitted,
explicit, `FALSE`, and `0`, and with no arguments at all. Every call must reach
the helper exactly as the original does. On localhost, the requests are
observed and compared between the original and generated clients, not
modelled.

The vector-examples wave maps a `c()` of scalar literals in an example to a
sequence example. At 0.1.6 it was rejected because specmill rendered it as
`base::evalq(c(...), envir = base::baseenv())`, which changed the Rd examples.
At 0.1.8 the Rd output is unchanged. The wave adopts the nine `*_bulk`
wrappers and five siblings that were retained only because they share a file
with one of them.

## Defects found in the original client (#329, #330; not fixed here)

- Paginated `generic_request` wrappers send only the first query of a batch.
  Queries 2..n are dropped. The runtime batch probe is skipped for these
  wrappers, and the before/after snapshots keep the original behavior.
- `chemi_stdizer_records` and `chemi_toxprints_assays_bulk` overwrite their
  public `options` argument with a locally built list. They are retained.
- `chemi_chet_reaction_batchsearch` evaluates its missing arguments in a
  different order from its signature, so a generated wrapper would give a
  different missing-argument error. It is retained.

## Dispositions (#310–#314)

`Rscript dev/specmill-rebuild/dispositions.R` covers all 248 checklist exports
and writes [dispositions.json](dispositions.json) and
[DISPOSITIONS.md](DISPOSITIONS.md). Each generated export records its service,
operation key, file, and wave. Each retained export records:

- the screen reason;
- the helper route (method and endpoint);
- the supported and blocked audit records on that route, with code, reason,
  pointer, and issue;
- any file siblings;
- for hooked wrappers, the hook chain, with the file that defines each hook and
  the stages the wrapper actually invokes.

| Issue | Generated | Retained | Client utility |
| --- | ---: | ---: | ---: |
| #310 | 87 | 19 | 3 |
| #311 | 50 | 43 | 0 |
| #312 | 4 | 22 | 0 |
| #313 | 0 | 16 | 0 |
| #314 | 2 | 2 | 0 |

Reasons for keeping an export retained:

- no unique supported schema route (44), including the ambiguous-media and
  malformed-route blockers in #313;
- a hand-written implementation (18);
- an inseparable grouped file (16);
- a request built by a pre-request hook (12);
- description prose that needs a manual mapping (6);
- a nonliteral helper argument (2);
- a computed default (1, `chemi_hazard`);
- a candidate whose no-argument call differs (1);
- the original defects above.

A retained function is a valid completion state. No contract is guessed.

## Hooks (#312)

`wave.R` now screens hooked wrappers against `inst/hook_config.yml`. It
recognises the generated hook pattern: a pre-request call with `skip_request`
and `params` write-back, an optional `chemicals` binding from
`{from: [hook_state, params, chemicals]}`, and an optional `post_response`
call. The stages in the body must match `hook_config`. Staged services set
`hook_config: inst/hook_config.yml`. Comparisons run the real hooks in the
package namespace, with the helper stubbed. Resolver calls get a found item, a
tibble response, and an empty result (the skip path).

The hooks wave generated 5 of the 28 hooked wrappers:
`ct_chemical_list_search_by_name`, `epi_ecosar_dye`,
`epi_ecosar_polymer_nonionic`, `epi_ecosar_surfactant_nonionic`, and
`epi_submit`. `epi_submit` first failed on formals because `write_yaml`
truncated `theta = 0.00010836` to 7 significant digits. The wave now writes
YAML with `precision = 15`.

The other 23 stay client-owned:

- 12 descriptor and webtest wrappers build the request inside a pre-request
  hook, so no route is guessed;
- 6 resolver and stdizer wrappers match the hook pattern but need manual
  description mapping;
- 4 have no unique supported route (`chemi_alerts`, `chemi_hazard_bulk`,
  `chemi_toxprints_calculate_bulk`, `ct_similar`);
- `chemi_hazard` has a computed `format = c(...)` default.

## Full rebuild rehearsal (#328)

Scope is frozen at the 409 exports in [inventory.json](inventory.json), and
each one is classified. The rehearsal ran `rehearse.R` at `b64adbf8`
(specmill 0.1.8) with the expanded allowlist. In a detached worktree, it
removed the 217 allowlisted files. Regeneration, a second `--apply`, and
`--check` were each byte-identical, and `git status` stayed empty. The rebuilt client was then
installed into `artifacts/rebuild-final-library` and checked two ways:

- The contract, request-edge, and hook tests passed.
- All 1113 localhost cases (409 exported signatures) matched the original
  `4fd720b9` client, with no candidate failures.

No output was promoted: the rebuilt tree is identical to the branch.

Rollback: revert the wave commits (`77de2d69`, `0fb6f4d5`, `b851a6cd`,
`30a4dc49`, `b5bccc97`) to
restore the hand-written files and legacy tests. Revert the other
`dev/specmill-rebuild/` commits to remove the tooling.
