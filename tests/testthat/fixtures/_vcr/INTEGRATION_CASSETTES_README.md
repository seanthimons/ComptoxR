# Integration Test Cassettes

Integration test cassettes are stored in `tests/testthat/fixtures/` (parent directory), not here.

This `_vcr/` subdirectory is reserved for future use if needed.

## Recording Cassettes

Integration tests in `test-pipeline-integration.R` require VCR cassettes to mock API responses.

**First run (recording):**
1. Set environment variable: `Sys.setenv(ctx_api_key = "YOUR_API_KEY")`
2. Run tests: `devtools::test(filter = "pipeline-integration")`
3. Cassettes will be created in `tests/testthat/fixtures/`:
   - `integration-ctx-hazard.yml` - CompTox Dashboard API responses
   - `integration-chemi-safety.yml` - Cheminformatics API responses

**Subsequent runs (replay):**
- Tests use recorded cassettes (no API key needed)
- No live API calls are made

## Security

VCR is configured to sanitize API keys via `helper-vcr.R`:
- Real keys are replaced with `<<<API_KEY>>>` in cassettes
- Safe to commit cassettes to repository

## Verification

Before committing cassettes, verify API keys are sanitized:
```r
# Check cassettes for exposed keys
grep -r "YOUR_ACTUAL_KEY" tests/testthat/fixtures/integration-*.yml
```

Should return no matches if properly sanitized.

## Missing Cassettes

If cassettes don't exist and no API key is set, tests will skip gracefully with message:
```
First run requires ctx_api_key to record cassette
```

This is expected behavior for environments without API access.
