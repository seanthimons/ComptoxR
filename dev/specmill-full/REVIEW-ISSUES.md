# Specmill migration review issues

Created 24 September 2026 from the migration branch at `418128bd`. These five
GitHub issues are the active review checklists. Each contains its full function
list, published baseline source links, review rationale, acceptance criteria,
verification commands, and the public-endpoint constraint.

| Category | Remaining exports |
| --- | ---: |
| [Protected lifecycle and metadata](https://github.com/seanthimons/ComptoxR/issues/310) | 109 |
| [Custom implementations](https://github.com/seanthimons/ComptoxR/issues/311) | 93 |
| [Hook behavior](https://github.com/seanthimons/ComptoxR/issues/312) | 26 |
| [Public schema route blockers](https://github.com/seanthimons/ComptoxR/issues/313) | 16 |
| [Grouped-file ownership](https://github.com/seanthimons/ComptoxR/issues/314) | 4 |

The 248 names are distinct CT/Chemi/EPI-prefixed exports outside the 105 mapped
operations. Some are client utilities, not endpoint wrappers. The original
screening had 113 protected/metadata entries; four already have retained
mappings and contracts, leaving 109 in that issue.

Screening stopped at the first reason. These categories are not defect counts,
and a custom implementation can also have an upstream schema blocker. Mark an
entry complete once its generated, retained, utility, or blocked disposition
and evidence are recorded. Retaining a manual implementation is a valid result.

## Supporting evidence

- [Original screening inventory](attempt-results.json) records all 409 exports.
- [Migration report](REPORT.md) records the adopted slice and verification limits.
- [Schema audit](../specmill-pilot/UPSTREAM-ISSUES.md) records stable routes,
  source pointers, invalid examples, and unsupported contracts. Issue #313 also
  includes this complete audit inline so it remains accessible before the
  feature branch is published.
- [Specmill source pin](../specmill-lock.json) fixes the toolkit revision and
  archive checksum used for the migration.

The five issues include the supporting details directly. Source links use the
published original-client commit `4fd720b97fb2f7f2abf131925e9270b0c11b057a`;
they do not depend on the unpublished feature branch.

Public API endpoints only. Use offline fixtures and localhost for verification.
Keep ambiguous media contracts blocked and preserve existing authentication,
hooks, signatures, lifecycle badges, and runtime policy. No production write
requests are authorized by these migration issues.

Related existing behavior work is linked from the relevant category issues,
including descriptor/WebTEST work #261, #262, #263, and #264, resolver default behavior #267,
`ct_related` #109, bioactivity annotation #239, and schema handling #83. Migration
compatibility work should not silently incorporate those behavior changes.
