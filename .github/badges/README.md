# Schema Coverage Badges

Badge data for the README's CCD, Cheminformatic and EPI Suite coverage badges,
in [shields.io endpoint format](https://shields.io/endpoint).

`dev/update_coverage.R` computes them with `specmill::coverage_report()`, using
the groups in `dev/coverage.yml`:

```bash
Rscript dev/update_coverage.R          # print coverage
Rscript dev/update_coverage.R --apply  # write the badges and dev/coverage-baseline.json
```

> These files are frozen until seanthimons/specmill#102 lands. `coverage_report()`
> currently measures against the operations selected in `apis/`, so it reports
> 100% for every group. These badges were computed against all schema operations.
