# Specmill service selection (#333)

Every service file in `apis/` is either `selection.unclaimed: true`, has no selection block (hazard, bioactivity), or keeps an explicit include list. Endpoint policy lives in `specmill.yml` `selection.exclude`.

## Why include lists remain

`unclaimed` selects every operation no sibling service claims. Two unclaimed services on one schema file collide on the first leftover operation (`Operation names collide across services`; reproduced with a two-unclaimed fixture on 0.1.56). Each schema therefore has exactly one unclaimed owner, and the other services on it keep the operations they own by include list, so selection stays non-overlapping.

Converted in #333: `alerts-pilot` (no other unclaimed service on `chemi_alerts_prod.json`) and `chemi-amos-direct-reads` (sole unclaimed owner of `chemi_amos_prod.json`). `dev/generate_specmill.R --plan` selected the same 458 operations before and after.

## Kept include lists

| Service file | Reason |
| --- | --- |
| `apis/epi-pilot.yml` | Schema already owned by unclaimed `epi-suite-prod-rebuild`; a second unclaimed service would collide. |
| `apis/amos-pilot.yml` | Shares `chemi_amos_prod.json` with `chemi-amos-direct-reads`, the schema's single unclaimed owner. A trial with this service unclaimed dropped `GET /api/amos/get_classification_for_dtxsid/{dtxsid}` from the selected set (plan diff), so it keeps its include list. |
| `apis/ctx-pilot.yml` | Schema already owned by unclaimed `ctx-chemical-prod-rebuild`; a second unclaimed service would collide. |
| `apis/search-pilot.yml` | Schema already owned by unclaimed `chemi-search-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-amos-prod-full.yml` | Shares `chemi_amos_prod.json` with `chemi-amos-direct-reads`, the schema's single unclaimed owner. A trial with this service unclaimed dropped `GET /api/amos/get_classification_for_dtxsid/{dtxsid}` from the selected set (plan diff), so it keeps its include list. |
| `apis/chemi-chet-prod-full.yml` | Schema already owned by unclaimed `chemi-chet-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-resolver-prod-full.yml` | Schema already owned by unclaimed `chemi-resolver-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-services-prod-full.yml` | Schema already owned by unclaimed `chemi-services-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-stdizer-prod-full.yml` | Schema already owned by unclaimed `chemi-stdizer-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-toxprints-prod-full.yml` | Schema already owned by unclaimed `chemi-toxprints-prod-rebuild`; a second unclaimed service would collide. |
| `apis/ctx-chemical-prod-full.yml` | Schema already owned by unclaimed `ctx-chemical-prod-rebuild`; a second unclaimed service would collide. |
| `apis/ctx-exposure-prod-full.yml` | Schema already owned by unclaimed `ctx-exposure-prod-rebuild`; a second unclaimed service would collide. |
| `apis/epi-suite-prod-full.yml` | Schema already owned by unclaimed `epi-suite-prod-rebuild`; a second unclaimed service would collide. |
| `apis/ctx-list-name.yml` | Schema already owned by unclaimed `ctx-chemical-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-chet-direct-reads.yml` | Schema already owned by unclaimed `chemi-chet-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-service-info.yml` | Schema already owned by unclaimed by 18 `*-prod-rebuild` services and `alerts-pilot` (only `chemi_descriptors_prod.json` has no owner); a second unclaimed service would collide. |
| `apis/chemi-management.yml` | Schema already owned by unclaimed by `chemi-safety`, `chemi-hazard` and `chemi-toxprints-prod-rebuild` and `alerts-pilot`; a second unclaimed service would collide. |
| `apis/chemi-chet-extra.yml` | Schema already owned by unclaimed `chemi-chet-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-resolver-remaining-facade.yml` | Schema already owned by unclaimed `chemi-resolver-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-search-services-native.yml` | Schema already owned by unclaimed `chemi-search-prod-rebuild`, `chemi-services-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-resolver-extra.yml` | Schema already owned by unclaimed `chemi-resolver-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-small-families.yml` | Schema already owned by unclaimed `chemi-predictor_models-prod-rebuild`, `chemi-webtest-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-stdizer-unbound.yml` | Schema already owned by unclaimed `chemi-stdizer-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-released-chet-facades.yml` | Schema already owned by unclaimed `chemi-chet-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-webtest-exports.yml` | Schema already owned by unclaimed `chemi-webtest-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-stdizer-reviewed-protocol-search.yml` | Schema already owned by unclaimed `chemi-stdizer-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-released-boolean-bindings.yml` | Schema already owned by unclaimed by `chemi-opera`, `chemi-resolver` and `chemi-stdizer-prod-rebuild` and `alerts-pilot`; a second unclaimed service would collide. |
| `apis/chemi-stdizer-reviewed-protocol-get.yml` | Schema already owned by unclaimed `chemi-stdizer-prod-rebuild`; a second unclaimed service would collide. |
| `apis/chemi-descriptors-native.yml` | Schema already owned by unclaimed `chemi-rdkit-prod-rebuild` (its `chemi_descriptors_prod.json` has no owner, but the rdkit leftovers would collide); a second unclaimed service would collide. |
| `apis/pubchem-reviewed.yml` | Sole service on `pubchem-reviewed.json`, but `unclaimed` would additionally select `POST /compound/cid/property/{properties}/JSON`, `POST /compound/cid/synonyms/JSON` and `POST /compound/{namespace}/cids/JSON` (plan diff); the include list owns only the three reviewed operations. |
