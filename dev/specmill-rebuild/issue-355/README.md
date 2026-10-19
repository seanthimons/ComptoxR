# Issue #355 route bans

On 2026-10-19 the user banned all CheT `/auth/*`, `/admin/*` and `/chemicals/chemdelete` operations for every method. Global generation continues to allow only GET and POST, so OPTIONS, DELETE and PUT are already banned everywhere.

The CheT rule bans 26 canonical production operations. All eight GET-body identities in #355 are included. Eighteen already generated public bindings are removed, along with their exports, help pages, hook entries and affected tests/fixtures. `dispositions.json` records all 26 exact identities; `removed-bindings.json` records the 18 removed wrappers. A path-pattern guard on CheT schema inputs also rejects future auth/admin/chemdelete selections.

The canonical production schemas remain unchanged. No request bodies are inferred or corrected, and no deployed authentication, session or deletion requests are made. This is a client-scope decision rather than a service-contract claim.

Validation-enabled generation, generation freshness, the surviving CheT localhost suite, the endpoint-policy regression suite and public-boundary checks passed. `verification.json` records the canonical source hash and check results. The progress ledger now records 474 migrated, 58 banned and 16 unresolved operations out of 548; banned operations do not count as migrated. Full package checks were not run.
