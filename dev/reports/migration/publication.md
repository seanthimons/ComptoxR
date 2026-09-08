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
  checks passed. Database download verification and withdrawal remain pending.

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
