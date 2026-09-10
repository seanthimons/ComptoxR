# specmill migration

The development toolkit is specmill 0.1.4. The exact source commit, immutable
archive, and SHA-256 are recorded in dev/toolkit-lock.json. Install it with
dev/install_toolkit.R.

Project configuration, callback/report policy, fixed-fixture paths, ownership
records, generated headers, maintainer commands, and CI now use specmill.
The manifest's old ownership hashes were verified before the mechanical rename;
operation ownership was retained. New names were applied to all active paths.

Verification on Windows, 2026-09-10:

- All 345 client R source files retained identical parsed code after the rename.
- Maintenance tests: 922 assertions passed, no failures, warnings, or skips.
- Installed client: 343 fixed contract tests passed without the toolkit in its
  runtime libraries, with no load-time HTTP or option changes.
- Public parity: 603 signatures and 451 help pages checked against the migration
  baseline, retaining the five previously approved rendered-help corrections.
- Generation check and second apply made no changes. All four maintainer commands
  passed from outside the client root: stubs, tests, hooks, and public boundary.
- No API schemas or recorded HTTP cassettes were changed. The 24 renamed RDS
  fixtures retain their original contents.

Historical evidence in this directory records the names and releases used at
the time. CONTRIBUTING.md and dev/ENDPOINT_EVAL_UTILS_GUIDE.md are current.
