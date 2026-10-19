Title: Review chemi_toxprints_bulk payload, service and authentication contract before native migration

`chemi_toxprints_bulk(query)` is retained during PR345 migration. Specmill issue181's chunk support is now officially released in0.1.50; the remaining problem is a ComptoxR client-contract decision under#311.

Affected operation: POST `/api/toxprints`, canonical `schema/chemi-toxprints-prod.json`, public wrapper in `R/chemi_toxprints.R`. The GET sibling `chemi_toxprints(smiles, headers=FALSE, profile=NULL)` already uses the native generated implementation in that same file and must remain intact.

The bulk wrapper calls:

```r
generic_request(query=query, endpoint='toxprints', method='POST',
                batch_limit=as.numeric(Sys.getenv('batch_limit','100')))
```

It inherits `server='ctx_burl'`, `auth=TRUE`, and `tidy=TRUE`. Thus its default target is `https://comptox.epa.gov/ctx-api/toxprints`, with `x-api-key`, and each cleaned chunk is encoded as a top-level JSON array, for example `["DTXSID7020182"]`.

The canonical Cheminformatics schema instead declares an object `ToxprintsRequest` with `chemicals: array<string>`, optional `options` and `profile`, and operation path `/api/toxprints`. A canonical request would be `{"chemicals":["DTXSID7020182"]}` against the Cheminformatics service. Selecting that body/service and omitting inherited CTX auth changes existing observable behavior, so migration must not silently repair it. The old array fails the unchanged canonical runtime object validator before HTTP. No schema edits or validation bypass are needed for the canonical object.

A private official-v50 candidate preserves the public `query` formal, normalization and environment chunk limit using supported `batch.input: query`, with a pure per-chunk canonical object projection. ValidationTRUE generation/freshness and localhost tests distinguish both wire contracts. No production calls were made for this review. This candidate is evidence, not an adopted migration or service-success claim.

Decide the intended service/auth/payload contract in a separate behavior-repair change. If canonical behavior is chosen, preserve input cleanup, public formals, chunk-size defaults, collected tidy output, API response observation, typed failures and native hard401/config behavior. Prove legacy/canonical differences explicitly and validate the actual service separately when authorized. Keep the owned GET bytes and ownership record unchanged when editing the shared R file.
