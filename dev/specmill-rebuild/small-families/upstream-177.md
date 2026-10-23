Additional PR345 operation affected on official released v0.1.41: proposed `chemi_opera_file`, POST `/api/opera/file`, canonical `schema/chemi-opera-prod.json`.

There is no previous public wrapper. The schema contract is a required multipart `file` plus query `format="json"` and boolean `standardize=false`. Validated official generation emits the multipart body correctly but passes the scalar boolean directly to `query` without serialization metadata. Actual localhost HTTP capture for both values shows:

```
POST /api/opera/file?format=json&standardize=FALSE
POST /api/opera/file?format=json&standardize=TRUE
Content-Type: multipart/form-data; boundary=...
```

Expected query boolean tokens are lowercase `false` and `true`. The multipart body contains the original `CCO ethanol\n` input. No production/staging call or upload was made, and no deployed rejection is claimed.

Minimal reproduction using the officially emitted wrapper and unchanged native helper:

```r
chemi_opera_file(standardize = FALSE,
  body = list(file = charToRaw("CCO ethanol\n")))
```

Configure `ComptoxR.chemi_burl` to a localhost httpuv server and record `QUERY_STRING`/`rook.input$read()`. Portable proof, frozen official output and real wire evidence will be committed under `dev/specmill-rebuild/small-families/{reproduce-held-opera.R,held-opera.R.txt,held-opera-wire.rds}` in ComptoxR. This operation stays unbound until the fix is released and the parent pin updated; no helper patch or request callback workaround. Blocks https://github.com/seanthimons/ComptoxR/pull/345.
