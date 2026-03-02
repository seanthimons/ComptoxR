### Endpoint Changes

**Summary:** 146 endpoints added, 0 removed, 4 modified across 9 schemas


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
| chemi-chet-dev.json | GET /index | Added | New endpoint |
| chemi-chet-dev.json | GET /version | Added | New endpoint |
| chemi-chet-dev.json | GET /metadata | Added | New endpoint |
| chemi-chet-dev.json | GET /admin/database | Added | New endpoint |
| chemi-chet-dev.json | GET /admin/resolve | Added | New endpoint |
| chemi-chet-dev.json | POST /admin/resolve | Added | New endpoint |
| chemi-chet-dev.json | GET /admin/errorreport | Added | New endpoint |
| chemi-chet-dev.json | POST /admin/errorreport | Added | New endpoint |
| chemi-chet-dev.json | GET /admin/register | Added | New endpoint |
| chemi-chet-dev.json | POST /admin/register | Added | New endpoint |
| chemi-chet-dev.json | GET /admin/login | Added | New endpoint |
| chemi-chet-dev.json | POST /admin/login | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/register | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/register | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/login | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/login | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/logout | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/report | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/report | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/errorpage | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/errorpage | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/errorpage/{showhide} | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/errorpage/{showhide} | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/errorpage/complete/{idnum} | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/errorpage/complete/{idnum} | Added | New endpoint |
| chemi-chet-dev.json | GET /auth/testpage | Added | New endpoint |
| chemi-chet-dev.json | POST /auth/testpage | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/verify/{dtxsid} | Added | New endpoint |
| chemi-chet-dev.json | POST /chemicals/newchemical | Added | New endpoint |
| chemi-chet-dev.json | POST /chemicals/newchemfile | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/database-old | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/database | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/database/stats | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/chemset | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/counts | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/maps | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/singlechemical | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/alias | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/chemical_DL | Added | New endpoint |
| chemi-chet-dev.json | POST /chemicals/chemical_DL | Added | New endpoint |
| chemi-chet-dev.json | POST /chemicals/template_DL | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/chemdelete | Added | New endpoint |
| chemi-chet-dev.json | POST /chemicals/chemdelete | Added | New endpoint |
| chemi-chet-dev.json | GET /chemicals/chemtemp/{type}/{value} | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/newlibrary | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/newreaction | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/newreactfile | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/libraries | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/maps | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/react_maps | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/details | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/template_DL | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/database_old | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/database-old/{pagenum}/{searchterm} | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/database | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/database/stats | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/search | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/reaction_DL | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/singlereaction | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/table | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/reactionmap | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/mapid | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/mapfix/{map_id} | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/map_DL | Added | New endpoint |
| chemi-chet-dev.json | POST /reaction/reactiondelete | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/dbcounts | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/searchcounts/{search_input}/{search_type} | Added | New endpoint |
| chemi-chet-dev.json | GET /reaction/download_DB_backup | Added | New endpoint |
| chemi-chet-staging.json | GET /index | Added | New endpoint |
| chemi-chet-staging.json | GET /version | Added | New endpoint |
| chemi-chet-staging.json | GET /metadata | Added | New endpoint |
| chemi-chet-staging.json | GET /admin/database | Added | New endpoint |
| chemi-chet-staging.json | GET /admin/resolve | Added | New endpoint |
| chemi-chet-staging.json | POST /admin/resolve | Added | New endpoint |
| chemi-chet-staging.json | GET /admin/errorreport | Added | New endpoint |
| chemi-chet-staging.json | POST /admin/errorreport | Added | New endpoint |
| chemi-chet-staging.json | GET /admin/register | Added | New endpoint |
| chemi-chet-staging.json | POST /admin/register | Added | New endpoint |
| chemi-chet-staging.json | GET /admin/login | Added | New endpoint |
| chemi-chet-staging.json | POST /admin/login | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/register | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/register | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/login | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/login | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/logout | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/report | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/report | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/errorpage | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/errorpage | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/errorpage/{showhide} | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/errorpage/{showhide} | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/errorpage/complete/{idnum} | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/errorpage/complete/{idnum} | Added | New endpoint |
| chemi-chet-staging.json | GET /auth/testpage | Added | New endpoint |
| chemi-chet-staging.json | POST /auth/testpage | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/verify/{dtxsid} | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/newchemical | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/newchemfile | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/database-old | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/database | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/database/stats | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/chemset | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/counts | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/maps | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/singlechemical | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/alias | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/chemical_DL | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/chemical_DL | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/template_DL | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/chemdelete | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/chemdelete | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/chemtemp/{type}/{value} | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/newlibrary | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/newreaction | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/newreactfile | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/libraries | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/maps | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/react_maps | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/details | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/template_DL | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/database_old | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/database-old/{pagenum}/{searchterm} | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/database | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/database/stats | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/search | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/reaction_DL | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/singlereaction | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/table | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/reactionmap | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/mapid | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/mapfix/{map_id} | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/map_DL | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/reactiondelete | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/dbcounts | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/searchcounts/{search_input}/{search_type} | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/download_DB_backup | Added | New endpoint |
| chemi-opera-staging.json | GET /api/opera/version | Added | New endpoint |
| chemi-opera-staging.json | GET /api/opera/metadata | Added | New endpoint |
| chemi-opera-staging.json | GET /api/opera | Added | New endpoint |
| chemi-opera-staging.json | POST /api/opera | Added | New endpoint |
| chemi-opera-staging.json | POST /api/opera/file | Added | New endpoint |
