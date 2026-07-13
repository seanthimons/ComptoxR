### Endpoint Changes

**Summary:** 14 endpoints added, 1 removed, 34 modified across 16 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-chet-staging.json | OPTIONS /reaction/reaction_dl | Removed | Endpoint no longer exists |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-alerts-prod.json | POST /api/alerts | Modified | body params unchanged |
| chemi-alerts-prod.json | POST /api/alerts/groups | Modified | body params unchanged |
| chemi-alerts-prod.json | PUT /api/alerts/groups/{id} | Modified | body params unchanged |
| chemi-amnb_nate-staging.json | POST /api/amnb_nate | Modified | body params unchanged |
| chemi-arn_cats-staging.json | POST /api/arn_cats | Modified | body params unchanged |
| ctx-chemical-prod.json | POST /chemical/msready/search/by-mass/ | Modified | body params unchanged |
| chemi-chet-staging.json | GET /curators/detail-sets | Added | New endpoint |
| chemi-chet-staging.json | POST /curators/details | Added | New endpoint |
| chemi-chet-staging.json | POST /curators/libraries | Added | New endpoint |
| chemi-chet-staging.json | GET /curators/libraries/detail-options | Added | New endpoint |
| chemi-chet-staging.json | GET /curators/libraries/{lib_id} | Added | New endpoint |
| chemi-chet-staging.json | PUT /curators/libraries/{lib_id} | Added | New endpoint |
| chemi-chet-staging.json | GET /curators/units | Added | New endpoint |
| chemi-chet-staging.json | POST /curators/units | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/editor/check-existing | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/editor/check-existing-map | Added | New endpoint |
| chemi-chet-staging.json | GET /reaction/editor/library-details | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/editor/load-map | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/editor/load-reactions | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/editor/save-scheme | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/visibility | Modified | body params unchanged |
| chemi-descriptors-prod.json | POST /api/descriptors | Modified | body params unchanged |
| chemi-hazard-prod.json | POST /api/hazard | Modified | params unchanged |
| chemi-hazard-prod.json | POST /api/hazard | Modified | body params unchanged |
| chemi-pfas_atlas-staging.json | POST /api/pfas_atlas | Modified | body params unchanged |
| chemi-pfas_cats-staging.json | POST /api/pfas_cats | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/getsimilaritylist | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/lookup | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/orderBySimilarity | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/resolve | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/safety-flags | Modified | body params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/universalharvest | Modified | params unchanged |
| chemi-resolver-prod.json | POST /api/resolver/universalharvest_cart | Modified | body params unchanged |
| chemi-safety-prod.json | POST /api/safety/rqcodes | Modified | body params unchanged |
| chemi-search-prod.json | POST /api/search | Modified | body params unchanged |
| chemi-search-prod.json | POST /api/search/lookup | Modified | body params unchanged |
| chemi-stdizer-prod.json | POST /api/stdizer | Modified | params unchanged |
| chemi-stdizer-prod.json | POST /api/stdizer/chemicals | Modified | body params unchanged |
| chemi-stdizer-prod.json | POST /api/stdizer/groups | Modified | body params unchanged |
| chemi-stdizer-prod.json | PUT /api/stdizer/groups/{id} | Modified | body params unchanged |
| chemi-stdizer-prod.json | POST /api/stdizer/records | Modified | body params unchanged |
| chemi-toxprints-prod.json | POST /api/toxprints | Modified | body params unchanged |
| chemi-toxprints-prod.json | POST /api/toxprints/assays | Modified | body params unchanged |
| chemi-toxprints-prod.json | PUT /api/toxprints/assays/{id} | Modified | body params unchanged |
| chemi-toxprints-prod.json | POST /api/toxprints/calculate | Modified | params unchanged |
| chemi-webtest-prod.json | POST /api/webtest | Modified | body params unchanged |
| chemi-webtest-prod.json | POST /api/webtest/predict | Modified | body params unchanged |
| ctx_chemical_prod.json | POST /chemical/msready/search/by-mass/ | Modified | body params unchanged |
