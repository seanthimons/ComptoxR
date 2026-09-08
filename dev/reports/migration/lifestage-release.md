# Lifestage migration release evidence

## Published replacement

The private source repository is now `seanthimons/env-harmonizer`. PR 20 passed
CI and merged as `72a41ae372b616efcbaea96b4dfd4373fc581de8`. Source implementation
`d540441` produced the frozen package. The original local CONTEXT.md edit remains.

Experimental package and data release:
https://github.com/seanthimons/envharmonizer-releases/releases/tag/v0.1.0

The coordinator downloaded all 11 payload files and verified SHA-256 against
SHA256SUMS. An unauthenticated package download also matched
`4afe80e6d806fcb0279a93c159e9e7ce5c0d4cbdaca6fa36304d0579a914c6b0`.
See `envharmonizer-published-checksums.json`. Independent installation into a
separate library passed offline mapping, AMOS hashes/APIs, and rendered help.
Original and copied transfer files matched every hash in the published evidence
archive's source inventory. Only then were 37 transferred files removed here.

Experimental mappings; not independently reviewed. Users must assess suitability
for their analysis. See the release attribution, review record and manifest.

## Integrated client and database

Worker commits `4e57637`, `dd13ff8` were reviewed and integrated locally as
`a03879c`, `cceb4b7`. Worker source checks: 62 passes, no failures or skips;
installed-directory checks: 28 passes, one declared maintainer-source skip.
The coordinator's focused integration check passed, with nine local-database
skips; deterministic database, HTTP, and both builder fixtures ran.

The coordinator then built from the frozen actual EPA archive and appendix,
without provider refresh or user database access. The resulting source-only
database has 1,242,356 results and passed publication checks. Input and output
SHA-256 values are in `source-build-hashes.csv`. The first build reported 13
warnings without detail. The installed-tarball builder repeat also passed with
1,242,356 results. Its output hashes are in `source-only-installed-hashes.csv`.
The 13 warnings are native-encoding transliteration warnings under the C locale;
each is recorded in `source-only-installed-warnings.txt`.

An installed-package example ran outside the checkout against this database.
It queried 664 records, read the recorded release from `_metadata`, and applied
envharmonizer explicitly. All source rows/columns were preserved. No native
lifestage description was absent from both the dictionary and review artifact.

Tarball inspection found that the pre-existing unanchored `build.R` exclusion
removed the shipped builders. It is now `^build[.]R$`. The rebuilt source
tarball includes `inst/ecotox/ecotox_build.R`, installs successfully, and
excludes transferred implementation/seed and internal planning files.

`Rscript dev/cran_readiness.R` passed: 4,851 assertions, 48 skips, no test failures
or warnings. Two dependency build-version warnings occurred outside tests.
The skipped cases require external services, credentials, local databases, or
optional external integrations. The migration's deterministic HTTP/build tests
are additional to these skipped cases. Both changed articles rendered, including
the explicit mapping example and required client/server update and restart.

## Release controls and remaining checks

The old ECOTOX workflow ID `306098499` is verified `disabled_manually`, with no
active runs, after replacement publication. The new source-only workflow has
a separate path and checks out `main`. Its upload guard rejects derived tables.
Offline checks prove the existing force input rebuilds a same-release artifact
and the downloader retrieves replacement bytes without a source-version cache.
The source-only database workflow must run with `force=true` for the first release.

The source tarball passed `R CMD check --no-manual --no-build-vignettes`
with `Status: OK` under the CRAN-safe test environment. The two changed articles
were rendered separately. ComptoxR's normal release workflow, source-only database upload,
download verification and old asset withdrawal are still pending. No database
asset has been withdrawn. Do not treat local artifact checks as publication.
