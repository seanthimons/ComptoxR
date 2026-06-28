

# ComptoxR NEWS

## Unreleased (2026-06-28)

#### Breaking changes

- migrate from httr to httr2 across all API functions
  ([6d96532](https://github.com/seanthimons/ComptoxR/tree/6d9653248790fa8e50b0345e8b2585f699b71e03))

#### New features

- add CTS functions, new cassettes, and infrastructure updates
  ([91b2baa](https://github.com/seanthimons/ComptoxR/tree/91b2baa22a38cd96b9eab4fa26ca6cb1c7f2b455))
- implement GenRA read-across prediction workflow
  ([32597d7](https://github.com/seanthimons/ComptoxR/tree/32597d70f2b4c9f911a247f9f538713ae8f5371e))
- rename tox\_\* functions to toxval\_\* and add ToxValDB integration
  ([628636d](https://github.com/seanthimons/ComptoxR/tree/628636dd2aedd4b18031f382110f4fc3a85f8927))
- add GitHub Release download, harden build pipeline, add diagnostics
  ([9740cba](https://github.com/seanthimons/ComptoxR/tree/9740cbadd71f8e749fbde455b302ccc2df97b875))
- add ToxValDB integration with local DuckDB + Plumber modes
  ([cdba585](https://github.com/seanthimons/ComptoxR/tree/cdba585832e0fa0de170196d1ee5731c51e5f558))
- add build-from-source ETL pipeline
  ([6bbeebb](https://github.com/seanthimons/ComptoxR/tree/6bbeebb7c6cf0fa580fbec7a88207fe15907608b))
- add core query functions for ECOTOX database
  ([7bd28b7](https://github.com/seanthimons/ComptoxR/tree/7bd28b748644c378aa221bac0839bde1fa3ad5bf))
- add server config, connection management, and install stub
  ([268e287](https://github.com/seanthimons/ComptoxR/tree/268e2870f157ef9b7e62469faaa22eee53152932))
- add local DSSTox database query layer with hardened SQL
  ([76a4108](https://github.com/seanthimons/ComptoxR/tree/76a4108b84b007e7a47c61ee7c32c2bf3c7da192))
- add documentation, tests, and NAMESPACE exports
  ([65247f2](https://github.com/seanthimons/ComptoxR/tree/65247f2dc9c2acbe146adf5f9c090408e57dab48))
- add util_pubchem_resolve_dtxsid with CAS fallback
  ([8edb60d](https://github.com/seanthimons/ComptoxR/tree/8edb60d403c23260d5b8d9fdb7dbd7845e596ac2))
- add pubchem_search, pubchem_properties, pubchem_synonyms
  ([425a526](https://github.com/seanthimons/ComptoxR/tree/425a5260309b4fd10248fe7f19f3accd3e9c655b))
- add PubChem PUG REST infrastructure
  ([73499b3](https://github.com/seanthimons/ComptoxR/tree/73499b393cf7f643480a53d2e5a2d2f1e5dc2ce9))
- add coverage deltas to schema automation PR body
  ([abc3997](https://github.com/seanthimons/ComptoxR/tree/abc3997c6634ce27a677e78e3dceba80c7149db5))
- add retry with exponential backoff to all generic request templates
  (#75)
  ([0888eb3](https://github.com/seanthimons/ComptoxR/tree/0888eb3facdc97208a41417f192b9ad5e38ee5d8))
- collapse list-columns to semicolon-separated strings in safe_tidy_bind
  ([07a1dce](https://github.com/seanthimons/ComptoxR/tree/07a1dcec0f7267788e98a04fbe295a3a0c0755b2))
- warn when pagination hits max_pages limit
  ([c55a739](https://github.com/seanthimons/ComptoxR/tree/c55a73979e8b5273731c5819311250c6aab506f9))
- integrate pagination metadata into stub generation pipeline
  ([81de76d](https://github.com/seanthimons/ComptoxR/tree/81de76d79289694b62ddb40517c196c1974a8564))
- added package_sitrep function for portable + safe diagnostics
  ([d67a774](https://github.com/seanthimons/ComptoxR/tree/d67a774a0cb53cf9eaaa42ad210c86102746b716))
- add new cheminformatics API wrapper stubs
  ([5cd22a8](https://github.com/seanthimons/ComptoxR/tree/5cd22a8394fd9f58e38039b20c3bcb43cb58aff5))
- integrate function stub generation into schema update workflow
  ([3eb9c39](https://github.com/seanthimons/ComptoxR/tree/3eb9c39227bf7af9935d19e80e09645c353ec3d2))
- add ‘none’ option to release workflow for creating releases without
  version bump
  ([614524e](https://github.com/seanthimons/ComptoxR/tree/614524e7fec993ab6b0ed5ab18d6df322dd1f75b))
- update to 1.4.0 with new functions and features
  ([e2a6cdf](https://github.com/seanthimons/ComptoxR/tree/e2a6cdf0858e64ec1cd03b09bca02046324b714c))
- updated common_chemistry functions, promoted some to `stable`
  ([73276bc](https://github.com/seanthimons/ComptoxR/tree/73276bc30d24408ab9857ca82b38ac103da6c3ec))
- added Common Chemistry auth, schema, and loading functions. Updated
  workflow to also check for schema updates.
  ([05a176f](https://github.com/seanthimons/ComptoxR/tree/05a176fd2e49848b40fb35fc07e3ff004695fef9))
- stable promotion for chemi_resolver functions (they work as-is).
  ([c40cd94](https://github.com/seanthimons/ComptoxR/tree/c40cd9415f0db3b44002df8fa44769475e707ffb))
- complete Phase 6 stub generation with flattened query parameters -
  Generate 117 chemi function stubs with proper query parameter
  handling - Add 2 new stubs: chemi_amos_get_classification_for_dtxsid,
  chemi_toxprints_calculate - Fix extract_query_params_with_refs() to
  correctly flatten nested schemas - Update ENDPOINT_EVAL_UTILS_GUIDE.md
  with Phase 1-5 documentation: - Add Schema Preprocessing section
  (preprocess_schema, filter_components_by_refs) - Add resolution docs
  (resolve_schema_ref, extract_query_params_with_refs) - Document new
  tibble columns (request_type, body_schema_full, body_item_type) -
  Update mermaid diagrams with preprocessing and resolution flows -
  Expand Key Functions Reference and Quick Reference tables - Restore
  chemi_endpoint_eval.R to production state - Update progress.md with
  Phase 6 completion status
  ([40b4b77](https://github.com/seanthimons/ComptoxR/tree/40b4b77a75d1511b88c1b0ce60b0f294315ccb34))
- Phase 5 - Query parameter $ref resolution
  ([23ab8c8](https://github.com/seanthimons/ComptoxR/tree/23ab8c888bdd8d562fad361b984adbad0bdd8991))
- Phase 4 - Code generation updates using request_type classification
  ([87414cf](https://github.com/seanthimons/ComptoxR/tree/87414cf1d764c67c61b7f4d5ecb250a3f16148cc))
- RQ codes now return tidy data or NULL, depreciated chemi_rq function.
  ([83c52fe](https://github.com/seanthimons/ComptoxR/tree/83c52fe1b48dcdcaef5b71d9b4bf36b72229bd14))
- added stubbed out chemi\_ functions + docuementation
  ([5298683](https://github.com/seanthimons/ComptoxR/tree/529868315f7dcc7f5592fb29467eb49fa403e1f9))
- updated chemi_search
  ([f725a88](https://github.com/seanthimons/ComptoxR/tree/f725a88c882a418247f958dee74a821ab29525e8))
- updated chemi_search
  ([77b7f76](https://github.com/seanthimons/ComptoxR/tree/77b7f764e2e32ad4a2fb7f1762c0f0da24dd45c5))
- finished scaffolding other functions
  ([60f7d4c](https://github.com/seanthimons/ComptoxR/tree/60f7d4c415386714183619019252e445f1824b90))
- built out chemi scaffolding
  ([7b123a3](https://github.com/seanthimons/ComptoxR/tree/7b123a3ce5e8b025896720d5247f830c0993d070))
- added endpoint evaluation + stubbing functions.
  ([b0bbd13](https://github.com/seanthimons/ComptoxR/tree/b0bbd13ebd101f2a3d5c1bcbd43c3e2c6fea7f72))
- added unicode cleaning function
  ([6ec5451](https://github.com/seanthimons/ComptoxR/tree/6ec545108cfcc07800bd6d3e64d413fc37acbbc8))
- added support files and hashes for file age on schema
  ([ff3d3ba](https://github.com/seanthimons/ComptoxR/tree/ff3d3bacad98edb9ed584f2e1d7a275d05579788))
- adds schema updates and initial loading behavior based upon status.
  ([4bab173](https://github.com/seanthimons/ComptoxR/tree/4bab17365d820d9cf32764409d6a81d8f8ca7163))
- added two compounds to testing set, and rebuilt ct_details.
  ([168bf99](https://github.com/seanthimons/ComptoxR/tree/168bf999c27db26f0c49601b70a21cd6782b2092))
- server pathing updates, documentation updates
  ([df27133](https://github.com/seanthimons/ComptoxR/tree/df2713341bca2182a9830bf506741c4717548930))
- fixed ct_env_fate(), now should return more informative errors and
  final data as tibble.
  ([effcca2](https://github.com/seanthimons/ComptoxR/tree/effcca2ff7d47712b79d39fbe899ce9dbf03c16e))
- update to schema and servers; will now try all servers and allows for
  fallback to developement to generate endpoint lists.
  ([e1f50f8](https://github.com/seanthimons/ComptoxR/tree/e1f50f80a8c78f8f19401f2556943e89725a1dca))
- schema now checks latest server for all endpoints, removed hardcoded
  endpoint list.
  ([a3970d5](https://github.com/seanthimons/ComptoxR/tree/a3970d576a7aafc685385743331753758f28994d))
- updated older functions
  ([52b19e9](https://github.com/seanthimons/ComptoxR/tree/52b19e94b89994720b6578e25062269be7c23ef4))
- added global POST request limit, now sets on initial load
  ([c8d6245](https://github.com/seanthimons/ComptoxR/tree/c8d6245773642f761f24dbf0ec7160e63aed2264))
- added ct_bioactivity_models for grabbing ToxCast model outputs.
  ([625eeea](https://github.com/seanthimons/ComptoxR/tree/625eeea00a4a7d5b3440fe7d7e12332c36aa234a))
- added chemi\_ schema downloading
  ([10d5b0f](https://github.com/seanthimons/ComptoxR/tree/10d5b0fd67a228209455dae058783b08e59013ca))
- added chemi_functional_use for export
  ([676afe6](https://github.com/seanthimons/ComptoxR/tree/676afe6637d42d571e1920ec1847a085a58c92b6))

#### Bug fixes

- qualify purrr::discard_at in cc_detail
  ([16ab9a8](https://github.com/seanthimons/ComptoxR/tree/16ab9a80aa97bb848f021976cf4daa7dbdeb7a4f))
- skip suite-level reload when ComptoxR namespace already loaded
  ([7b56785](https://github.com/seanthimons/ComptoxR/tree/7b56785618490112098f9645509e5bb56046f475))
- guard generated-contract helper against mid-suite namespace reload
  ([3f1dc49](https://github.com/seanthimons/ComptoxR/tree/3f1dc49d1314354471b6aa57d8605fab340cecfc))
- disambiguate generated wrapper name collisions and seed example
  sampler (#214)
  ([5d54ccf](https://github.com/seanthimons/ComptoxR/tree/5d54ccfe9ed1f07d20eff203d565417c3b87f965))
- use bulk resolver POST for chemi\_\*\_bulk stubs
  ([e62e3b4](https://github.com/seanthimons/ComptoxR/tree/e62e3b4cb23acafe174802d29b890dcad1f1d3e8))
- WR-01 add regression test for GO:0040007 contamination in lifestage
  baseline
  ([41a18dd](https://github.com/seanthimons/ComptoxR/tree/41a18dd08fe24475aa7a4a4fc2d0ed431eef39d4))
- WR-02 add skip_if_not_installed(readr) guard to lifestage tests
  ([902e912](https://github.com/seanthimons/ComptoxR/tree/902e912c5d5d08777a22f3d56cc05bd7d4c6fda2))
- revise plans based on checker feedback
  ([f633df2](https://github.com/seanthimons/ComptoxR/tree/f633df2861fbe03db4c1d4ae4d99d3b8d451d152))
- NVS error paths return typed empty tibble instead of zero-column
  tibble
  ([90ff818](https://github.com/seanthimons/ComptoxR/tree/90ff818eb8bccebcbfcfb2752657beece936513b))
- add DuckDB connection validity guard in confirm_gate.R
  ([42adcda](https://github.com/seanthimons/ComptoxR/tree/42adcda6ead7334e67777807cd3bf4265a720f4b))
- WR-02 align classifier patterns with dictionary for 6 disagreeing
  terms
  ([d71c262](https://github.com/seanthimons/ComptoxR/tree/d71c262cd399039c79b184ccd5b4b697746ce3f1))
- WR-01 move alevin from Juvenile to Larva classifier pattern
  ([906be38](https://github.com/seanthimons/ComptoxR/tree/906be38d5aabdecc24df525755906be8b49defb5))
- add connection validity fallback with read_only safety
  ([a50b37d](https://github.com/seanthimons/ComptoxR/tree/a50b37d6b54d5fe024dab134825236ec39922cc2))
- store DuckDB driver reference to prevent GC invalidation
  ([3fea98d](https://github.com/seanthimons/ComptoxR/tree/3fea98d4ea02a48aa24bd6bec815868843b048b8))
- move environment setup from .onAttach to .onLoad
  ([807f2a0](https://github.com/seanthimons/ComptoxR/tree/807f2a0b3685519cc4f7c4b5d28449b69c5d8ab2))
- dsstox + package sitrep adjustment
  ([ad692d9](https://github.com/seanthimons/ComptoxR/tree/ad692d94fcd738590ba9adff3f31a062ad22435d))
- change to build process for DSSTOX
  ([9ed0181](https://github.com/seanthimons/ComptoxR/tree/9ed0181eaf73aa27884a83394e987ca3b582c3b6))
- variable name update
  ([084814c](https://github.com/seanthimons/ComptoxR/tree/084814c7bbb9f74266cf67ee38111ad3d9815351))
- adjustments for PR review
  ([d9c72fe](https://github.com/seanthimons/ComptoxR/tree/d9c72fe28f10433b196b742f227cdab419e5c1cf))
- remove remaining toxval_server()/toxval_path() double-call patterns in
  test files
  ([1d087a0](https://github.com/seanthimons/ComptoxR/tree/1d087a04c693fcee788fe46934cb3e224a9e2cca))
- resolve HIGH/MEDIUM findings from PR review (env var, test names,
  human_eco, plumber, dss/eco fallback)
  ([b202379](https://github.com/seanthimons/ComptoxR/tree/b202379dca95bc4b90deb2b969ca1ab7133a3789))
- add permissions, TAG validation, and staleness guard to db-\*.yml
  workflows
  ([991cf2f](https://github.com/seanthimons/ComptoxR/tree/991cf2f1a87efb81638e44ea20259674496a887c))
- fix build pipeline invocation, Clowder endpoint, and test gaps
  ([8169954](https://github.com/seanthimons/ComptoxR/tree/81699544d50d9f6db1a2f116755a9b49698a947b))
- resolve PR #136 round 2 review findings
  ([f761078](https://github.com/seanthimons/ComptoxR/tree/f7610781f783b234f00d9889843953689018140e))
- address remaining PR review issues
  ([a42777e](https://github.com/seanthimons/ComptoxR/tree/a42777ee863781d40bc11bd32580f72b88de64c2))
- address PR #136 review findings (HIGHs + MEDIUMs)
  ([f05317f](https://github.com/seanthimons/ComptoxR/tree/f05317f1aabf49ceefb23c12a40520904ef8c91e))
- plumber defaults, startup display, and test robustness
  ([3e0b424](https://github.com/seanthimons/ComptoxR/tree/3e0b42446af6ae090be0a20795cafe7d41987d07))
- use existing is_cas() instead of duplicate is_valid_cas()
  ([a7e2511](https://github.com/seanthimons/ComptoxR/tree/a7e2511e6b938054dffe67462b77b84a9d441b38))
- add tidyr and tibble to badge workflow dependencies
  ([13be782](https://github.com/seanthimons/ComptoxR/tree/13be78284805b8d3f32710822da406cf25261587))
- add tidyr and tibble to badge workflow dependencies
  ([a391d8a](https://github.com/seanthimons/ComptoxR/tree/a391d8a559d5f8fd642efa0be907dd126d6a49ce))
- run badge coverage calculation from integration branch
  ([0cd8236](https://github.com/seanthimons/ComptoxR/tree/0cd8236ba4d6588acf47f6831b4ca9ae2536b661))
- run badge coverage calculation from integration branch
  ([52a6d73](https://github.com/seanthimons/ComptoxR/tree/52a6d73146b62aaeb514983d17ed094671c8c8f5))
- add missing R dependencies for coverage badge workflow
  ([452cbec](https://github.com/seanthimons/ComptoxR/tree/452cbecb0a7b6c49b6516e5191696b21308a44c3))
- add missing R dependencies for coverage badge workflow
  ([46324d4](https://github.com/seanthimons/ComptoxR/tree/46324d491246267d13b6fdd5756ccd6df8d3b5e3))
- resolve GHA failures and bump action versions
  ([3c8d033](https://github.com/seanthimons/ComptoxR/tree/3c8d0335e5ffe144e30a9fdc62e20d76701b1b93))
- resolve GHA failures and bump action versions
  ([fb7388b](https://github.com/seanthimons/ComptoxR/tree/fb7388bd14dd42e58b48e2dde16efb71ee3b7740))
- strip ‘ccd’ slug and hyphens from ct\_\* function name generation
  ([3bcbefe](https://github.com/seanthimons/ComptoxR/tree/3bcbefeab6132d0fb8d42a9ed0f78aa5397b648d))
- align coverage calculator with shared utilities and surface skip
  counts
  ([4345452](https://github.com/seanthimons/ComptoxR/tree/434545238039b090d17423241b3ebcd70573236b))
- handle schema filenames with non-standard hyphen counts
  ([eea5e68](https://github.com/seanthimons/ComptoxR/tree/eea5e683434e2de5fccb347ee4b7ed6d88786343))
- exclude non-API endpoints and non-schema files from diff
  ([500d8de](https://github.com/seanthimons/ComptoxR/tree/500d8de366a2448b43745a36e0a7fd02ec1f2598))
- use string comparison for stubs_generated gating
  ([a69ff56](https://github.com/seanthimons/ComptoxR/tree/a69ff56e32284ed8ea89d29071bfd2c81cecaa4a))
- gate devtools::document() on actual stub generation
  ([04fd081](https://github.com/seanthimons/ComptoxR/tree/04fd081138cc7199b3812a761043798bf9fa6b7a))
- fix test params, add cassette error checker, create testing guide
  ([197ffee](https://github.com/seanthimons/ComptoxR/tree/197ffeea531aa4a3d0ee6089001de1ab561914b6))
- clarify CLI output for candidate vs API wrapper file counts
  ([8ce42ae](https://github.com/seanthimons/ComptoxR/tree/8ce42ae7098dbc0fcb266850c23f192966b6f6fa))
- protect stable functions from stub generator overwrite (#95)
  ([1d0bdad](https://github.com/seanthimons/ComptoxR/tree/1d0bdad559c3eaf8d123ce4dce8232c5c26bcf93))
- replace non-existent ct_bio_assay_all() with ct_bioactivity_assay()
  ([8854d2d](https://github.com/seanthimons/ComptoxR/tree/8854d2d0a60016d106afb1e518f605b0eaf7e90a))
- pre-scan list fields in safe_tidy_bind to prevent type conflicts
  ([41b0909](https://github.com/seanthimons/ComptoxR/tree/41b090913f7cd7534187da3ae63c9b1e46d94ba6))
- unwrap named response containers in offset_limit pagination callback
  ([0028957](https://github.com/seanthimons/ComptoxR/tree/00289578a32217b771fd5571ae4fbe3a722732ad))
- remove schema_old from tracking and prevent stale diff baselines
  ([869b489](https://github.com/seanthimons/ComptoxR/tree/869b489a67a3368fdde7d95c9b4e11a409297111))
- regenerate paginated stubs with correct defaults
  ([d6ef344](https://github.com/seanthimons/ComptoxR/tree/d6ef344ff18c2aee1d574f20bdfbb521796f253f))
- clean up schema_old directory after diff step
  ([b08444f](https://github.com/seanthimons/ComptoxR/tree/b08444f4a4524501cfbd022b9c56767c2119fa87))
- gracefully skip body-only endpoints with no extractable params
  ([1f3ac60](https://github.com/seanthimons/ComptoxR/tree/1f3ac60dc7cb5cbd5ec9c0090fddd739ecaf66de))
- pretty-print chemi schemas at download time
  ([1a6dd9d](https://github.com/seanthimons/ComptoxR/tree/1a6dd9d0f4d4283ca6cd1484fd1bd9f4c7aa25f5))
- source diff_schemas.R without pre-loading parser
  ([6bd3c52](https://github.com/seanthimons/ComptoxR/tree/6bd3c52105b2843255f9cf170bd521351a28d49c))
- pretty-print schemas and list changed files in PR body
  ([519c629](https://github.com/seanthimons/ComptoxR/tree/519c629146915711dd9ec97ffe923284aa0982b2))
- correct test expectations for pipeline functions
  ([2edef01](https://github.com/seanthimons/ComptoxR/tree/2edef01a05e5b06688b82a8d862a58d99a741de9))
- handle vector primary_example in stub generation
  ([204ca5d](https://github.com/seanthimons/ComptoxR/tree/204ca5de33d5ca340d99b4b24278eb6045e6fb45))
- remove aggressive schema component filtering
  ([b24131f](https://github.com/seanthimons/ComptoxR/tree/b24131f198416159e1420bf1ae10f94a8d425d28))
- add object_array body type support for inline object arrays
  ([be45e0f](https://github.com/seanthimons/ComptoxR/tree/be45e0f8dcda8b3c0b95cbf73bc63c364b24259a))
- changed production URL for tests.
  ([3ed7718](https://github.com/seanthimons/ComptoxR/tree/3ed77184b0a1d5c9e88b1bee4e5da18ab4b2898e))
- Suppress startup messages for CRAN compliance
  ([ab8124c](https://github.com/seanthimons/ComptoxR/tree/ab8124c6a5aa2e5ce0949dd2a03d476b49372c58))
- updated workflows to not infinite-trigger
  ([83a0856](https://github.com/seanthimons/ComptoxR/tree/83a08563689a5bad5ccdab1bf44ed335142e125e))
- disabled workflows while debuggin building errors
  ([f56d6b3](https://github.com/seanthimons/ComptoxR/tree/f56d6b36bdb0315621ab4cf00acfa8031506ec6c))
- workflow updates
  ([ce1ce0b](https://github.com/seanthimons/ComptoxR/tree/ce1ce0bcd574614199d1c284980c8e218763890a))
- Phase 5 bug fixes and circular reference detection
  ([ab24b92](https://github.com/seanthimons/ComptoxR/tree/ab24b922d041933f26bba5af5d463055ac25f631))
- update DESCRIPTION + promote some functions to stable
  ([96d91e3](https://github.com/seanthimons/ComptoxR/tree/96d91e3953c1b71c2fc8886279da1f37bf1804b4))
- update workflow to only run on dev branch
  ([fef0f97](https://github.com/seanthimons/ComptoxR/tree/fef0f97413c2aedfa9e966d54137fcba56eac63e))
- adjusted search regex for not yet built functions
  ([f785f81](https://github.com/seanthimons/ComptoxR/tree/f785f81e58797adf8439a32d71e4bc487b7231c9))
- fixed logic and stubbing generation
  ([045ec10](https://github.com/seanthimons/ComptoxR/tree/045ec10cd6142312d803b334496818d97cccb294))
- Add CRAN mirror to Install dependencies step
  ([c4ecce6](https://github.com/seanthimons/ComptoxR/tree/c4ecce65c755470e798ec322a9d434c44dc3638e))
- add permissions and fetch-depth for schema PR creation
  ([db1a3f1](https://github.com/seanthimons/ComptoxR/tree/db1a3f1bdf42cd2fc82e3772e861b4de17fb5a6d))
- add permissions and fetch-depth for schema PR creation
  ([e485842](https://github.com/seanthimons/ComptoxR/tree/e485842eaeb869a5aaff577e0d2111d842058db8))
- add permissions and fetch-depth for schema PR creation
  ([51b8df5](https://github.com/seanthimons/ComptoxR/tree/51b8df56e3d1bca202e27070b94a520adfa9ee6b))
- adjusted stubbing for content type
  ([440ef09](https://github.com/seanthimons/ComptoxR/tree/440ef09c510749188a2cc9bc8b6490197286fa4e))
- adjustment to test YAML
  ([db94f63](https://github.com/seanthimons/ComptoxR/tree/db94f63b0bfc1c7b95b8255bee5bd8366b1f8c83))
- updated misc functions feat: Adjusted functional usage / exposure
  functions
  ([ff921e7](https://github.com/seanthimons/ComptoxR/tree/ff921e7a1d6abf20992a685294d43935dfd89ace))
- adjusted the generic functions to handle things like projections.
  ([60d42f6](https://github.com/seanthimons/ComptoxR/tree/60d42f6612355a5c56402958d1baab6e523519fe))
- updated the loading logic for run\_\* flags
  ([21c8690](https://github.com/seanthimons/ComptoxR/tree/21c86909eb5c0be728b9be5fcd07870938aaa181))
- added latency calculatiosn to ping test to diagnose routing issues.
  ([08eb2a3](https://github.com/seanthimons/ComptoxR/tree/08eb2a3560e519a3d54e207bc615be95fff28d69))
- updated generic request to strip out empty strings and NAs
  ([95b0a6b](https://github.com/seanthimons/ComptoxR/tree/95b0a6bb5f6c39136830575823b82ea1d1fe3530))
- minor update to generic request: now asserts type of query request
  better.
  ([80d5e3b](https://github.com/seanthimons/ComptoxR/tree/80d5e3be9cbd077b1bdf04e29c091e6a0a089beb))
- type on server pathing
  ([725f552](https://github.com/seanthimons/ComptoxR/tree/725f552bb838bcaeae1ebc077383f96b9a662c56))
- for smaller queries under batch limit, enclose them into a list.
  ([55bcb36](https://github.com/seanthimons/ComptoxR/tree/55bcb36fd423c13c69806c3cf2debea38cf392c7))
- updated schema generation and initial load testing for API key
  ([570d513](https://github.com/seanthimons/ComptoxR/tree/570d5137d895ab70f6b7be0b6f7908911ef2095b))
- updated clustering + resolver services.
  ([7eb455d](https://github.com/seanthimons/ComptoxR/tree/7eb455d8249f782985ddf85358a1696e08d8f3ab))
- server update
  ([efba09b](https://github.com/seanthimons/ComptoxR/tree/efba09b6d89a82a5822eb279a44af95df19dcb8f))
- update chemi_classyfire for error message
  ([6d5545c](https://github.com/seanthimons/ComptoxR/tree/6d5545cfd098d7c30fe2791c3c86130fbf1eeff1))
- update to ct_related
  ([e35fa1a](https://github.com/seanthimons/ComptoxR/tree/e35fa1ad569ceec4dcbb6e2cc8f13bda6d355f92))

#### Refactorings

- drop non-idiomatic helper-sourcing preamble from chemi_predict test
  (#218)
  ([ee7b6cb](https://github.com/seanthimons/ComptoxR/tree/ee7b6cb7b441371770eac89dd18058ed1c0fba4c))
- collapse four stub generators into one config-driven runner
  ([c54b52c](https://github.com/seanthimons/ComptoxR/tree/c54b52c0c4d0d85627acf4ccd288f9aba90a1fed))
- overhaul pipeline scripts, add test fixtures, and clean up legacy
  files
  ([7111076](https://github.com/seanthimons/ComptoxR/tree/7111076b96005b35833c043d7d9651fde4952133))
- ship lifestage patch seed
  ([5218eab](https://github.com/seanthimons/ComptoxR/tree/5218eab2e1214b9c2c7a8e371688136ba9b35686))
- add safe_tidy_bind() helper for robust list-to-tibble conversion
  ([c26aab2](https://github.com/seanthimons/ComptoxR/tree/c26aab25e8f930bf9e0fce2000a10c6e23f50412))
- standardize API requests and migrate to httr2
  ([e107a94](https://github.com/seanthimons/ComptoxR/tree/e107a944b7e5fe421158aa449301b0aacfab296c))

#### Tests

- cover resolve-then-POST resolver cluster against branch contract
  (#219)
  ([a0507c3](https://github.com/seanthimons/ComptoxR/tree/a0507c3ee4628bde82cf95d69914e6e23aca5eb0))
- cover pubchem properties, search, and synonyms branching and shaping
  (#221)
  ([af52ca3](https://github.com/seanthimons/ComptoxR/tree/af52ca3eee80ac9b68a34a5486f4f58291adb761))
- cover cc_detail single and multi result response shaping (#220)
  ([0e92b38](https://github.com/seanthimons/ComptoxR/tree/0e92b382bf90bbe9d9d9bda8ce53b5cd80be5c99))
- cover chemi_resolver_lookup_bulk validation boundary (#219)
  ([9867cc3](https://github.com/seanthimons/ComptoxR/tree/9867cc341f23228d893d9c46a4e9cb07eda6ec25))
- cover chemi_predict resolution, report, and error branches (#218)
  ([24e085e](https://github.com/seanthimons/ComptoxR/tree/24e085ed8ff4684b7f363fdf722d1f64bff94349))
- retire stale vcr test infrastructure
  ([93313b8](https://github.com/seanthimons/ComptoxR/tree/93313b852def1c0be52245b283283a027d750aa6))
- persist verification, review, and human UAT items
  ([24698dc](https://github.com/seanthimons/ComptoxR/tree/24698dcd15ee32a0e6e9dadb592a1b611a8fdf1f))
- Phase 6 integration testing with documentation
  ([5d042b2](https://github.com/seanthimons/ComptoxR/tree/5d042b2780086bd1ff16bbf7c06b3f86c711c149))

#### CI

- generate NEWS.md on pull requests; skip heavy checks on non-package
  changes
  ([66d51e8](https://github.com/seanthimons/ComptoxR/tree/66d51e87443a8c3aebfb83bc9859ac4cabe06e87))
- allowlist EPA NEPIS fixture doc IDs
  ([f2cd01f](https://github.com/seanthimons/ComptoxR/tree/f2cd01f4d18b156ff210af6143cab4496e8ea87a))
- remove build-databases.yml, superseded by per-DB workflows
  ([fafb1ae](https://github.com/seanthimons/ComptoxR/tree/fafb1aea60b0d1804a5278dc217513f11a31f283))
- add per-DB release asset workflows with staleness checks
  ([9e83ed2](https://github.com/seanthimons/ComptoxR/tree/9e83ed2e3ec03dbf509614af2c54aca2249ff8e2))
- expand gitleaks workflow triggers - Add scheduled runs (Mon, Wed, Fri
  at 9am UTC) - Include integration branch in push/PR triggers
  ([8aa7806](https://github.com/seanthimons/ComptoxR/tree/8aa78068040bc48525eeecd8cf0038e694c7e785))
- add schema update check workflow
  ([7e06f89](https://github.com/seanthimons/ComptoxR/tree/7e06f895ab71eb740edd2282f093470332eab0b8))
- add schema update check workflow
  ([7338942](https://github.com/seanthimons/ComptoxR/tree/7338942c95322d87a946395ca205aca3e6e4d7d2))
- add schema update check workflow
  ([edd3bb3](https://github.com/seanthimons/ComptoxR/tree/edd3bb399f315f1d6efff4fd1fc1e5ee7c098b69))

#### Docs

- add wrapper test rubric and contributor pointers (#212)
  ([74bd4b9](https://github.com/seanthimons/ComptoxR/tree/74bd4b971e86546e9b10c4972386a24fb02397ac))
- record phase 36.2 context session
  ([0b2952b](https://github.com/seanthimons/ComptoxR/tree/0b2952b3a10b4ce960efa1976868aba34edbf73d))
- create phase plan for bootstrap data artifacts
  ([f759198](https://github.com/seanthimons/ComptoxR/tree/f759198d852be121de1bdc14634a55a63584a881))
- capture phase context
  ([baafecb](https://github.com/seanthimons/ComptoxR/tree/baafecb4fc56d2514e034d99c44ad4608ad8ad3a))
- capture phase context
  ([a66d7bc](https://github.com/seanthimons/ComptoxR/tree/a66d7bc830a1791861ff8148f4dbc5413c95ab4c))
- record phase 34 context session
  ([7d44e0b](https://github.com/seanthimons/ComptoxR/tree/7d44e0b45265c47f9152da99d403465aafa4e90e))
- capture phase context
  ([f80cb3f](https://github.com/seanthimons/ComptoxR/tree/f80cb3f53707a8bfdcfa27cbdcbc31f9d6c45518))
- complete v2.4 lifestage resolution research
  ([25fdd55](https://github.com/seanthimons/ComptoxR/tree/25fdd5564a979ed48445c0fd403a6129623434b8))
- create phase plan for build confirmation
  ([0cc5de1](https://github.com/seanthimons/ComptoxR/tree/0cc5de1378d38fb914461166e1a398088ceed97d))
- create phase plan for build pipeline integration
  ([c6c7ea6](https://github.com/seanthimons/ComptoxR/tree/c6c7ea63477f23b04f59675bc0be67c69503547f))
- create phase 31 standalone validation plans
  ([13cc790](https://github.com/seanthimons/ComptoxR/tree/13cc7906f5dec078b3320bc845679f11bc18fd16))
- create phase plan for build quality validation
  ([8ffb500](https://github.com/seanthimons/ComptoxR/tree/8ffb500578787f0baa94acb150cde1719bdce5d1))
- record phase 30 context session
  ([2ce709e](https://github.com/seanthimons/ComptoxR/tree/2ce709e062da34fbe08312b39a2d0c815d9c9381))
- capture phase context
  ([7c457db](https://github.com/seanthimons/ComptoxR/tree/7c457db4564a4ce080d415bc7415d6c8db9445b3))
- create phase plan for direct template migration
  ([33da222](https://github.com/seanthimons/ComptoxR/tree/33da2222eb523e854cac88c6a73b95430a2dc94e))
- record phase 29 context session
  ([1e2d05d](https://github.com/seanthimons/ComptoxR/tree/1e2d05d87a2e876f701186f8d237b83461568c16))
- capture phase context for direct template migration
  ([9c7694f](https://github.com/seanthimons/ComptoxR/tree/9c7694fd078dd6de80d43cfb407bdecbf2a75d9d))
- create phase plan for thin wrapper migration
  ([11d4d21](https://github.com/seanthimons/ComptoxR/tree/11d4d211cb71ad9a67c7174f54f612ad0ceb548c))
- record phase 28 context session
  ([9e47a3c](https://github.com/seanthimons/ComptoxR/tree/9e47a3c1390c372d5d3405aede939b6e81d067df))
- capture phase context for thin wrapper migration
  ([6dd74c8](https://github.com/seanthimons/ComptoxR/tree/6dd74c8fa7ed272584c57aec1f5e91c2ed8bfd34))
- create phase plan for test infrastructure stabilization
  ([b1ba67a](https://github.com/seanthimons/ComptoxR/tree/b1ba67a603f6b470bf5e5118967118272888d182))
- complete project research synthesis
  ([05f1a92](https://github.com/seanthimons/ComptoxR/tree/05f1a92b9cb342bad47cf12e20748e4064d338ee))
- create phase plan for pagination tests and coverage hardening
  ([b88e817](https://github.com/seanthimons/ComptoxR/tree/b88e8173489361dce6b5f6c21b3f1099605ee2b9))
- create phase plan for automated test generation pipeline
  ([ca65db7](https://github.com/seanthimons/ComptoxR/tree/ca65db7b32de1bb71a1e1f804d4a83c56074aa52))
- create phase plan for VCR cassette cleanup
  ([29c660c](https://github.com/seanthimons/ComptoxR/tree/29c660c0e11df57cd5a2fe90e867b6922f8b902e))
- create phase plan for build fixes and test generator core
  ([c3ff4f9](https://github.com/seanthimons/ComptoxR/tree/c3ff4f98b83dcd16b8320a36dc06b74a3f667bf6))
- initialize milestone v2.1 Test Infrastructure (4 phases, 30
  requirements)
  ([16d6fd2](https://github.com/seanthimons/ComptoxR/tree/16d6fd2f3886968067fb3bdc8dccba4dc57eb0f8))
- complete project research
  ([0ea4cae](https://github.com/seanthimons/ComptoxR/tree/0ea4caef7df940e1979cec2d063f56ca2e1145a6))
- add blocking build/test issues to TODO and pause feature work
  ([68a657b](https://github.com/seanthimons/ComptoxR/tree/68a657b759f5b3ec3ff97c59e2894420ab84292b))
- sync TODO.md with GitHub Issues #97-#110
  ([55108b1](https://github.com/seanthimons/ComptoxR/tree/55108b10c4318933918c3596604f44b04fe83257))
- add inline TODO comments as separate issues to TODO.md
  ([3d913c8](https://github.com/seanthimons/ComptoxR/tree/3d913c88b2b1b1e8851b013a6869d0137c7eaa31))
- create phase plan for stub generation integration
  ([9c5fab0](https://github.com/seanthimons/ComptoxR/tree/9c5fab015e6af232e0ab04c3e490c25adaba265d))
- create phase plan for reliability improvements
  ([b9107e2](https://github.com/seanthimons/ComptoxR/tree/b9107e281cc60c6a316271010bffaf97f6e17967))
- create phase plan for schema diffing
  ([074fc33](https://github.com/seanthimons/ComptoxR/tree/074fc33563a12f10eea0df2f902f4f3057978794))
- Update progress document with Phase 6 blocking issue
  ([312cadd](https://github.com/seanthimons/ComptoxR/tree/312caddc13cc24fe1d19358162b0accc0e277625))
- Update Phase 5 status with test results
  ([b2cba71](https://github.com/seanthimons/ComptoxR/tree/b2cba715b22d4d7f8baac0d4f2d68e0c06dfe877))
- Update progress document with Phase 5 completion
  ([5fe3b25](https://github.com/seanthimons/ComptoxR/tree/5fe3b256a17331c9bb965012d006d8c47c7825f8))
- progress update
  ([72f0e14](https://github.com/seanthimons/ComptoxR/tree/72f0e1419f8ade41606df5528293e9db93362928))

#### Other changes

- defer cts and common chemistry wrappers
  ([6dccace](https://github.com/seanthimons/ComptoxR/tree/6dccace40429b88bf37feb5223085bf20801e261))
- removed old planning docs
  ([25165f9](https://github.com/seanthimons/ComptoxR/tree/25165f930d374bdb52b7d8807a430ac5a2089b95))
- add CompToxR hex logo
  ([fad93a9](https://github.com/seanthimons/ComptoxR/tree/fad93a99ce27c4bc419ff42d6a36ee82d982652a))
- regenerate wrappers/tests/docs; restore shadowed endpoint variants
  (#214)
  ([c94ca9a](https://github.com/seanthimons/ComptoxR/tree/c94ca9a4610f23e80b0d092d69b2b30b12107784))
- remove inert annotate_assay_if_requested hook and dead config (#214)
  ([a6700eb](https://github.com/seanthimons/ComptoxR/tree/a6700eb0e23aabe5960952aa83ef9c2d7b6938a0))
- refresh unit-test readiness inventory (#184)
  ([32c7e40](https://github.com/seanthimons/ComptoxR/tree/32c7e40b67d9360c78e72507f35ab2133f82768f))
- update API schemas and generate function stubs
  ([bfba81c](https://github.com/seanthimons/ComptoxR/tree/bfba81cf2083befd073f794b58b4c4ec77dcd7ea))
- update API schemas and generate function stubs
  ([0a37488](https://github.com/seanthimons/ComptoxR/tree/0a37488ceb2190dda5c3997ad549c7623bed8b90))
- update API schemas and generate function stubs
  ([324e959](https://github.com/seanthimons/ComptoxR/tree/324e9596c5eb115f780fc2c9b1211b3e0c542066))
- update API schemas and generate function stubs
  ([febab55](https://github.com/seanthimons/ComptoxR/tree/febab55337f4cc76ac6f6d3fcf43f8014488dc98))
- update API schemas and generate function stubs
  ([76ba3d2](https://github.com/seanthimons/ComptoxR/tree/76ba3d21cb8619eb5b425f78675d6391043d235d))
- update API schemas and generate function stubs
  ([6269621](https://github.com/seanthimons/ComptoxR/tree/6269621f0664e27146364bce8d911cee41e0638f))
- archive phase directories from completed milestones
  ([8038b57](https://github.com/seanthimons/ComptoxR/tree/8038b57cc765953f9aa1df9f9ee4bdd658cf3528))
- archive v2.4 milestone
  ([b85befc](https://github.com/seanthimons/ComptoxR/tree/b85befc228f091fed500fe2cadb9b8dde92282f1))
- remove abandoned phase 36.2
  ([549d4bd](https://github.com/seanthimons/ComptoxR/tree/549d4bdaa98b90cfae66bdf487b81b1073aa7de1))
- update API schemas and generate function stubs
  ([6f03254](https://github.com/seanthimons/ComptoxR/tree/6f03254561c0d859761739713930e5520f237544))
- merge executor worktree (worktree-agent-a638f45f)
  ([a8bf901](https://github.com/seanthimons/ComptoxR/tree/a8bf901aa2319a3488d8f04d7ac00c97f259cab8))
- update API schemas and generate function stubs
  ([529c477](https://github.com/seanthimons/ComptoxR/tree/529c477e562ff5a463b038c38c5346bf88a299d4))
- updated PT dataset
  ([9c2c725](https://github.com/seanthimons/ComptoxR/tree/9c2c725db5ecc09f1880e8489cf11ab517eeed89))
- update API schemas and generate function stubs
  ([7fcfff2](https://github.com/seanthimons/ComptoxR/tree/7fcfff2d5e46ade37accca11b7240c54237e8c1b))
- update API schemas and generate function stubs
  ([a3cd0c3](https://github.com/seanthimons/ComptoxR/tree/a3cd0c369dce2c04076d5013909d48ef17a3ae78))
- update to pubchem features
  ([fd14f34](https://github.com/seanthimons/ComptoxR/tree/fd14f3453b6fe419b0f72fc6dc86540efa33303a))
- update API schemas and generate function stubs
  ([672a49d](https://github.com/seanthimons/ComptoxR/tree/672a49d671d26452b7964fa3b93b4caf7252de75))
- update API schemas and generate function stubs
  ([56e3ead](https://github.com/seanthimons/ComptoxR/tree/56e3ead7ac38604e6a7b0aa72bfc65cd856063f5))
- update API schemas and generate function stubs
  ([7ab6a7b](https://github.com/seanthimons/ComptoxR/tree/7ab6a7b826017cb6b7bf7e16c9f2d66710d05fd2))
- update API schemas and generate function stubs
  ([9410781](https://github.com/seanthimons/ComptoxR/tree/94107812b2bd9a3ff826c20e2f0bac0e31a67298))
- update API schemas and generate function stubs
  ([2e445ba](https://github.com/seanthimons/ComptoxR/tree/2e445ba42043da9247d28e547695e85be8be8b3c))
- update API schemas and generate function stubs
  ([e4e0be4](https://github.com/seanthimons/ComptoxR/tree/e4e0be41940889be34be061c40882d6eed4d0dd3))
- function regeneration
  ([7a0f43b](https://github.com/seanthimons/ComptoxR/tree/7a0f43bf75f36eaff6b10c00483e40d5b35e9798))
- update API schemas and generate function stubs
  ([4d0adbf](https://github.com/seanthimons/ComptoxR/tree/4d0adbf8a65342e28fafaf4d07937cbad4ae62b4))
- update API schemas and generate function stubs
  ([bb29d83](https://github.com/seanthimons/ComptoxR/tree/bb29d835677971bb2f36a98a9da516c1ecf15be8))
- update API schemas and generate function stubs
  ([7dab1cc](https://github.com/seanthimons/ComptoxR/tree/7dab1cc3bad5a66fda1af096e2d0a9db43d14219))
- update TODO checkboxes and fix pagination tidy flag
  ([08d8d44](https://github.com/seanthimons/ComptoxR/tree/08d8d447893854b5915049453e52694835c9fb17))
- update API schemas and generate function stubs
  ([135488c](https://github.com/seanthimons/ComptoxR/tree/135488c19c067db4ca260c5c63377e81027f8ebc))
- start v2.0 milestone for paginated requests
  ([78a6357](https://github.com/seanthimons/ComptoxR/tree/78a6357e296641fcd07f7134310d5061c21182c0))
- update API schemas and generate function stubs
  ([a4ffbe3](https://github.com/seanthimons/ComptoxR/tree/a4ffbe30d5ca8c0fe82744168fdbf91fd5d3cd42))
- update API schemas and generate function stubs
  ([659f5e2](https://github.com/seanthimons/ComptoxR/tree/659f5e27e4bb7007c1604f7babfe9bbb0fc0a4f9))
- update API schemas
  ([015a679](https://github.com/seanthimons/ComptoxR/tree/015a679dc432580d87f162d918cfb5296bd8111a))
- sync TODO.md with GitHub Issues and add #86
  ([9ce84ea](https://github.com/seanthimons/ComptoxR/tree/9ce84eaba01e258953133cae03f3c5a3acf73bec))
- update API schemas and generate function stubs
  ([2c3f5b5](https://github.com/seanthimons/ComptoxR/tree/2c3f5b5aaadda2e2bd065b36ad86fded417311fc))
- update API schemas and generate function stubs
  ([7d3ef54](https://github.com/seanthimons/ComptoxR/tree/7d3ef543e804103aa16ca779de4202c2252f1bc6))
- schema update + new functions
  ([befd21d](https://github.com/seanthimons/ComptoxR/tree/befd21d68e90f180cb90010c518fea111e859703))
- update API schemas
  ([8e82e7f](https://github.com/seanthimons/ComptoxR/tree/8e82e7f84d58e1eb7abfee7b7f9c77f5124a6434))
- pipe replacement
  ([2645d93](https://github.com/seanthimons/ComptoxR/tree/2645d933fb74cf6a2a58dc3ddc4f8862f3e3f76e))
- added tests for ct\_\* functions
  ([56c09ec](https://github.com/seanthimons/ComptoxR/tree/56c09ecfd99a4bd531e90d778ce6a7a64181a7d4))
- fixed function and doc rendering
  ([c04b57d](https://github.com/seanthimons/ComptoxR/tree/c04b57d36b73e35ad136530f1900fde33449bdcb))
- update API schemas
  ([1ea7754](https://github.com/seanthimons/ComptoxR/tree/1ea77546650443baf71ab1d9c78ca06714a9a984))
- Update NEWS.md \[skip ci\]
  ([042d25e](https://github.com/seanthimons/ComptoxR/tree/042d25eb6efa3e3c5a4fda65bee2a41eecf34e56))
- Update NEWS.md \[skip ci\]
  ([f7e0fef](https://github.com/seanthimons/ComptoxR/tree/f7e0fef9d8aae756c4177a05151fa86716e6be0d))
- docs update for generic functions
  ([a12cb29](https://github.com/seanthimons/ComptoxR/tree/a12cb292f073f5b59128a8907ff5ede235976e32))
- docs update
  ([4c6f03e](https://github.com/seanthimons/ComptoxR/tree/4c6f03e7917dc8ad854e24bd2d1af977e8305255))
- regeneration of docs and wrappers
  ([3b3cb10](https://github.com/seanthimons/ComptoxR/tree/3b3cb102b96d5ec92aa04565cd64692063429a5a))
- broke up large parsing script into smaller scripts
  ([cd4a3b4](https://github.com/seanthimons/ComptoxR/tree/cd4a3b4f11e77845537f9cddb910e51da7b94ddf))
- docs update
  ([a47fa01](https://github.com/seanthimons/ComptoxR/tree/a47fa015da24438eeda2f99560fae133ca0b8bf2))
- update API schemas (#46)
  ([2edf4dc](https://github.com/seanthimons/ComptoxR/tree/2edf4dc9ea97943456b7bfa3ad8dcb5e0aef29ce))
- update API schemas (#45)
  ([f10c535](https://github.com/seanthimons/ComptoxR/tree/f10c535c3336566eaa371260886b2a9cd469cb12))
- deleted old testing files
  ([d134fc1](https://github.com/seanthimons/ComptoxR/tree/d134fc12c52b67c8e7b0530310c12b0cbf3b9456))
- updated NAMESPACE for new functions
  ([8285cda](https://github.com/seanthimons/ComptoxR/tree/8285cdad8f516fa473fe9c5a20409a0f46ef693a))
- Reorganize repository structure: move dev scripts and test utilities
  to appropriate directories
  ([7668d98](https://github.com/seanthimons/ComptoxR/tree/7668d9837a8f19d3157aec63ba36b57b285b744a))
- deleted old testing files
  ([95a02ad](https://github.com/seanthimons/ComptoxR/tree/95a02ad727b70f2031e68cd847047977488d5039))
- updated build process
  ([6180906](https://github.com/seanthimons/ComptoxR/tree/6180906795041a84327291e85d95c21a2ab583e3))
- updated tests
  ([bab2c46](https://github.com/seanthimons/ComptoxR/tree/bab2c468c92c32b43ac02fabf6d1b29b8d403694))
- added unit testing boilerplate for offline + live testing.
  ([e429f22](https://github.com/seanthimons/ComptoxR/tree/e429f22edc2cc0cd4fe7edf472a98422626f6ac6))
- updates to unit testing harness
  ([c6ddbbb](https://github.com/seanthimons/ComptoxR/tree/c6ddbbb9c9e3a92a31628ca0b2cf4caa2a4a895a))
- Add test infrastructure and tests for ct_env_fate function
  ([de08440](https://github.com/seanthimons/ComptoxR/tree/de08440ce6c952fc7b2a01b9bc73d5bfde12cfbb))

Full set of changes:
[`v1.3.0...66d51e8`](https://github.com/seanthimons/ComptoxR/compare/v1.3.0...66d51e8)

## v1.3.0 (2025-10-02)

#### New features

- updated NEWS.md
  ([d965e6b](https://github.com/seanthimons/ComptoxR/tree/d965e6bd3fb601353beb9ec7a6eb4c41dcf914d6))
- update input component styles and add new features
  ([f75d782](https://github.com/seanthimons/ComptoxR/tree/f75d7829dcc04473df3f563b82fcf097deac9b00))
- updated ct_hazard to new endpoints and added GET / POST methods.
  ([f7f94e5](https://github.com/seanthimons/ComptoxR/tree/f7f94e5f0bc82e6a03543472a47351c93db5a13a))
- added schema download feature
  ([2183b24](https://github.com/seanthimons/ComptoxR/tree/2183b2437c0ecd3a198d778920f53d896cb24360))
- enhance chemi_resolver output and documentation
  ([0875d41](https://github.com/seanthimons/ComptoxR/tree/0875d41ae313fc8dddba02ba6b530f340f18f4bd))
- add batch processing for large chemical queries
  ([7289df3](https://github.com/seanthimons/ComptoxR/tree/7289df3cad6f49b6a723698479320ec8fbf55bc7))
- Add TODO comment for batched query preparation
  ([45244a8](https://github.com/seanthimons/ComptoxR/tree/45244a80e6ef26a3a9e3dc6ad23ee9ea14f346ad))
- improve parameter validation and error handling in chemi_resolver
  ([27113e4](https://github.com/seanthimons/ComptoxR/tree/27113e471bcf661dd6f95d28137b42ec2e62fc61))
- enhance chemi_resolver with ID type and fuzzy search options
  ([e341d7d](https://github.com/seanthimons/ComptoxR/tree/e341d7deb3e5cb9c9af850ac2030f449a78829ec))

#### Bug fixes

- updated documentation
  ([ef36bf9](https://github.com/seanthimons/ComptoxR/tree/ef36bf96fb3c94adab3541dda6a86561d8ffdcff))
- updated file path for ct_file to reflect new directory structure.
  Began to update chemi_search for updated documentation and new
  features.
  ([dee9f0f](https://github.com/seanthimons/ComptoxR/tree/dee9f0ff77b3d0e75d69c134062970bb769d0650))
- minor adjustment to server ping test
  ([d69a45d](https://github.com/seanthimons/ComptoxR/tree/d69a45df49a61c782501440b09ef86ed2f63b273))
- Update server path and added schema download
  ([91c4cc5](https://github.com/seanthimons/ComptoxR/tree/91c4cc586612f0f149690f8bbc9013b42ee4a522))

#### Refactorings

- simplify column renaming in chemi_resolver using rename_with
  ([f6b9548](https://github.com/seanthimons/ComptoxR/tree/f6b954831e731a5f98b8d069dc0e72ef90a0f7fd))
- simplify chemi_resolver query handling and response processing
  ([a1b3de4](https://github.com/seanthimons/ComptoxR/tree/a1b3de4d27591f50a5279c75758702035e60217d))

#### Docs

- Update NEWS.md for release
  ([f7978d4](https://github.com/seanthimons/ComptoxR/tree/f7978d45d14ae885bf331f3afa8927960458c026))
- improve chemi_resolver function documentation
  ([631ca5d](https://github.com/seanthimons/ComptoxR/tree/631ca5d9aedc0a8eb69d3c7745172883d262bd5a))

#### Other changes

- update build script and bump minor version
  ([8554127](https://github.com/seanthimons/ComptoxR/tree/85541272044c1732a01ed8421060afd0666a354a))

Full set of changes:
[`v1.2.2.9009...v1.3.0`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9009...v1.3.0)

## v1.2.2.9009 (2025-08-27)

#### New features

- remove exposure and production volume endpoints
  ([33e8d5b](https://github.com/seanthimons/ComptoxR/tree/33e8d5b1ffde1eb5caf5786ab2c8ccf8ac07fedf))
- reduce POST request chunk size and standardize pipe operators
  ([8cf27a5](https://github.com/seanthimons/ComptoxR/tree/8cf27a5f994ccf1f221a1b7fbf6dd7c40fd9d717))
- add base request class implementation
  ([2d7eb89](https://github.com/seanthimons/ComptoxR/tree/2d7eb89b270a7295fec39011611c75724517d1a5))

#### Bug fixes

- clean up server setup and error messages
  ([ef52836](https://github.com/seanthimons/ComptoxR/tree/ef528360d95f792393e77fc337752487cafd2304))

#### Docs

- update NEWS.md format and build process
  ([ff29ce3](https://github.com/seanthimons/ComptoxR/tree/ff29ce3a6e835db1d749c663eeeb5a1968086942))

#### Other changes

- remove unused/ old R functions, now available through stable/ staging
  documentation.
  ([546df8f](https://github.com/seanthimons/ComptoxR/tree/546df8fcfb9336c31ccc352e8caced2f0b78fd90))
- update GitHub Actions workflow with changelog builder
  ([53177fc](https://github.com/seanthimons/ComptoxR/tree/53177fc68bad7d342a6e77294095ec3ee0a68cbc))

Full set of changes:
[`v1.2.2.9008...v1.2.2.9009`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9008...v1.2.2.9009)

## v1.2.2.9008 (2025-08-18)

#### Style

- replace pipe operator |\> with %\>% for consistency
  ([80a899b](https://github.com/seanthimons/ComptoxR/tree/80a899bdc3701f5c01ce9a4ff3ebbfdde8d7c554))

Full set of changes:
[`v1.2.2.9007...v1.2.2.9008`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9007...v1.2.2.9008)

## v1.2.2.9007 (2025-07-16)

Full set of changes:
[`v1.2.2.9006...v1.2.2.9007`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9006...v1.2.2.9007)

## v1.2.2.9006 (2025-06-18)

Full set of changes:
[`v1.2.2.9005...v1.2.2.9006`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9005...v1.2.2.9006)

## v1.2.2.9005 (2025-06-17)

Full set of changes:
[`v1.2.2.9004...v1.2.2.9005`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9004...v1.2.2.9005)

## v1.2.2.9004 (2025-06-10)

Full set of changes:
[`v1.2.2.9003...v1.2.2.9004`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9003...v1.2.2.9004)

## v1.2.2.9003 (2024-08-21)

Full set of changes:
[`v1.2.2.9002...v1.2.2.9003`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9002...v1.2.2.9003)

## v1.2.2.9002 (2024-06-04)

Full set of changes:
[`v1.2.2.9001...v1.2.2.9002`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9001...v1.2.2.9002)

## v1.2.2.9001 (2024-05-23)

Full set of changes:
[`v1.2.2.9000...v1.2.2.9001`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9000...v1.2.2.9001)

## v1.2.2.9000 (2024-05-14)

Full set of changes:
[`v1.2.0...v1.2.2.9000`](https://github.com/seanthimons/ComptoxR/compare/v1.2.0...v1.2.2.9000)

## v1.2.0 (2023-12-19)

Full set of changes:
[`v1.1.0...v1.2.0`](https://github.com/seanthimons/ComptoxR/compare/v1.1.0...v1.2.0)

## v1.1.0 (2023-12-06)

Full set of changes:
[`v1.0.0...v1.1.0`](https://github.com/seanthimons/ComptoxR/compare/v1.0.0...v1.1.0)

## v1.0.0 (2023-07-18)

Full set of changes:
[`d95fcd1...v1.0.0`](https://github.com/seanthimons/ComptoxR/compare/d95fcd1...v1.0.0)
