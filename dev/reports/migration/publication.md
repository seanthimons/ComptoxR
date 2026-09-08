# Migration publication evidence

## Final public endpoint release

ComptoxR 3.0.0 is published through normal Release run `34185471524`:
https://github.com/seanthimons/ComptoxR/releases/tag/v3.0.0

PR 307 merged as `35e0d0c952429a9bf2ae24ff9097e5df985ccd85`. The release commit
is `e2de0aa9a39380990bbda446838bf888448469ac`, published at
2026-09-08T04:05:03Z. Package asset `549832331` is 1,790,257 bytes, with SHA-256
`2e6249b2185af035f5fc69fa10288446beaf50728c27c2f011572c60b3652991`.

- All normal package/platform, readiness, coverage, toolkit, generation, and
  site acceptance checks passed. The two cancelled R-devel jobs were rerun in
  `34181879988` and passed. Their original logs show long source compilation;
  intermediate API status had lagged behind actual progress.
- The optional integration rolling publisher stopped at its existing `.9000`
  development-version guard for stable 2.0.0 metadata. No development package
  was published. This guard was retained; the normal stable release succeeded.
- The release workflow's package check and final source/archive boundary scans
  passed before publication. No package version or release tag was edited by hand.
- The downloaded 3.0.0 archive matched its digest and installed into a separate
  library. Its 1,206 text files passed the public boundary scan. Installed default
  URLs, explicit override behavior, removed exports, and startup state passed.
  wrapmaint was not loaded at runtime. `R/`, `inst/`, and `NAMESPACE` match the
  reviewed endpoint commit `e3b08c7` exactly.
- The published client and envharmonizer 0.1.1 passed the September database and
  fresh local Plumber check for 664 selected rows. Every native source column and
  row was preserved; database SHA-256 remained unchanged.
- Release site workflow `34185724310` passed build and deployment. Its downloaded
  `github-pages` artifact `10040517247` passed the 981-text-file boundary scan.
  The live site shows 3.0.0, and the removed `chemi_safety` page returns HTTP 404.
- Release-triggered source-only database workflow `34185724234` passed without
  replacing the verified current database. Its builder metadata remains 2.0.0;
  the 3.0.0 client and server were verified against that source-only schema.

Final runtime verification logs are retained in the production-endpoints
worktree under `.migration-evidence/published-3.0.0/` and
`.migration-evidence/published-site/`. Users must update the client packages and
restart local Plumber servers. Existing local databases and mapping evidence
remain intact. Existing unrelated PRs 304 and 305 are outside this migration.

## Lifestage and source-only client

Experimental envharmonizer 0.1.0 passed publication verification before the
ComptoxR removal release. See `lifestage-release.md` for hashes and offline checks.

ComptoxR PR 306 passed all checks and merged as
`1f61423b4469ff7de39bb6f9459d33d8806f771b`. Normal Release run `34180852761`
published v2.0.0 at `b55949c3036a7fae0b6b869f3581ce205c39c7ff`.

- Package asset: `549749907`, `ComptoxR_2.0.0.tar.gz`, 1,812,519 bytes.
- SHA-256: `a7b7bae7f4462b7d6fa95b77c6f113a664e756a93ff44b2c18beb1e13b2bd589`.
- Downloaded archive matched the published digest. Separate-library installation
  passed. Version is 2.0.0; the source-only builder is shipped; no public
  `lifestage_details` argument or `eco_lifestage_patch` export remains.
- Forced source-only database workflow `34181519666` started only after these
  checks passed. Database download verification and withdrawal are complete;
  details follow below.

## Pinned development toolkit

The reviewed wrapmaint 0.1.0 archive is attached to ComptoxR v2.0.0:
https://github.com/seanthimons/ComptoxR/releases/download/v2.0.0/wrapmaint_0.1.0.tar.gz

- Asset: `549752304`, 44,401 bytes.
- SHA-256: `a9e8ff83f1316b1e3059c63ab84e7aa01567bb7c2156259400bf791781408fe0`.
- Toolkit source: `aae88f99f6bd355a06d3404fd100b86620609e83`.
- `install_toolkit(lib = <separate library>)` downloaded the public URL without
  credentials and verified the checksum, installation status, and version.
- Clean detached checkout `04085a7` used this downloaded installation. Generation
  returned 140 protected and 205 unchanged files. Generated tests, hook validation,
  and the public scan passed; `git status --porcelain` stayed empty.
- Commands: `generate_stubs_main(args = c('--check', '--rebuild=ct',
  '--rebuild=chemi', '--rebuild=epi'))`, `generate_tests_main(args = '--check')`,
  `check_hook_config()`, `check_public_api()`. All entry points were sourced from
  the clean checkout. The scan covered 1,584 text files. Existing schema pagination
  warnings were reported; no generation error occurred.

PR 307 contains the integrated endpoint and toolkit changes. Integration advanced
by fast-forward from `8f055b8` to `04085a7`, preserving prior history. The normal
release workflow checks final source and expanded package contents before push.

## September mapping applicability and database withdrawal

The live rebuild used `ecotox_ascii_09_15_2026.zip`, already named by the old
rolling sidecar. Its 1,250,611 results passed the source-only publication guard.
The first cross-package check correctly failed: envharmonizer 0.1.0 supports the
frozen June release, not September. No release check was weakened.

Native files from both EPA archives contain the same 139 code-description pairs,
with SHA-256 `31eaeb745dd1ffa41f7c70691a2092a1e6efaccc00f2db113c823cd0f5e2ba98`.
The September archive hash is
`6aba4def7d6e405e8f9f44173e4fe132013f3657bb4b5491f1fcc660fd1454b1`.
The current appendix and index match the frozen hashes already recorded.

envharmonizer 0.1.1 adds explicit September tables that record June as their
mapping-evidence release. June values, RDS bytes, and metadata are unchanged.
Unknown releases still fail. Mappings remain experimental and not independently
reviewed. Source PR 21 passed CI and merged as
`2facf3b513394763194bbc3e02f216ea37cf3edf`.

Published at 2026-09-08T03:43:58Z:
https://github.com/seanthimons/envharmonizer-releases/releases/tag/v0.1.1

- Package SHA-256: `b5d0b717980d13712ddee3250edecfab43abafb91d93818dbb66e27925b3b71d`.
- Manifest SHA-256: `86b59536cfdd958dd180a580de50248e52474b1b92f9c1495d48b218e735e5bb`.
- All 12 downloaded payloads match the reviewed checksum file. A separate
  unauthenticated package download matched and installed successfully.
- Source suite: 308 passes, no failures, warnings, or skips. R CMD check: Status
  OK; installed suite 292 passes and five documented maintainer-source skips.
- Independent installed ComptoxR 2.0.0 and published envharmonizer 0.1.1 matched
  664 selected database rows through a fresh localhost server. Mapping preserved
  every source column and row. The database hash was unchanged.

Source-only rolling database asset `549783704`, 444,084,224 bytes, has SHA-256
`2664e63ab9b6d37fbd8206d1747d7e8f77084897de80f2320c660873ef04c5db`.
Sidecar asset `549783706` has SHA-256
`6a82043ba3d9c0ec6927ec01ba49c72edb386ed7b19ad6d9e7272718db349835`.
Database metadata records builder ComptoxR 2.0.0 and the exact September source
identifier. The provider uses a September 15 identifier; it is recorded literally.

The rolling upload replaced old IDs `548521627` and `548521629`. Only after all
public mapping and database checks passed, old `v1.5.0` database asset `464523912`
was deleted. All three old IDs return HTTP 404. New IDs and hashes were checked
again after withdrawal. Other release assets, users' databases, and mapping
evidence are preserved. No legacy derived database was published.

Withdrawal state was verified at 2026-09-08T03:45:48Z. The runnable
`verify_published_database.R` verifies native tables, explicit release mapping,
source-column preservation, matching installed/local HTTP behavior, and unchanged
database hashes. Local command logs are retained under the production-endpoints
worktree's `.migration-evidence/published-database/` and
`.migration-evidence/published-harmonizer-september/`.

Reviewed September payload SHA-256 values (also published as `SHA256SUMS`):

```text
b5d0b717980d13712ddee3250edecfab43abafb91d93818dbb66e27925b3b71d  envharmonizer_0.1.1.tar.gz
dba6e8c5a133f6d78fbbd96d5118514fef01800e848fcee0fcdcb8e83e0fb4e1  ATTRIBUTION.md
1ca2d9ec97215f192761b637b7f47cfa5040fb7e7ca6dc53d7e0124250ecbfdb  REVIEW.md
209bbf3d52e8d9ad76dd55f92c5c0125278d0f127068694aaa85018673dfc8e9  comparison.json
42b700c32faab94f8d2fd3a87c65c8892742ba48d89ece2d2a78d137b76f8e55  lifestage-evidence.tar.gz
86b59536cfdd958dd180a580de50248e52474b1b92f9c1495d48b218e735e5bb  lifestage-manifest.json
25808c69fb895513dad633ffb25071f09bce4a108db613a9c0ce5aea71c14051  lifestage_dictionary_09_15_2026.csv
40d48f4466017fcc43d5a101167ac3de04ac5dbaa4f3087556ad2b54dd3052e5  lifestage_dictionary_09_15_2026.parquet
d74d49bfce5cd0a68feae69b38d4aee2bb3981e2132ac11881e06f8b573a3ee6  lifestage_dictionary_09_15_2026.rds
503cd3392f9514d4911fc01753d2cd264a19c03e457e4f4494a91d7cde69b79b  lifestage_review_09_15_2026.csv
5ee07ccacdc62ea63fe27b6b0ce091226f6eac42283a4df429d215b0a3cdee66  lifestage_review_09_15_2026.parquet
608b7164eed4d0c916fb81671dd336f44d25f9394aca364fbc935b02447846c9  lifestage_review_09_15_2026.rds
```
