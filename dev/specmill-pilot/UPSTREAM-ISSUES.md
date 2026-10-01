# Migration blockers and source corrections

The 27 canonical production files declare 548 operations: 495 parse individually and 53 remain contract-blocked or unsupported. 1 whole-service parse is also blocked by a duplicated operation ID. Of the individually parsed canonical routes, 25 have invalid default examples; minimal mode fails for 27, including two empty-multipart fixture limitations. The four legacy snapshots are counted separately below.

The legacy generator selects the 27 canonical hyphenated production files. Four underscore-named CTX files are legacy snapshots and are audited separately, not additional production services. These results describe source bytes and offline native fixtures, not production behavior or compatibility of existing ComptoxR wrappers. Only declared source types and values determine invalid-example findings; domain plausibility and generated client documentation examples are not evaluated.

| Source group | Files | Declared routes | Individually parsed | Parser blockers | Default failures | Minimal failures |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| canonical_production | 27 | 548 | 495 | 53 | 25 | 27 |
| legacy_snapshot | 4 | 140 | 140 | 0 | 25 | 25 |

## What to fix next

- Service contracts block #26, #27, #28 and #31. Confirm media, corrected parameter names/types, file representation and nested-query serialization for each affected route before generation. Do not infer wire formats from schema names or development observations. #29 GET-body handling remains unsupported; OAuth #4 is outside this work.
- Invalid examples need source-example corrections, not endpoint or serialization changes. Most failures provide JSON-looking text where the declared body is an array; publish an actual JSON array example. The image GSID path example is numeric while its parameter type is string; confirm the contract and publish a matching example. Both default and minimal failures remain visible. No substitute fixtures were selected.
- CHET repeats an operationId across two OPTIONS routes. Upstream should assign unique operation IDs. A reviewed client naming override could resolve naming locally, but this audit did not invent one. Each declared route was parsed independently with an exact include key to reveal its fixture diagnostics; whole-service parsing remains blocked.
- A mixed generation selection containing a parser-blocked route fails atomically. Record diagnostics first and explicitly scope generation to independently supported routes. This audit makes no fallback requests.
- Two CHET uploads pass default fixtures but fail minimal fixtures because all fields are optional while the multipart body is required. Omitting all fields creates an unencodable empty form. This is a minimal-fixture limitation, not an invalid selected example or parser rejection. Ask the service owner whether a field is required; keep tested explicit inputs separately if using these routes.

## Fixture modes

| Mode | Pass | Fail |
| --- | ---: | ---: |
| default | 585 | 50 |
| minimal | 583 | 52 |

Minimal mode omits optional inputs and reduces coverage. It cannot repair an invalid required example. Explicit overrides were not used. No type/enum contradiction was observed in this corpus; the JSON inventory keeps parser fixture diagnostics separately if future schemas introduce them.

## Contract blockers by stable route

| Schema | Method and path | Issue | Diagnostic / upstream action | Source pointer |
| --- | --- | --- | --- | --- |
| `chemi-alerts-prod.json` | `POST /api/alerts` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1alerts/post/parameters/0/schema` |
| `chemi-alerts-prod.json` | `POST /api/alerts/groups` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1alerts~1groups/post/parameters/0/schema` |
| `chemi-alerts-prod.json` | `POST /api/alerts/groups/{id}/add` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1alerts~1groups~1{id}~1add/post/parameters/1/schema` |
| `chemi-alerts-prod.json` | `POST /api/alerts/groups/{id}/replace` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1alerts~1groups~1{id}~1replace/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/add_aqc_spectrum/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1add_aqc_spectrum~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_fact_sheet/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1add_new_fact_sheet~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_method/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1add_new_method~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_product_declaration/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1add_new_product_declaration~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_safety_data_sheet/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1add_new_safety_data_sheet~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/all_similarities_by_dtxsid/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1all_similarities_by_dtxsid~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/analytical_qc_batch_search` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1analytical_qc_batch_search/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/analytical_qc_keyset_pagination/{limit}` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1analytical_qc_keyset_pagination~1{limit}/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/batch_search` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1batch_search/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/count_substances_in_ids/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1count_substances_in_ids~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/dtxsids/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1dtxsids~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/entropy_similarity/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1entropy_similarity~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/fact_sheet_keyset_pagination/{limit}` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1fact_sheet_keyset_pagination~1{limit}/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `GET /api/amos/get_similar_structures/{identifier_type}/{identifier}` | #27 | Unmatched path parameter: dtxsid Make parameter names match actual path placeholders. | `#/paths/~1api~1amos~1get_similar_structures~1{identifier_type}~1{identifier}/get/parameters/0` |
| `chemi-amos-prod.json` | `GET /api/amos/list_sources_by_record_type/{record_type}` | #27 | Missing path parameter: record_type Declare the actual path placeholder and its type/allowed values. | `#/paths/~1api~1amos~1list_sources_by_record_type~1{record_type}` |
| `chemi-amos-prod.json` | `POST /api/amos/mass_range_search/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1mass_range_search~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/mass_spectra_for_substances/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1mass_spectra_for_substances~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/mass_spectrum_similarity_search/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1mass_spectrum_similarity_search~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/max_similarity_by_dtxsid/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1max_similarity_by_dtxsid~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/method_keyset_pagination/{limit}` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1method_keyset_pagination~1{limit}/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/next_level_classification/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1next_level_classification~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/product_declaration_keyset_pagination/{limit}` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1product_declaration_keyset_pagination~1{limit}/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/record_counts_by_dtxsid/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1record_counts_by_dtxsid~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/retrieve_fact_sheets/` | #27 | Invalid input schema type Correct invalid declared types; nested files need a supported upload contract. | `#/paths/~1api~1amos~1retrieve_fact_sheets~1/post/parameters/0/type` |
| `chemi-amos-prod.json` | `POST /api/amos/retrieve_product_declarations/` | #27 | Invalid input schema type Correct invalid declared types; nested files need a supported upload contract. | `#/paths/~1api~1amos~1retrieve_product_declarations~1/post/parameters/0/type` |
| `chemi-amos-prod.json` | `POST /api/amos/retrieve_safety_data_sheets/` | #27 | Invalid input schema type Correct invalid declared types; nested files need a supported upload contract. | `#/paths/~1api~1amos~1retrieve_safety_data_sheets~1/post/parameters/0/type` |
| `chemi-amos-prod.json` | `POST /api/amos/safety_data_sheet_keyset_pagination/{limit}` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1safety_data_sheet_keyset_pagination~1{limit}/post/parameters/1/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/search_for_document_ids/{record_type}` | #27 | Invalid input schema type Correct invalid declared types; nested files need a supported upload contract. | `#/paths/~1api~1amos~1search_for_document_ids~1{record_type}/post/parameters/1/type` |
| `chemi-amos-prod.json` | `POST /api/amos/spectral_entropy/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1spectral_entropy~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/spectrum_count_for_methodology/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1spectrum_count_for_methodology~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/substances_for_classification/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1substances_for_classification~1/post/parameters/0/schema` |
| `chemi-amos-prod.json` | `POST /api/amos/substances_for_ids/` | #26 | Ambiguous body media type Declare service-owned consumes/media and body representation. | `#/paths/~1api~1amos~1substances_for_ids~1/post/parameters/0/schema` |
| `chemi-hazard-prod.json` | `POST /api/hazard` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1hazard/post/parameters/0/schema` |
| `chemi-resolver-prod.json` | `POST /api/resolver/casharvest` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1resolver~1casharvest/post/parameters/0/schema` |
| `chemi-resolver-prod.json` | `GET /api/resolver/ghs-list-count` | #29 | OAS 3.1 GET request body requires an explicit operation body_media review GET-body route remains unsupported (#29); upstream must clarify its supported contract. | `#/paths/~1api~1resolver~1ghs-list-count/get/requestBody` |
| `chemi-resolver-prod.json` | `POST /api/resolver/safety-flags` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1resolver~1safety-flags/post/parameters/0/schema` |
| `chemi-resolver-prod.json` | `POST /api/resolver/universalharvest` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1resolver~1universalharvest/post/parameters/0/schema` |
| `chemi-services-prod.json` | `POST /api/services/caspreflight` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1services~1caspreflight/post/parameters/0/schema` |
| `chemi-services-prod.json` | `POST /api/services/files` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1services~1files/post/parameters/0/schema` |
| `chemi-services-prod.json` | `POST /api/services/preflight` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1services~1preflight/post/parameters/0/schema` |
| `chemi-services-prod.json` | `POST /api/services/universalpreflight` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1services~1universalpreflight/post/parameters/0/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1stdizer/post/parameters/0/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1stdizer~1groups/post/parameters/0/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups/preflight` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1stdizer~1groups~1preflight/post/parameters/0/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups/{id}/add` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1stdizer~1groups~1{id}~1add/post/parameters/1/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups/{id}/replace` | #28 | Binary parameter requires source contract review (#16) Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1stdizer~1groups~1{id}~1replace/post/parameters/1/schema` |
| `chemi-stdizer-prod.json` | `GET /api/stdizer/protocols/{id}` | #31 | Unsupported nested parameter object Specify nested-query field names and exact serialization, including arrays. | `#/paths/~1api~1stdizer~1protocols~1{id}/get/parameters/6/schema` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/protocols/{id}` | #31 | Unsupported nested parameter object Specify nested-query field names and exact serialization, including arrays. | `#/paths/~1api~1stdizer~1protocols~1{id}/post/parameters/1/schema` |
| `chemi-toxprints-prod.json` | `POST /api/toxprints/calculate` | #28 | Binary parameter requires source contract review (#16); Unsupported nested parameter object Specify file location, representation, media and relation to metadata. | `#/paths/~1api~1toxprints~1calculate/post/parameters/0/schema` |

## Independent defects masked by the first parser error

Correcting a primary blocker alone does not resolve these additional defects. Source bytes were hash-matched to the independent inspection in `schema-results.json`.

| Schema | Method and path | Issue | Input | Additional defect | Source pointer |
| --- | --- | --- | --- | --- | --- |
| `chemi-alerts-prod.json` | `POST /api/alerts` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1alerts/post/parameters/1` |
| `chemi-alerts-prod.json` | `POST /api/alerts/groups/{id}/add` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1alerts~1groups~1{id}~1add/post/parameters/2` |
| `chemi-amos-prod.json` | `POST /api/amos/add_aqc_spectrum/` | #27 | `body` | Invalid input schema type | `#/definitions/NewAnalyticalQCSpectrum/properties/file/type` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_fact_sheet/` | #27 | `body` | Invalid input schema type | `#/definitions/NewFactSheet/properties/file/type` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_method/` | #27 | `body` | Invalid input schema type | `#/definitions/NewMethod/properties/file/type` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_product_declaration/` | #27 | `body` | Invalid input schema type | `#/definitions/NewDocument/properties/file/type` |
| `chemi-amos-prod.json` | `POST /api/amos/add_new_safety_data_sheet/` | #27 | `body` | Invalid input schema type | `#/definitions/NewDocument/properties/file/type` |
| `chemi-hazard-prod.json` | `POST /api/hazard` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1hazard/post/parameters/1` |
| `chemi-resolver-prod.json` | `POST /api/resolver/casharvest` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1resolver~1casharvest/post/parameters/1` |
| `chemi-resolver-prod.json` | `POST /api/resolver/safety-flags` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1resolver~1safety-flags/post/parameters/1` |
| `chemi-resolver-prod.json` | `POST /api/resolver/universalharvest` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1resolver~1universalharvest/post/parameters/1` |
| `chemi-services-prod.json` | `POST /api/services/files` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1services~1files/post/parameters/1` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1stdizer/post/parameters/1` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1stdizer~1groups/post/parameters/1` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/groups/{id}/add` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1stdizer~1groups~1{id}~1add/post/parameters/2` |
| `chemi-stdizer-prod.json` | `GET /api/stdizer/protocols/{id}` | #31 | `pageable` | Unsupported nested parameter object | `#/paths/~1api~1stdizer~1protocols~1{id}/get/parameters/6` |
| `chemi-stdizer-prod.json` | `POST /api/stdizer/protocols/{id}` | #31 | `pageable` | Unsupported nested parameter object | `#/paths/~1api~1stdizer~1protocols~1{id}/post/parameters/1` |
| `chemi-toxprints-prod.json` | `POST /api/toxprints/calculate` | #31 | `request` | Unsupported nested parameter object | `#/paths/~1api~1toxprints~1calculate/post/parameters/1` |

## Invalid fixture examples by stable route

Each row below fails in both default and minimal mode. Canonical production and legacy snapshot rows are labeled separately; legacy repetitions are not new production defects. The machine-readable report contains individual mode results, JSON values, JSON types, declared types and exact pointers. Required inputs remain required.

| Schema | Method and path | Input | Source value and type | Declared type | Source pointer |
| --- | --- | --- | --- | --- | --- |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/assay/search/by-aeid/` | body required | `"[\"111\",\"3032\"]"` (string) | `array` | `#/paths/~1bioactivity~1assay~1search~1by-aeid~1/post/requestBody/content/application~1json/example` |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/data/aed/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1aed~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/data/search/by-aeid/` | body required | `"[\"3032\",\"755\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-aeid~1/post/requestBody/content/application~1json/example` |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/data/search/by-dtxsid/` | body required | `"[\"DTXSID9026974\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/data/search/by-m4id/` | body required | `"[\"7826737\",\"7834113\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-m4id~1/post/requestBody/content/application~1json/example` |
| `ctx-bioactivity-prod.json` canonical_production | `POST /bioactivity/data/search/by-spid/` | body required | `"[\"EPAPLT0232A03\",\"TP0000311A04\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-spid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/detail/search/by-dtxcid/` | body required | `"[\"DTXCID505\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1detail~1search~1by-dtxcid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/detail/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1detail~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/extra-data/search/by-dtxsid/` | body required | `"[\"DTXSID101296374\",\"DTXSID10612113\",\"DTXSID20635878\"]"` (string) | `array` | `#/paths/~1chemical~1extra-data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/fate/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1fate~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `GET /chemical/file/image/search/by-gsid/{gsid}` | gsid required | `20182` (number) | `string` | `#/paths/~1chemical~1file~1image~1search~1by-gsid~1{gsid}/get/parameters/0/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/property/experimental/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1property~1experimental~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/property/predicted/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1property~1predicted~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-chemical-prod.json` canonical_production | `POST /chemical/synonym/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1synonym~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/functional-use/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1functional-use~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/httk/search/by-dtxsid/` | body required | `"[\"DTXSID0027301\",\"DTXSID0027272\"]"` (string) | `array` | `#/paths/~1exposure~1httk~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/list-presence/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1list-presence~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/product-data/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1product-data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/seem/demographic/search/by-dtxsid/` | body required | `"[\"DTXSID00195506\",\"DTXSID0027301\"]"` (string) | `array` | `#/paths/~1exposure~1seem~1demographic~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-exposure-prod.json` canonical_production | `POST /exposure/seem/general/search/by-dtxsid/` | body required | `"[\"DTXSID00195485\",\"DTXSID00195400\"]"` (string) | `array` | `#/paths/~1exposure~1seem~1general~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-hazard-prod.json` canonical_production | `POST /hazard/cancer-summary/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1cancer-summary~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-hazard-prod.json` canonical_production | `POST /hazard/genetox/details/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1genetox~1details~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-hazard-prod.json` canonical_production | `POST /hazard/genetox/summary/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1genetox~1summary~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-hazard-prod.json` canonical_production | `POST /hazard/skin-eye/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1skin-eye~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx-hazard-prod.json` canonical_production | `POST /hazard/toxval/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1toxval~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/assay/search/by-aeid/` | body required | `"[\"111\",\"3032\"]"` (string) | `array` | `#/paths/~1bioactivity~1assay~1search~1by-aeid~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/data/aed/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1aed~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/data/search/by-aeid/` | body required | `"[\"3032\",\"755\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-aeid~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/data/search/by-dtxsid/` | body required | `"[\"DTXSID9026974\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/data/search/by-m4id/` | body required | `"[\"7826737\",\"7834113\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-m4id~1/post/requestBody/content/application~1json/example` |
| `ctx_bioactivity_prod.json` legacy_snapshot | `POST /bioactivity/data/search/by-spid/` | body required | `"[\"EPAPLT0232A03\",\"TP0000311A04\"]"` (string) | `array` | `#/paths/~1bioactivity~1data~1search~1by-spid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/detail/search/by-dtxcid/` | body required | `"[\"DTXCID505\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1detail~1search~1by-dtxcid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/detail/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1detail~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/extra-data/search/by-dtxsid/` | body required | `"[\"DTXSID101296374\",\"DTXSID10612113\",\"DTXSID20635878\"]"` (string) | `array` | `#/paths/~1chemical~1extra-data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/fate/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1fate~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `GET /chemical/file/image/search/by-gsid/{gsid}` | gsid required | `20182` (number) | `string` | `#/paths/~1chemical~1file~1image~1search~1by-gsid~1{gsid}/get/parameters/0/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/property/experimental/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1property~1experimental~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/property/predicted/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1property~1predicted~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_chemical_prod.json` legacy_snapshot | `POST /chemical/synonym/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1chemical~1synonym~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/functional-use/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1functional-use~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/httk/search/by-dtxsid/` | body required | `"[\"DTXSID0027301\",\"DTXSID0027272\"]"` (string) | `array` | `#/paths/~1exposure~1httk~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/list-presence/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1list-presence~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/product-data/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1exposure~1product-data~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/seem/demographic/search/by-dtxsid/` | body required | `"[\"DTXSID00195506\",\"DTXSID0027301\"]"` (string) | `array` | `#/paths/~1exposure~1seem~1demographic~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_exposure_prod.json` legacy_snapshot | `POST /exposure/seem/general/search/by-dtxsid/` | body required | `"[\"DTXSID00195485\",\"DTXSID00195400\"]"` (string) | `array` | `#/paths/~1exposure~1seem~1general~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_hazard_prod.json` legacy_snapshot | `POST /hazard/cancer-summary/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1cancer-summary~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_hazard_prod.json` legacy_snapshot | `POST /hazard/genetox/details/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1genetox~1details~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_hazard_prod.json` legacy_snapshot | `POST /hazard/genetox/summary/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1genetox~1summary~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_hazard_prod.json` legacy_snapshot | `POST /hazard/skin-eye/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1skin-eye~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |
| `ctx_hazard_prod.json` legacy_snapshot | `POST /hazard/toxval/search/by-dtxsid/` | body required | `"[\"DTXSID7020182\",\"DTXSID9020112\"]"` (string) | `array` | `#/paths/~1hazard~1toxval~1search~1by-dtxsid~1/post/requestBody/content/application~1json/example` |

## Minimal multipart fixture limitation

These routes pass native default fixtures. Minimal mode omits every optional property, leaving a required multipart body empty. Confirm whether the service requires a particular field and correct source requiredness only if confirmed. Do not invent fields to make minimal mode pass.

| Schema | Method and path | Mode | Diagnostic | Source pointer |
| --- | --- | --- | --- | --- |
| `chemi-chet-prod.json` | `POST /chemicals/newchemfile` | minimal | POST /chemicals/newchemfile (required body) Empty multipart forms cannot be encoded | `#/paths/~1chemicals~1newchemfile/post/requestBody` |
| `chemi-chet-prod.json` | `POST /reaction/newreactfile` | minimal | POST /reaction/newreactfile (required body) Empty multipart forms cannot be encoded | `#/paths/~1reaction~1newreactfile/post/requestBody` |

## Unparsed schema: chemi-chet-prod.json

Operation name collision; supply reviewed name overrides

Duplicate IDs block whole-service parsing. All routes below were also parsed and fixture-tested independently using their exact method/path include key, without naming overrides. Individual success does not remove the whole-service naming conflict.

| Colliding method and path | operationId | Source pointer |
| --- | --- | --- |
| `OPTIONS /reaction/batchsearch` | `api.reaction.map_dl_options` | `#/paths/~1reaction~1batchsearch/options/operationId` |
| `OPTIONS /reaction/map_DL` | `api.reaction.map_dl_options` | `#/paths/~1reaction~1map_DL/options/operationId` |

All affected routes:

| Method and path |
| --- |
| `GET /admin/database` |
| `GET /admin/errorreport` |
| `POST /admin/errorreport` |
| `GET /admin/login` |
| `POST /admin/login` |
| `GET /admin/register` |
| `POST /admin/register` |
| `GET /admin/resolve` |
| `POST /admin/resolve` |
| `GET /auth/errorpage` |
| `POST /auth/errorpage` |
| `GET /auth/errorpage/complete/{idnum}` |
| `POST /auth/errorpage/complete/{idnum}` |
| `GET /auth/errorpage/{showhide}` |
| `POST /auth/errorpage/{showhide}` |
| `GET /auth/login` |
| `POST /auth/login` |
| `GET /auth/logout` |
| `GET /auth/register` |
| `POST /auth/register` |
| `GET /auth/report` |
| `POST /auth/report` |
| `GET /auth/testpage` |
| `POST /auth/testpage` |
| `GET /chemicals/alias` |
| `GET /chemicals/chemdelete` |
| `POST /chemicals/chemdelete` |
| `GET /chemicals/chemical_DL` |
| `POST /chemicals/chemical_DL` |
| `GET /chemicals/chemset` |
| `GET /chemicals/chemtemp/{type}/{value}` |
| `GET /chemicals/counts` |
| `GET /chemicals/database` |
| `GET /chemicals/database-old` |
| `GET /chemicals/database/stats` |
| `GET /chemicals/maps` |
| `POST /chemicals/newchemfile` |
| `POST /chemicals/newchemical` |
| `GET /chemicals/singlechemical` |
| `GET /chemicals/suggest` |
| `POST /chemicals/template_DL` |
| `GET /chemicals/verify/{dtxsid}` |
| `GET /chemicals/{chemical_id}/image` |
| `POST /curators/change-password` |
| `GET /curators/detail-sets` |
| `POST /curators/details` |
| `POST /curators/libraries` |
| `GET /curators/libraries/detail-options` |
| `GET /curators/libraries/{lib_id}` |
| `PUT /curators/libraries/{lib_id}` |
| `POST /curators/login` |
| `POST /curators/logout` |
| `GET /curators/me` |
| `GET /curators/units` |
| `POST /curators/units` |
| `GET /metadata` |
| `OPTIONS /reaction/batchsearch` |
| `POST /reaction/batchsearch` |
| `GET /reaction/database` |
| `GET /reaction/database-old/{pagenum}/{searchterm}` |
| `GET /reaction/database/stats` |
| `GET /reaction/database_old` |
| `GET /reaction/dbcounts` |
| `GET /reaction/details` |
| `GET /reaction/download_DB_backup` |
| `POST /reaction/editor/check-existing` |
| `POST /reaction/editor/check-existing-map` |
| `GET /reaction/editor/library-details` |
| `POST /reaction/editor/load-map` |
| `POST /reaction/editor/load-reactions` |
| `POST /reaction/editor/save-scheme` |
| `GET /reaction/editor/{reaction_id}` |
| `POST /reaction/editor/{reaction_id}` |
| `GET /reaction/libraries` |
| `OPTIONS /reaction/map_DL` |
| `POST /reaction/map_DL` |
| `POST /reaction/mapfix/{map_id}` |
| `GET /reaction/mapid` |
| `DELETE /reaction/mappositions/{map_id}` |
| `GET /reaction/mappositions/{map_id}` |
| `GET /reaction/maps` |
| `POST /reaction/newlibrary` |
| `POST /reaction/newreactfile` |
| `POST /reaction/newreaction` |
| `GET /reaction/react_maps` |
| `POST /reaction/reaction_dl` |
| `POST /reaction/reactiondelete` |
| `GET /reaction/reactionmap` |
| `GET /reaction/search` |
| `GET /reaction/searchcounts/{search_input}/{search_type}` |
| `GET /reaction/singlereaction` |
| `GET /reaction/table` |
| `POST /reaction/template_DL` |
| `POST /reaction/visibility` |
| `GET /version` |

## Origin metadata, separate from request-contract blockers

Relative servers and absent Swagger host/scheme need an origin context. Existing ComptoxR helpers retain their configured service base URLs. These warnings do not make a route parser-unsupported, and this audit supplies no guessed hosts. Counts below cover parsed operations only.

| Source file | Affected parsed operations | Origin diagnostic |
| --- | ---: | --- |
| `chemi-alerts-prod.json` | 16 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-amnb_nate-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-amos-prod.json` | 45 | Swagger host/scheme requires a recorded origin or explicit base URL override |
| `chemi-arn_cats-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-chet-prod.json` | 95 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-descriptors-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-hazard-prod.json` | 16 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-mordred-prod.json` | 4 | Swagger host/scheme requires a recorded origin or explicit base URL override |
| `chemi-ncc_cats-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-opera-prod.json` | 6 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-padel-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-pfas_atlas-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-pfas_cats-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-predictor_models-prod.json` | 5 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-rdkit-prod.json` | 4 | Swagger host/scheme requires a recorded origin or explicit base URL override |
| `chemi-resolver-prod.json` | 45 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-safety-prod.json` | 4 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-search-prod.json` | 14 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-services-prod.json` | 14 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-stdizer-prod.json` | 33 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-toxprints-prod.json` | 23 | Relative server URL requires a recorded origin or explicit base URL override |
| `chemi-webtest-prod.json` | 9 | Relative server URL requires a recorded origin or explicit base URL override |
| `epi-suite-prod.json` | 14 | Relative server URL requires a recorded origin or explicit base URL override |

## Legacy snapshots are separate evidence

Do not file their repeated failures as extra canonical-production defects. Byte comparison also prevents treating a differently named historical snapshot as the same source.

| Legacy snapshot | Canonical production file | Byte-identical |
| --- | --- | --- |
| `ctx_bioactivity_prod.json` | `ctx-bioactivity-prod.json` | FALSE |
| `ctx_chemical_prod.json` | `ctx-chemical-prod.json` | FALSE |
| `ctx_exposure_prod.json` | `ctx-exposure-prod.json` | FALSE |
| `ctx_hazard_prod.json` | `ctx-hazard-prod.json` | TRUE |

## Reproduce

Run `Rscript dev/specmill-pilot/audit-all-schemas.R` after installing the isolated toolkit with `Rscript dev/install_specmill.R`.

Toolkit commit: `f41eeb9bae628eeb1f0fee16227f5ee8373a7ae2`. Source hashes, stable keys and complete per-mode outcomes are in `all-schema-diagnostics.json`. No schemas, client policies or production endpoints are changed.
