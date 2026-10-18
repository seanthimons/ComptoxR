# Released v41 integration

Root integration of 53 operations on official Specmill v0.1.41, source
`05862bee1804806cea157ff1962300d741516301`:

- Six PaDEL, RDKit and WebTEST descriptor GET/POST bindings.
- The actual list-name facade, with combined formatting and original raw hook params.
- EPI specification and JAR distribution reads.
- Forty metadata/version GETs across twenty Chemi schemas.
- Four CheT direct reads.

The per-schema ledger reaches 361/548. It counts native ownership and behavior
coverage, not universal deployed service availability. No ComptoxR push.

`verify.R` reproduces official helper provenance, validated whole-client
freshness and ownership checks, then the legacy test inventory. Launch R with
TMPDIR on persistent storage. The parent used
`/home/sxthi/.cache/comptoxr-specmill-finish/tmp` after the shared tmpfs filled.

Final validated apply and independent freshness checks passed, with all 590
owned artifacts unchanged and every ownership hash matching. Operation, mapping,
retained-output and drift diagnostics are empty. Retained-route warnings remain
visible in generation-freshness.txt.

## Behavior and package gates

The initial focused root replay passed 1,607 assertions. The later fixture/export
registration assertion initially preceded its helper definition; that test-only
ordering error was corrected. The complete CheT direct suite then passed 150
assertions, including the two added assertions. The retained PubChem and search/
safety suites passed 77 and 58 root assertions respectively. They preserve and
explain blockers; they do not count as migrations.

The broad CRAN-safe run executed 787 tests, with 7,781 passing assertions, zero
failed expectations, zero warnings, 50 expected skips and one error in that same
subsequently corrected registration assertion. `full-safe-results.csv` retains
the exact result. The corrected file was independently replayed successfully;
this is not represented as a clean single full-suite run. External HTTP was
blocked and localhost allowed. Missing optional databases account for skips.

The package gate after declaring the generated pagination companion's existing
`digest::digest()` dependency finished with 0 errors, 0 warnings, 0 notes. Tests,
examples, vignettes and manual generation were excluded from that package gate;
tests were exercised separately as above. The earlier package gate's sole
warning was the missing digest declaration, retained in
`package-before-dependency-fix.rds`.

Both initial freshness and full-test attempts hit ENOSPC while a package build
copied development artifacts into /tmp. Their failure evidence is retained;
they are not passing runs. The retry package used a 9 MB source snapshot with
package sources, docs, data, tests and installed resources, omitting development
artifacts. No active library was modified during cleanup.

## Live limits

All 40 metadata/version routes returned meaningful production responses without
error payloads. Six descriptor operations returned actual descriptor data.
EPI /api returned the 14-path specification; JAR byte preservation is controlled
localhost evidence, not a production JAR download. CheT temporary chemical
lookup still returns 500. Production hazard and alerts remain unavailable;
staging evidence and rejected controls remain recorded in the preceding wave.

Mordred and WebTEST prediction bindings remain retained in this checkpoint.
Their existing hook-route warnings are preserved. Independent follow-up work
addresses the client-owned Mordred NULL-cell defect; no such formatter change
is included in these 53 operations. Held CheT search, search/safety facades and
PubChem wrappers remain unchanged. New management and reviewed CheT download
candidates belong to the following root iteration and are excluded here.
