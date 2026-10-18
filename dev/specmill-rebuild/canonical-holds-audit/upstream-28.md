Additional route-specific archived-source evidence for ComptoxR PR345.

POST `/api/stdizer/groups/preflight`, canonical `schema/chemi-stdizer-prod.json`, is held for required binary query `files[]`. No public wrapper currently exists. Official generation diagnoses that declaration; it does not establish multipart by itself.

The already archived production asset `https://hcd.rtpnc.epa.gov/js/app.2b8197a6.js`, SHA256 `dc6443e91da0ceef29f7f930cbb91671003cc3a8c983d77cbbc0bce4ca7754dd`, supplies the missing route-specific caller evidence:

- At byte 456342, Standardizer's `FileUploadDialog` sets `preflight-url` to `${e.STDIZER_URL}/groups/preflight` and `upload-url` separately to `${e.STDIZER_URL}/groups`.
- At byte 102839, that dialog's watcher creates FormData, appends every file as `files[]` with its filename, then posts only that FormData to `this.preflightUrl`.

Reproduce offline by searching those literals in the archived asset and comparing POST `/api/stdizer/groups/preflight`'s sole required binary-query parameter. This mirrors the separately evidenced services preflight correction, without inferring contracts from route names.

A scoped isolated candidate now replaces only this operation's binary-query declaration with a required multipart body containing required repeated binary `files[]`. The canonical snapshot stays verbatim; the separate reviewed subset retains response reference closure and the explicit production resolver. On official released v0.1.42, validation TRUE, generation/freshness, all four independent ownership hashes and actual localhost multipart tests pass. The focused suite passes 45 assertions, including raw/form_file bytes, validation before HTTP, response media, typed HTTP errors and real transport failure. No deployed upload, mutation, auth or session call was performed. This is source-contract evidence using existing released capability, not a new generator gap or a deployed success claim. The inactive candidate and per-operation audit are under ComptoxR `dev/specmill-rebuild/canonical-holds-audit/`; root integration/coverage credit remain separate.

Other caller evidence is insufficient for wider adoption: group create/add and universal harvest append `request = JSON.stringify(...)` as a string form part, leaving their typed metadata-part contracts unresolved. Protocol POST shows page/size, but no sort encoding or corresponding GET proof. Existing #28/#31 holds remain separate.

Blocks and candidate report target: https://github.com/seanthimons/ComptoxR/pull/345. No duplicate issue or upstream fix.
