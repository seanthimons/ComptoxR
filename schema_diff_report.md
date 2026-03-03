### Endpoint Changes

**Summary:** 10 endpoints added, 0 removed, 4 modified across 7 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| coverage_baseline.json | ERROR | Parse error | OpenAPI object has no 'paths'. |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amos-staging.json | GET /api/amos/analytical_qc_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/fact_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/method_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/product_declaration_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/safety_data_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-resolver-dev.json | POST /api/resolver/safety-flags | Modified | body params added: [additionalProps] |
| chemi-resolver-staging.json | POST /api/resolver/safety-flags | Modified | body params added: [additionalProps] |
| chemi-safety-dev.json | POST /api/safety/rqcodes | Modified | body params added: [additionalProps] |
| chemi-safety-staging.json | POST /api/safety/rqcodes | Modified | body params added: [additionalProps] |
| chemi-opera-staging.json | GET /api/opera/version | Added | New endpoint |
| chemi-opera-staging.json | GET /api/opera/metadata | Added | New endpoint |
| chemi-opera-staging.json | GET /api/opera | Added | New endpoint |
| chemi-opera-staging.json | POST /api/opera | Added | New endpoint |
| chemi-opera-staging.json | POST /api/opera/file | Added | New endpoint |
