Endpoints migrated to Specmill — iteration checkpoint

Counted: root-adopted native wrappers with matching Specmill ownership hashes and committed offline behavior suites. Fresh generation checks pass. Held private candidates and endpoints with literal legacy request callers are excluded; live validation remains incomplete.

Denominator: all HTTP operations in each canonical `schema/*-prod.json`, including routes not yet exposed by this client. Archived underscore-named CTX copies and coverage metadata are excluded. There are no staging schema files in this checkout.

```
Endpoints migrated (adopted / source schema total):
chemi-alerts-prod: 4/16
chemi-amnb_nate-prod: 2/4
chemi-amos-prod: 56/77
chemi-arn_cats-prod: 2/4
chemi-chet-prod: 26/95
chemi-descriptors-prod: 0/4
chemi-hazard-prod: 0/16
chemi-mordred-prod: 0/4
chemi-ncc_cats-prod: 2/4
chemi-opera-prod: 3/6
chemi-padel-prod: 0/4
chemi-pfas_atlas-prod: 2/4
chemi-pfas_cats-prod: 2/4
chemi-predictor_models-prod: 2/5
chemi-rdkit-prod: 0/4
chemi-resolver-prod: 21/46
chemi-safety-prod: 0/4
chemi-search-prod: 4/14
chemi-services-prod: 4/14
chemi-stdizer-prod: 5/33
chemi-toxprints-prod: 9/23
chemi-webtest-prod: 0/9
ctx-bioactivity-prod: 30/30
ctx-chemical-prod: 54/55
ctx-exposure-prod: 27/27
ctx-hazard-prod: 28/28
epi-suite-prod: 12/14
```

Total: 295/548. This is endpoint ownership/test coverage, not a claim that every live server behavior has been validated.
