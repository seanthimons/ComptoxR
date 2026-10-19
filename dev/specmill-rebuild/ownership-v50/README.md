# Official 50 ownership candidate

This isolated candidate covers canonical GET/POST `/api/descriptors` through existing `chemi_descriptors` and `chemi_descriptors_bulk`, and safety's shared GET `/api/alerts/render` through existing `chemi_alerts_render`. It adds no public alias, signature, schema correction or handwritten runtime change.

Official Specmill 0.1.50 source is `064478735580b54a732e3859b066b317e72d53a1`; independent archive/tag/library verification is in `../release50-verification/`. The private helper is the official emitted scaffold. The snapshot includes root authentication metadata, preserving render's explicit empty auth context; its runtime AST is identical to the original.

Validation and behavior evidence:

- `evidence/generation.json`: validation TRUE for all four canonical sources, wrapper/manual freshness, all 637 private owner hashes, exact official helper; two descriptor routes retain primary and RDKit fallback provenance. Shared render selects alerts' PNG/SVG response contract explicitly and records both canonical contracts/hashes.
- `evidence/portable-localhost.json`: final 116 actual HTTP assertions, zero failures/errors/warnings/skips, rerun after auth alignment. JSON wide/raw, exact requests and observers, empty/invalid inputs, typed failures/hard credential behavior, fallback, PNG/SVG/204 are covered.
- `evidence/parity-tests.json`: 569 native/frozen assertions, zero failures/errors/warnings/skips. Missing-argument checks ignore only R interpreter internal evalError/getvarError subclasses while preserving missingArgError, message and zero HTTP.
- `evidence/hook-tests.json`: 98 existing hook assertions unchanged, all green. `evidence/public-preservation.json` verifies both original descriptor signatures and identical render runtime AST.
- `evidence-v49/live-verification.json`: four previously saved bounded read-only production calculation controls (old/new GET and POST), all HTTP 200 and identical one-row 1024-descriptor output, warnings and RDKit fallback provenance. No further live calls are needed.

An existing CSV/TSV bug remains: the original unchanged `validate_descriptor_response` treats a decoded data.frame as an error-field list and raises `undefined columns selected`. Both candidates preserve the same typed post-hook failure after correct delimited decoding. See `evidence-v49/retained-csv-limitation.json`; this candidate does not claim CSV success or repair the hook. Prior49 diagnostic attempts are retained under evidence-v49/. The official50 combined apply/check is the final freshness evidence in evidence/final-check.log.

Import using `import-plan.json` and `management.patch`. The full isolated `render.yml` must not replace the full root management configuration. Copy config, callback, selected manuals and portable test/fixture files only. Parent must preserve and move the complete unowned original grouped descriptor file out of R before official generation emits both functions; the original is archived here with SHA256 `4e714d13138b9e93fa7812e0beb9c09ec341c97d6a7ceaea406347ba91a4e1c5`. Existing render is owned and stays in place. Do not copy private ownership metadata, generated wrapper bodies or unrelated manuals into root.

The extended native-calculation fixture preserves the original six definitions and adds both descriptors. Existing descriptor hook tests remain unchanged; no fixed descriptor contract test files exist to retire. Root functions are already exported. Update only the two descriptor bespoke-test registry fields to the new actual HTTP suite.

Reproduction from repository root uses persistent TMPDIR and the scripts here: `prepare.R`, `generate.R`, `iterate.R`, `final-check.R`, `verify-runtime.R`, `run-portable.R`, `run-parity.R`, `run-hooks.R`. prepare.R resets the isolated snapshot and therefore must not run concurrently with any private generation. Parent owns root adoption, pin/scaffold, public apply/check, ledger changes and broader package validation. No root tracked files or libraries were changed by this replay. Official50 installation is owned by its verification agent.

No deployed calls are authorized for this replay. live.R is an archived reproduction script only; do not run it. Saved prior live controls remain under evidence-v49/.

Final50 result: all 783 requested assertions passed; full validation/freshness passed with 637 owner hashes. The final-check log retains a cosmetic inherited `final49` label; generation.json asserts actual installed version/source 0.1.50/064478735580b54a732e3859b066b317e72d53a1.
