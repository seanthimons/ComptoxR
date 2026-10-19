Endpoints migrated to Specmill — iteration checkpoint

Counted: root-adopted native wrappers with matching Specmill ownership hashes and committed offline behavior suites. Fresh generation checks pass. Held private candidates and endpoints with literal legacy request callers are excluded; live validation remains incomplete.

Denominator: all HTTP operations in each canonical `schema/*-prod.json`, including banned routes. Banned routes are excluded from remaining work and are never counted as migrated. Policy: `dev/endpoint-policy.json`. Dev/staging evidence stays under `dev/`.

```
Endpoints migrated (adopted / source schema total):
chemi-alerts-prod: 10/16 (3 banned; 3 remaining)
chemi-amnb_nate-prod: 4/4 (0 banned; 0 remaining)
chemi-amos-prod: 64/77 (11 banned; 2 remaining)
chemi-arn_cats-prod: 4/4 (0 banned; 0 remaining)
chemi-chet-prod: 83/95 (4 banned; 8 remaining)
chemi-descriptors-prod: 4/4 (0 banned; 0 remaining)
chemi-hazard-prod: 13/16 (3 banned; 0 remaining)
chemi-mordred-prod: 4/4 (0 banned; 0 remaining)
chemi-ncc_cats-prod: 4/4 (0 banned; 0 remaining)
chemi-opera-prod: 6/6 (0 banned; 0 remaining)
chemi-padel-prod: 4/4 (0 banned; 0 remaining)
chemi-pfas_atlas-prod: 4/4 (0 banned; 0 remaining)
chemi-pfas_cats-prod: 4/4 (0 banned; 0 remaining)
chemi-predictor_models-prod: 5/5 (0 banned; 0 remaining)
chemi-rdkit-prod: 4/4 (0 banned; 0 remaining)
chemi-resolver-prod: 42/46 (0 banned; 4 remaining)
chemi-safety-prod: 4/4 (0 banned; 0 remaining)
chemi-search-prod: 14/14 (0 banned; 0 remaining)
chemi-services-prod: 12/14 (0 banned; 2 remaining)
chemi-stdizer-prod: 21/33 (8 banned; 4 remaining)
chemi-toxprints-prod: 19/23 (3 banned; 1 remaining)
chemi-webtest-prod: 9/9 (0 banned; 0 remaining)
ctx-bioactivity-prod: 30/30 (0 banned; 0 remaining)
ctx-chemical-prod: 55/55 (0 banned; 0 remaining)
ctx-exposure-prod: 27/27 (0 banned; 0 remaining)
ctx-hazard-prod: 28/28 (0 banned; 0 remaining)
epi-suite-prod: 14/14 (0 banned; 0 remaining)
```

Total: 492/548. This is endpoint ownership/test coverage, not a claim that every live server behavior has been validated.
