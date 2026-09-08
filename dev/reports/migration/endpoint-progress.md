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
logic. Final suite, package/site scans, toolkit archive retrieval, release,
and database withdrawal remain coordinator gates.
