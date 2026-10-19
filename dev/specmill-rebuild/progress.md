Endpoints migrated to Specmill — iteration checkpoint

Counted: root-adopted native wrappers with matching Specmill ownership hashes and committed offline behavior suites. Fresh generation checks pass. Held private candidates and endpoints with literal legacy request callers are excluded; live validation remains incomplete.

Denominator: all HTTP operations in each canonical `schema/*-prod.json`, including routes not yet exposed by this client. Archived underscore-named CTX copies and coverage metadata are excluded. There are no staging schema files in this checkout.

```
Endpoints migrated (adopted / source schema total):
chemi-alerts-prod: 13/16
chemi-amnb_nate-prod: 4/4
chemi-amos-prod: 64/77
chemi-arn_cats-prod: 4/4
chemi-chet-prod: 84/95
chemi-descriptors-prod: 2/4
chemi-hazard-prod: 16/16
chemi-mordred-prod: 4/4
chemi-ncc_cats-prod: 4/4
chemi-opera-prod: 6/6
chemi-padel-prod: 4/4
chemi-pfas_atlas-prod: 4/4
chemi-pfas_cats-prod: 4/4
chemi-predictor_models-prod: 5/5
chemi-rdkit-prod: 4/4
chemi-resolver-prod: 42/46
chemi-safety-prod: 3/4
chemi-search-prod: 13/14
chemi-services-prod: 12/14
chemi-stdizer-prod: 29/33
chemi-toxprints-prod: 22/23
chemi-webtest-prod: 9/9
ctx-bioactivity-prod: 30/30
ctx-chemical-prod: 55/55
ctx-exposure-prod: 27/27
ctx-hazard-prod: 28/28
epi-suite-prod: 14/14
```

Total: 506/548. This is endpoint ownership/test coverage, not a claim that every live server behavior has been validated.
