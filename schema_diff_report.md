### Endpoint Changes

**Summary:** 2 endpoints added, 1 removed, 1 modified across 2 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-chet-staging.json | POST /reaction/reaction_DL | Removed | Endpoint no longer exists |
| chemi-opera-staging.json | POST /api/opera | Modified | body params removed: [smiles] |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-chet-staging.json | OPTIONS /reaction/map_DL | Added | New endpoint |
| chemi-chet-staging.json | POST /reaction/reaction_dl | Added | New endpoint |
