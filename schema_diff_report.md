### Endpoint Changes

**Summary:** 4 endpoints added, 0 removed, 4 modified across 4 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-chet-staging.json | GET /reaction/database/stats | Modified | params removed: [parent_id] |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-amnb_nate-staging.json | POST /api/amnb_nate | Modified | body params added: [smiles, chemicals] |
| chemi-arn_cats-staging.json | POST /api/arn_cats | Modified | body params added: [smiles, chemicals, model] |
| chemi-chet-staging.json | OPTIONS /reaction/batchsearch | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/batchsearch | Added | New endpoint |
| chemi-chet-staging.json | OPTIONS /reaction/reaction_dl | Added | New endpoint |
| chemi-chet-staging.json | GET /chemicals/database | Modified | params added: [exact_search, only_in_reactions] |
| chemi-opera-staging.json | GET /api/opera/report | Added | New endpoint |
