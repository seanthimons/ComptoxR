Endpoints migrated to Specmill — iteration checkpoint

Counted: root-adopted native wrappers with matching Specmill ownership hashes and committed offline behavior suites. Fresh generation checks pass. Held private candidates and endpoints with literal legacy request callers are excluded; live validation remains incomplete.

Denominator: all HTTP operations in each canonical `schema/*-prod.json`, including banned routes. Banned routes are excluded from remaining work and are never counted as migrated. Policy: `specmill.yml` `selection`. Dev/staging evidence stays under `dev/`.

```
Endpoints migrated (adopted / source schema total):
chemi-alerts-prod: 3/16 (13 banned; 0 remaining)
chemi-amnb_nate-prod: 4/4 (0 banned; 0 remaining)
chemi-amos-prod: 58/77 (13 banned; 6 remaining)
chemi-arn_cats-prod: 4/4 (0 banned; 0 remaining)
chemi-chet-prod: 64/95 (30 banned; 1 remaining)
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
chemi-resolver-prod: 42/46 (3 banned; 1 remaining)
chemi-safety-prod: 3/4 (1 banned; 0 remaining)
chemi-search-prod: 14/14 (0 banned; 0 remaining)
chemi-services-prod: 12/14 (2 banned; 0 remaining)
chemi-stdizer-prod: 17/33 (16 banned; 0 remaining)
chemi-toxprints-prod: 20/23 (3 banned; 0 remaining)
chemi-webtest-prod: 9/9 (0 banned; 0 remaining)
ctx-bioactivity-prod: 30/30 (0 banned; 0 remaining)
ctx-chemical-prod: 55/55 (0 banned; 0 remaining)
ctx-exposure-prod: 27/27 (0 banned; 0 remaining)
ctx-hazard-prod: 28/28 (0 banned; 0 remaining)
epi-suite-prod: 14/14 (0 banned; 0 remaining)
```

Total: 456/548. This is endpoint ownership/test coverage, not a claim that every live server behavior has been validated.
