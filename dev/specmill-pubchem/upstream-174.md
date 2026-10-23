ComptoxR PR345: https://github.com/seanthimons/ComptoxR/pull/345. Released Specmill v0.1.41, exact source `05862bee1804806cea157ff1962300d741516301`, git archive SHA256 `70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.

Affected public wrappers/files:
- `R/pubchem_search.R`: GET `/compound/{namespace}/{query}/cids/JSON` for name/inchikey/formula; POST `/compound/{namespace}/cids/JSON` with form field smiles or inchi.
- `R/pubchem_properties.R`: GET `/compound/cid/{cid}/property/{properties}/JSON`; POST `/compound/cid/property/{properties}/JSON` with comma-separated cid form field.
- `R/pubchem_synonyms.R`: GET `/compound/cid/{cid}/synonyms/JSON`; POST `/compound/cid/synonyms/JSON` with comma-separated cid form field.

No existing PUG REST schema/config in ComptoxR. Authoritative source: https://pubchem.ncbi.nlm.nih.gov/pcfe/docs/markdown/pug-rest.md. A separate reviewed minimal source/candidate is being recorded under `dev/specmill-pubchem/`; canonical schema snapshots remain unchanged.

The old wrappers maintain `.ComptoxREnv` session caches. Search validates type/query, then returns a cached tibble before server resolution, request construction or forcing transport defaults. Properties/synonyms coerce/validate CIDs, partition cached versus uncached IDs, choose GET when exactly one uncached CID remains or sequential POST batches of 100 otherwise, update per-CID caches and combine cached entries before fresh entries. Duplicates and cache-hit ordering matter. Search caches empty results too, so a repeated missing result does not issue HTTP or repeat its warning. Properties cache keys include the sorted property set; synonyms cache raw information and project tidy output afterward.

Minimal original behavior:
```r
# With ComptoxR loaded and a successful first call:
pubchem_search("aspirin")
options(ComptoxR.pubchem_burl = "")
pubchem_search("aspirin") # same tibble, zero HTTP, no missing-server error
# For a partially warm property cache:
pubchem_properties(1L, properties = "XLogP")
pubchem_properties(c(2L, 1L), properties = "XLogP")
# Only GET cid=2 is sent; cached CID=1 precedes fresh CID=2 in the result.
```

Released configuration has no cache setting or cache-aware prepare/return/partition stage. Its operation settings reject:
```r
specmill:::validate_settings(list(cache = list(enabled = "cache")), "PubChem")
# Error: PubChem: unknown field cache
```
`result_formatter` only runs after transport/iteration and cannot prevent a request or select batches from the uncached remainder. Operation `prepare` is a development callback, not runtime state. An invented pre_request/post_response hook chain would replace the wrappers' public hook lifecycle, and side-effectful request/response callbacks would hide caching/orchestration in handwritten code. Both are disallowed for this migration. Batch preflight #166/#167 alone does not supply this cache lifecycle. Separate unbatched formatter limitation is already #157.

Please provide a generator-owned cache lifecycle that can express whole-call early returns and per-CID cache partitioning before routing/batching, cache stores after decoding, and final projection using original public inputs. Preserve validation/default forcing order and original errors/warnings/attributes. Existing wrappers remain unchanged until a supported released implementation is available. No helper/executor patch or fake hooks adopted.
