# Migration publication evidence

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

`database-withdrawal.json` records the checked asset state. The runnable
`verify_published_database.R` verifies native tables, explicit release mapping,
source-column preservation, matching installed/local HTTP behavior, and unchanged
database hashes. Local command logs are retained under the production-endpoints
worktree's `.migration-evidence/published-database/` and
`.migration-evidence/published-harmonizer-september/`.
