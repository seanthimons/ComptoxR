### Endpoint Changes

**Summary:** 1 endpoints added, 0 removed, 1 modified across 2 schemas


#### Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-arn_cats-staging.json | POST /api/arn_cats | Modified | body params removed: [smiles, chemicals, model] |

#### Non-Breaking Changes

| Schema | Endpoint | Change | Detail |
|--------|----------|--------|--------|
| chemi-chet-staging.json | GET /chemicals/{chemical_id}/image | Added | New endpoint |
