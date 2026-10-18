ComptoxR PR345: https://github.com/seanthimons/ComptoxR/pull/345

Official released Specmill 0.1.42, source b17a0856263e0179a164a9673399f221168cda6d, supports permissive explicit-client fan-out through #166, but an explicit client input still cannot be split into chunks when the selected operation has an object body.

Affected facade: `chemi_toxprints_bulk(query)`, POST `/api/toxprints`, `schema/chemi-toxprints-prod.json`. Its existing implementation calls `generic_request(query, endpoint = 'toxprints', method = 'POST', batch_limit = as.numeric(Sys.getenv('batch_limit', '100')))`. It cleans duplicate/NA/blank inputs, sends JSON arrays in chunks and formats the complete collected response. It also inherits CTX server/auth defaults. These legacy payload/server mismatches are client defects to review separately; this report does not propose changing the canonical schema into an array.

Minimal mapping on the canonical operation:

```yaml
inputs:
  query: {type: any, required: true}
normalize_inputs:
  query: .ct_legacy_query
batch:
  max_items: {env: batch_limit, default: 100}
  split: true
  on_error: {single: stop, multiple: drop}
request:
  arguments:
    body: {from: [params, query]}
```

`specmill::generate_client(..., artifacts = 'wrappers', validation = TRUE)` rejects this before emission:

```
batch.split requires batch.max_items on a top-level array request body: held-toxprints-bulk POST /api/toxprints
```

A supported explicit client chunk-input seam would also permit projecting each chunk into a canonical object body. Scalar `fan_out` cannot preserve a configured chunk size of two or more. Please retain the original full normalized input for response policy and expose the complete chunk through `params`, matching the released explicit-client fan-out support. No helper/executor patches or alternate wrappers were adopted. The original facade remains unchanged pending an official release and client-contract review.

The complete isolated config is `dev/specmill-rebuild/released-facades-v42/held-bulk.yml` on the ComptoxR migration branch. For reproduction, substitute a pure body callback/object projection if desired; the rejection depends on the canonical object body and explicit split, not the proposed array serialization. No live request is needed.
