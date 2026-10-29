# Schema Coverage Badges

Badge data for the README's CCD, Cheminformatic and EPI Suite coverage badges,
in [shields.io endpoint format](https://shields.io/endpoint).

`dev/update_coverage.R` computes them with `specmill::coverage_report()`, using
the groups in `dev/coverage.yml`:

```bash
Rscript dev/update_coverage.R          # print coverage
Rscript dev/update_coverage.R --apply  # write the badges and dev/coverage-baseline.json
```

> Coverage is measured against all schema operations (`denominator: schema` in
> `dev/coverage.yml`); pubchem is excluded via `exclude_services`.
