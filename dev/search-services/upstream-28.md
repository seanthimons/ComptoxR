ComptoxR PR345 follow-up on v0.1.41, source `05862bee1804806cea157ff1962300d741516301`.

Scope: `schema/chemi-services-prod.json`, POST `/api/services/{caspreflight,files,preflight,universalpreflight}`. These four operations have no existing public wrappers; proposed names are `chemi_services_caspreflight`, `chemi_services_files`, `chemi_services_preflight`, and `chemi_services_universalpreflight`. The canonical records still declare required `files[]` as a query array of binary strings; `/files` additionally declares required query object `request: FilesUploadRequest`.

Read-only production source evidence retrieved 2026-10-18: `https://hcd.rtpnc.epa.gov/js/app.2b8197a6.js`. Its AddChemicals component wires FileUploadDialog to `/api/services/preflight` and `/api/services/files`; the shared dialog appends each actual File with `FormData.append("files[]", file, file.name)`. Its preflight caller posts that FormData. The universal dialog separately wires `/api/services/universalpreflight` and also appends actual files to FormData. A separately named, self-contained derivative for just the two evidenced preflight corrections is undergoing full schema validation and actual localhost raw/form_file byte testing. No production/staging uploads or sessions were used.

Remaining holds:

- `caspreflight`: no route-specific deployed caller found. A similarly named operation or shared dialog is insufficient evidence; the binary-query review stays unresolved.
- `files`: source establishes FormData files plus `request = JSON.stringify({filesInfo: ...})`, appended as a string. The canonical query-object declaration is therefore not a faithful frontend wire description. However, backend acceptance of an application/json object part versus this string form part is not established. Specmill's supported typed multipart object encoding uses application/json; changing the source object to a string would lose the existing FilesUploadRequest field validation without another reviewed input contract. No alternative wrapper or unvalidated string escape hatch has been added.

Minimal reproduction: inspect the named public asset for `this.files.forEach(t=>e.append("files[]",t,t.name)),this.$axios.post(this.preflightUrl,e)` and `e.append("request",JSON.stringify({filesInfo:`. Compare to the four unchanged canonical `parameters` arrays. The two remaining operations should remain blocked by this issue pending route-specific file/metadata input evidence.

Blocks https://github.com/seanthimons/ComptoxR/pull/345. Portable excerpts, exact semantic diff, source hashes, isolated generation and localhost evidence will accompany the ComptoxR child commit. This comment does not claim the service executed an upload.
