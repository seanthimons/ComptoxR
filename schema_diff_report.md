### Endpoint Changes

**Summary:** 20 endpoints added, 1 removed, 1 modified across 6 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amos-staging.json | GET /api/amos/fact_sheets_for_substance/{dtxsid} | Removed | Endpoint no longer exists |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-alerts-staging.json | POST /api/alerts/export | Modified | body params added: [showImages] |
| chemi-amos-dev.json | GET /api/amos/analytical_qc_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-dev.json | GET /api/amos/fact_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-dev.json | GET /api/amos/method_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-dev.json | GET /api/amos/product_declaration_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-dev.json | GET /api/amos/safety_data_sheet_keyset_pagination/{limit} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/product_declaration_pagination/{limit}/{offset} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/record_ids_for_substance/{dtxsid}/{record_type} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/safety_data_sheet_pagination/{limit}/{offset} | Added | New endpoint |
| chemi-opera-dev.json | GET /api/opera/version | Added | New endpoint |
| chemi-opera-dev.json | GET /api/opera/metadata | Added | New endpoint |
| chemi-opera-dev.json | GET /api/opera | Added | New endpoint |
| chemi-opera-dev.json | POST /api/opera | Added | New endpoint |
| chemi-opera-dev.json | POST /api/opera/file | Added | New endpoint |
| chemi-pfas_cats-staging.json | GET /api/pfas_cats/version | Added | New endpoint |
| chemi-pfas_cats-staging.json | GET /api/pfas_cats/metadata | Added | New endpoint |
| chemi-pfas_cats-staging.json | GET /api/pfas_cats | Added | New endpoint |
| chemi-pfas_cats-staging.json | POST /api/pfas_cats | Added | New endpoint |
| commonchemistry-prod.json | GET /detail | Added | New endpoint |
| commonchemistry-prod.json | GET /export | Added | New endpoint |
| commonchemistry-prod.json | GET /search | Added | New endpoint |
