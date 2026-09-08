# Production endpoint migration

Toolkit parity passed before endpoint edits. The installed wrapmaint archive
hash is pinned in `dev/toolkit-lock.json`; independent package check was OK.
The extraction comparison covered 387 files with zero contract differences.

Production snapshots were acquired from the approved services. Alerts and
Hazard downloads returned HTTP 502; their existing approved snapshots were
retained. Acquisition records and raw hashes are frozen in the coordinator's
`.migration-evidence/production/acquisition.csv`. JSON object keys use radix
ordering so schema maintenance is independent of runner locale.

Shared resolution now uses option, environment, then default. Package loading
does not set endpoint variables. Explicit URLs and local database paths remain
valid. Stale database connections close when the effective target changes.
Obsolete numeric choices and automatic non-production fallback hooks are gone.

Verification before final cleanup:

- Focused offline suite: 598 passes, zero failures/warnings, 36 declared skips.
- Full offline suite: 4,760 passes, zero failures, 48 declared skips. Four
  warnings report dependencies built under newer R versions (jsonlite, dplyr,
  purrr, here). The baseline reported the same four warnings.
- Additional database acceptance cases from commit `8dbd5d7`: 57 passes;
  fixture hashes unchanged. Tests are integrated in this branch.
- Rebuilt production generation check: only protected/unchanged actions.
- Hook validation: 37 functions, 111 hooks, 34 extra parameters; passed.
- Air passed. Jarl reported 28 existing style/dynamic-hook findings in touched
  files; no broad unrelated style changes were made.

Manual review then found `chemi_safety()` calls a route absent from production.
That operation is removed; its original source is preserved outside the public
checkout. The remaining manual helpers use approved production operations,
approved Dashboard-specific paths, Natural Products, or local/configuration
logic.

Final local gates after removal:

- Readiness: 4,727 passes in the main lane, 66 in the state-sensitive lane;
  zero failures, 48 declared external/database skips, four known dependency
  build-version warnings. The readiness command completed successfully.
- Expanded source package: 1,206 text files passed the boundary scan.
  `R CMD check --no-manual`: Status OK, zero errors, warnings, and notes.
  The Windows session-information helper emitted a separate Quarto invocation
  warning after check completion; the validation process exited zero.
- Rendered pkgdown site: 504 text files passed the boundary scan. Existing
  NEWS heading formatting produced a pkgdown warning; normal release rebuilds
  NEWS through the existing release workflow.
- Final generation check: no writes or removals. The adapter copies `air.toml`
  and CI pins Air 0.9.0. All 38 formatter-only wrapper changes preserve parsed R.
- Separate local package: deterministic generation, containment checks, and
  installed mocked HTTP passed without ComptoxR or wrapmaint in its library.
  Frozen alerts supports nine operations and reports eight unsupported ones.
- Fifty-four development/staging schema files were removed only after SHA-256
  matched their copies outside the repository. See `local-input-hashes.csv`.
- `removed-exports.csv` records removed names and production replacements;
  `production-acquisition.csv` records approved acquisition URLs and raw hashes.

Remote toolkit archive retrieval, clean-checkout CI, releases, and database
withdrawal remain coordinator gates. The envharmonizer publication gate passed
before all source-only release actions.
