# Existing generator fixture comparison

Ran OpenAPI Generator CLI 7.15.0 with Java 17 against the exact checked-in
`wrapmaint/inst/catalogue/schema.json`. The Maven Apache source JAR has SHA256
`4DA1A7CDB78C3A43B1EAB0648891135E8C3547D2EEDBA0DD69DAF377F865F366`.

Command:

```text
java -jar openapi-generator-cli-7.15.0.jar generate -g r --library httr2 -i inst/catalogue/schema.json -o evidence/openapi-generator --additional-properties=packageName=localcatalogue,operationIdNaming=snake_case,hideGenerationTimestamp=true
```

The command passed. The generated R6 `DefaultApi` provides all four operations,
including the no-input POST refresh action. It produces `Item`, `ApiClient`,
`ApiResponse`, documentation and test files. The four operation tests contain
commented assertion placeholders, with no active request/result checks.

Its default API shape is `DefaultApi$new()$get_item(...)`, rather than a
procedural wrapper that calls the existing client helper. This output did not
include the client-owned pre/post callback contract or ComptoxR lifecycle
ownership checks. Preserving those contracts would need template customization
and independent tests. No existing component was substituted during this
parity migration. This is a fixture comparison, not a claim of general product
superiority or full OpenAPI coverage.

Source documentation: https://openapi-generator.tech/docs/generators/r/
