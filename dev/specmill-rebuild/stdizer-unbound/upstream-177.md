Confirmed the same released-v41 serialization defect on the unbound standardizer operation `PATCH /api/stdizer/groups/{id}/freeze`, candidate `chemi_stdizer_groups_by_id_freeze_patch`, canonical `schema/chemi-stdizer-prod.json` SHA256 `178680219fccf31ecd6778532e69deff196e3767e3f8b6b3558d1cc3256f12ec`.

No previous wrapper exists for this operation. Generated from unchanged source with official 0.1.41 and `validation=TRUE`. Both scalar boolean query parameters default to true. Real localhost httpuv capture of `chemi_stdizer_groups_by_id_freeze_patch('group-123', freeze=FALSE, hierarchically=TRUE)` received:

```
PATCH /api/stdizer/groups/group-123/freeze?freeze=FALSE&hierarchically=TRUE
```

Expected `freeze=false&hierarchically=true`. Existing legacy and native endpoints remain unchanged. No deployed mutation was executed. The reproduction script and received wire proof are `dev/specmill-rebuild/stdizer-unbound/verify-held.R` and `held-freeze-proof.json` in ComptoxR PR345. This binding stays held; the protocol GET `/api/stdizer/protocols/{id}` also exposes scalar booleans but is independently held by nested Pageable #31. Blocks https://github.com/seanthimons/ComptoxR/pull/345. No duplicate issue or local generator workaround.
