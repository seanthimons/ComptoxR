Reconfirmed on released Specmill 0.1.42, source `b17a0856263e0179a164a9673399f221168cda6d`, for seanthimons/ComptoxR#345 at parent `3ea6140c`.

The existing `chemi_alerts_render(smiles = NULL, smirks = NULL, format = "SVG", width = NULL, height = NULL)` owns GET `/api/alerts/render` from `schema/chemi-alerts-prod.json`. The same canonical operation in `schema/chemi-safety-prod.json` has identical parameters/server but response `*/*` instead of `image/png,image/svg+xml`. No additional safety facade exists.

Minimal repro remains adding `schema/chemi-safety-prod.json` to `apis/chemi-management.yml` `schemas.files`, without changing any other mapping, then:

```r
specmill::generate_client(root = root, config = 'specmill.yml',
  mode = 'plan', artifacts = 'wrappers', validation = TRUE)
```

Actual result:

```
Conflicting duplicate operation chemi-management GET /api/alerts/render in .../schema/chemi-alerts-prod.json, .../schema/chemi-safety-prod.json
```

Pinned source inspection: `R/operations.R` duplicate-contract comparison removes only `source` and `source_hash`, so response media remains part of conflict detection. `R/configuration.R` declared-route handling calls `read_operations(service$files, ...)` before resolving `routes`; listing this same operation as a route cannot bypass the duplicate conflict. Schema file selection excludes a source rather than recording both identities. Response corrections would change the canonical contract being accounted for. Please support explicit shared-source ownership with these differing response declarations, or identify an existing supported config.

We retain the current alerts wrapper and leave the safety source identity held. No duplicate alias, schema change, helper/runtime patch or coverage credit. The two unrelated WebTEST exports use their own canonical schema and generated wrappers. Reproduction and hashes are being committed under `dev/specmill-rebuild/webtest-exports/` for PR345 integration.
