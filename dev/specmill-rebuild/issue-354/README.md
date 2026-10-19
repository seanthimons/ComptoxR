# Issue #354 dispositions

Decision on 2026-10-19: ban all methods except GET and POST across the client, and ban the five AMOS `add_*` uploads in this issue. These are client-scope decisions, not proof that the service restricts them to administrators.

Fresh production and development schemas are archived verbatim alongside `retrieval.json` with URLs, UTC retrieval times and SHA256 hashes. Production serves Swagger 2.0; development serves OpenAPI 3.0.3. Staging returned HTTP 503. The archived 2026-10-18 staging schema is byte-identical to today's development schema, but does not establish current staging availability or contents.

All eleven exact method/path identities exist in fresh production and are absent in fresh development and archived staging. There is no eligible intersection to contract or generate. All eleven are now banned under the user's decisions. No public wrappers existed for these eleven identities.

The six production-only updates are listed individually in `dispositions.json` for review. Their method ban supersedes the earlier contract-or-ban decision. No bodies are inferred from similarly named components.

Across canonical production schemas, the policy bans 27 non-GET/POST operations plus five AMOS uploads. Twenty-one already generated public wrappers are removed, with names and operation identities recorded in `removed-bindings.json`. Production schemas remain unchanged. The progress ledger keeps the canonical denominator and reports banned endpoints separately from migrated and remaining endpoints.

Verification uses exact method/path matching, generation with validation enabled, generation freshness, public-boundary checks and the affected offline localhost suites. No live upload, update or deletion requests are made.

All five affected offline suites, validation-enabled generation, generation freshness and public-boundary checks passed. Exact results and limits are in `verification.json`. Current totals are 492 migrated, 32 banned and 24 remaining out of 548 canonical production operations. Full package checks were not run.
