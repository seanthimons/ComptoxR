# WebTEST exports and safety ownership, released v42

Candidate for PR345 from fixed parent `3ea6140c`. Add `apis/chemi-webtest-exports.yml` to the integrating root's services and run official generation to register ownership there. This candidate intentionally leaves root `specmill.yml`, `.specmill/manifest.json`, the pin, helpers, global progress and HANDOFF untouched. The full-client proof has its own generated manifest in `~/.cache/comptoxr-specmill-finish/proof`.

Two new canonical operation bindings:

- `schema/chemi-webtest-prod.json` POST `/api/webtest/predict/export`, `chemi_webtest_predict_export(body)`.
- `schema/chemi-webtest-prod.json` POST `/api/webtest/export-append`, `chemi_webtest_export_append(body = NULL)`.

Both use official generated `.ct_request` wrappers and the existing server resolver. No existing facade is replaced or aliased. Requests are JSON and multipart respectively. The multipart `predictionRequest` part is JSON and optional `file` accepts binary bytes or an explicit upload object. Tests send only to a real localhost server, including file bytes with NUL and 255. No deployed request or upload is made.

The safety canonical GET `/api/alerts/render` remains an existing ownership hold, not an additional binding or a new hold. Its parameters and server equal alerts, but safety declares `*/*` response media while alerts declares PNG/SVG. Loading both in the existing owning service fails duplicate-contract comparison. Pinned source evidence explains why declared routes cannot fix this. No source correction, duplicate alias or helper patch is used. Existing `chemi_alerts_render` stays unchanged. Safety rqcodes #352 is outside this change.

Upstream follow-up: https://github.com/seanthimons/specmill/issues/61#issuecomment-6254632814

PR345 cross-link: https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6254640424

Reproduce from this worktree, with the pinned versioned toolkit library available read-only at the parent repository's absolute path:

```sh
mkdir -p /home/sxthi/.cache/comptoxr-specmill-finish/tmp
export TMPDIR=/home/sxthi/.cache/comptoxr-specmill-finish/tmp
Rscript dev/specmill-rebuild/webtest-exports/generate.R
Rscript dev/specmill-rebuild/webtest-exports/audit-safety.R
Rscript dev/specmill-rebuild/webtest-exports/test.R
Rscript dev/specmill-rebuild/webtest-exports/verify.R
```

`generate.R` archives only the fixed parent into the persistent cache and copies this service config into it. It applies with `validation = TRUE`, generates docs, refreshes provenance, then checks freshness with validation enabled. The proof manifest and source hashes are checked by `verify.R`; existing canonical schemas, R files and public wrappers retain their bytes. `verification.json`, `tests.json`, `localhost-wire.rds`, `safety-ownership.json` and `pinned-source-evidence.json` record the results. No full package build/check, deployed mutation, push, or safety rqcodes integration is part of this candidate.

Whole-client validation reports the existing OAS 3.1 GET request-body interoperability warning from the parent configuration. This candidate changes no GET request-body mapping. The focused test suites report zero warnings.

The execution completed both official apply passes and the validated freshness check, then the runner hit a trailing parse error because its file was edited while R was still reading it. The saved freshness plan was retained in the cache. A stable finalization replay parsed all evidence scripts, copied the official outputs, checked the two namespace additions and completed `verify.R` successfully. The recorded freshness and hash results come from that completed check and replay; the interrupted runner is not described as a clean end-to-end script execution.
