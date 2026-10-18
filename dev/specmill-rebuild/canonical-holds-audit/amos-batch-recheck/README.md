# AMOS batch contract recheck

On 18 October 2026 at 22:14 UTC, the exact JSON examples in the archived corrected OAS3 staging source were replayed against production and staging. These are read-only workbook searches; no upload, session or deployed mutation occurred. Request bodies, origins, timestamps, source hash, response media and byte hashes are recorded individually. Response files retain exact bytes.

- Production analytical batch: HTTP200, workbook with atrazine DTXSID9020112 and four AQC records.
- Staging analytical batch: HTTP200, workbook with five AQC records.
- Staging general batch: HTTP200, workbook with 816 atrazine records.
- Production general batch: HTTP500, HTML error. No workbook claim.

workbook-review.json records the worksheet rows and source values decoded directly from the XLSX XML with the Python standard library. This new evidence supersedes the earlier all-500 service observation. It does not certify the existing public wrappers: they send a generic Chemical envelope, use ids rather than identifiers, and expect JSON. Public argument names/defaults can be retained in a separately recorded contract repair, but the wire and successful return would change. User contract clarification is pending; root adoption remains held.

To replay one archived request, extract `.request` from the corresponding JSON record and POST it with Content-Type application/json to its recorded origin plus path. The request is the service source example, including its placeholder base_url; generated workbook links consequently retain that placeholder. This proof does not claim usable frontend links.
