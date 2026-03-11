### Endpoint Changes

**Summary:** 38 endpoints added, 0 removed, 3 modified across 3 schemas


#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-opera-staging.json | GET /api/opera | Modified | params added: [format, standardize] |
| chemi-opera-staging.json | POST /api/opera | Modified | params added: [format, standardize] |
| chemi-predictor_models-staging.json | GET /api/predictor_models/predict | Modified | params added: [identifier, report_format] |
| chemi-chet-staging.json | GET /chemicals/verify/{dtxsid} | Added | New endpoint |
| chemi-chet-staging.json | POST /chemicals/newchemical | Added | New endpoint |
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
