### Endpoint Changes

**Summary:** 6 endpoints added, 1 removed, 1 modified across 3 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amos-staging.json | GET /api/amos/fact_sheets_for_substance/{dtxsid} | Removed | Endpoint no longer exists |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-alerts-staging.json | POST /api/alerts/export | Modified | body params added: [showImages] |
| chemi-amos-staging.json | GET /api/amos/product_declaration_pagination/{limit}/{offset} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/record_ids_for_substance/{dtxsid}/{record_type} | Added | New endpoint |
| chemi-amos-staging.json | GET /api/amos/safety_data_sheet_pagination/{limit}/{offset} | Added | New endpoint |
| commonchemistry-prod.json | GET /detail | Added | New endpoint |
| commonchemistry-prod.json | GET /export | Added | New endpoint |
| commonchemistry-prod.json | GET /search | Added | New endpoint |
