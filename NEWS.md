

# ComptoxR NEWS

## Unreleased (2026-02-27)

#### Breaking changes

-   migrate from httr to httr2 across all API functions
    ([6d96532](https://github.com/seanthimons/ComptoxR/tree/6d9653248790fa8e50b0345e8b2585f699b71e03))

#### New features

-   use coverage delta outputs in schema PR body
    ([e9f93bb](https://github.com/seanthimons/ComptoxR/tree/e9f93bb0a31b5dfa8e651f3c78485d6ee7643961))
-   add ‘none’ option to release workflow for creating releases without
    version bump
    ([614524e](https://github.com/seanthimons/ComptoxR/tree/614524e7fec993ab6b0ed5ab18d6df322dd1f75b))
-   update to 1.4.0 with new functions and features
    ([e2a6cdf](https://github.com/seanthimons/ComptoxR/tree/e2a6cdf0858e64ec1cd03b09bca02046324b714c))
-   updated common_chemistry functions, promoted some to `stable`
    ([73276bc](https://github.com/seanthimons/ComptoxR/tree/73276bc30d24408ab9857ca82b38ac103da6c3ec))
-   added Common Chemistry auth, schema, and loading functions. Updated
    workflow to also check for schema updates.
    ([05a176f](https://github.com/seanthimons/ComptoxR/tree/05a176fd2e49848b40fb35fc07e3ff004695fef9))
-   stable promotion for chemi_resolver functions (they work as-is).
    ([c40cd94](https://github.com/seanthimons/ComptoxR/tree/c40cd9415f0db3b44002df8fa44769475e707ffb))
-   complete Phase 6 stub generation with flattened query parameters -
    Generate 117 chemi function stubs with proper query parameter
    handling - Add 2 new stubs:
    chemi_amos_get_classification_for_dtxsid,
    chemi_toxprints_calculate - Fix extract_query_params_with_refs() to
    correctly flatten nested schemas - Update
    ENDPOINT_EVAL_UTILS_GUIDE.md with Phase 1-5 documentation: - Add
    Schema Preprocessing section (preprocess_schema,
    filter_components_by_refs) - Add resolution docs
    (resolve_schema_ref, extract_query_params_with_refs) - Document new
    tibble columns (request_type, body_schema_full, body_item_type) -
    Update mermaid diagrams with preprocessing and resolution flows -
    Expand Key Functions Reference and Quick Reference tables - Restore
    chemi_endpoint_eval.R to production state - Update progress.md with
    Phase 6 completion status
    ([40b4b77](https://github.com/seanthimons/ComptoxR/tree/40b4b77a75d1511b88c1b0ce60b0f294315ccb34))
-   Phase 5 - Query parameter $ref resolution
    ([23ab8c8](https://github.com/seanthimons/ComptoxR/tree/23ab8c888bdd8d562fad361b984adbad0bdd8991))
-   Phase 4 - Code generation updates using request_type classification
    ([87414cf](https://github.com/seanthimons/ComptoxR/tree/87414cf1d764c67c61b7f4d5ecb250a3f16148cc))
-   RQ codes now return tidy data or NULL, depreciated chemi_rq
    function.
    ([83c52fe](https://github.com/seanthimons/ComptoxR/tree/83c52fe1b48dcdcaef5b71d9b4bf36b72229bd14))
-   added stubbed out chemi\_ functions + docuementation
    ([5298683](https://github.com/seanthimons/ComptoxR/tree/529868315f7dcc7f5592fb29467eb49fa403e1f9))
-   updated chemi_search
    ([f725a88](https://github.com/seanthimons/ComptoxR/tree/f725a88c882a418247f958dee74a821ab29525e8))
-   updated chemi_search
    ([77b7f76](https://github.com/seanthimons/ComptoxR/tree/77b7f764e2e32ad4a2fb7f1762c0f0da24dd45c5))
-   finished scaffolding other functions
    ([60f7d4c](https://github.com/seanthimons/ComptoxR/tree/60f7d4c415386714183619019252e445f1824b90))
-   built out chemi scaffolding
    ([7b123a3](https://github.com/seanthimons/ComptoxR/tree/7b123a3ce5e8b025896720d5247f830c0993d070))
-   added endpoint evaluation + stubbing functions.
    ([b0bbd13](https://github.com/seanthimons/ComptoxR/tree/b0bbd13ebd101f2a3d5c1bcbd43c3e2c6fea7f72))
-   added unicode cleaning function
    ([6ec5451](https://github.com/seanthimons/ComptoxR/tree/6ec545108cfcc07800bd6d3e64d413fc37acbbc8))
-   added support files and hashes for file age on schema
    ([ff3d3ba](https://github.com/seanthimons/ComptoxR/tree/ff3d3bacad98edb9ed584f2e1d7a275d05579788))
-   adds schema updates and initial loading behavior based upon status.
    ([4bab173](https://github.com/seanthimons/ComptoxR/tree/4bab17365d820d9cf32764409d6a81d8f8ca7163))
-   added two compounds to testing set, and rebuilt ct_details.
    ([168bf99](https://github.com/seanthimons/ComptoxR/tree/168bf999c27db26f0c49601b70a21cd6782b2092))
-   server pathing updates, documentation updates
    ([df27133](https://github.com/seanthimons/ComptoxR/tree/df2713341bca2182a9830bf506741c4717548930))
-   fixed ct_env_fate(), now should return more informative errors and
    final data as tibble.
    ([effcca2](https://github.com/seanthimons/ComptoxR/tree/effcca2ff7d47712b79d39fbe899ce9dbf03c16e))
-   update to schema and servers; will now try all servers and allows
    for fallback to developement to generate endpoint lists.
    ([e1f50f8](https://github.com/seanthimons/ComptoxR/tree/e1f50f80a8c78f8f19401f2556943e89725a1dca))
-   schema now checks latest server for all endpoints, removed hardcoded
    endpoint list.
    ([a3970d5](https://github.com/seanthimons/ComptoxR/tree/a3970d576a7aafc685385743331753758f28994d))
-   updated older functions
    ([52b19e9](https://github.com/seanthimons/ComptoxR/tree/52b19e94b89994720b6578e25062269be7c23ef4))
-   added global POST request limit, now sets on initial load
    ([c8d6245](https://github.com/seanthimons/ComptoxR/tree/c8d6245773642f761f24dbf0ec7160e63aed2264))
-   added ct_bioactivity_models for grabbing ToxCast model outputs.
    ([625eeea](https://github.com/seanthimons/ComptoxR/tree/625eeea00a4a7d5b3440fe7d7e12332c36aa234a))
-   added chemi\_ schema downloading
    ([10d5b0f](https://github.com/seanthimons/ComptoxR/tree/10d5b0fd67a228209455dae058783b08e59013ca))
-   added chemi_functional_use for export
    ([676afe6](https://github.com/seanthimons/ComptoxR/tree/676afe6637d42d571e1920ec1847a085a58c92b6))

#### Bug fixes

-   restore full schema-check workflow from integration \[skip ci\]
    ([5b8ec8b](https://github.com/seanthimons/ComptoxR/tree/5b8ec8b680ccf2a8ea6fe800041ecda44bd5bcdc))
-   updated workflows to not infinite-trigger
    ([83a0856](https://github.com/seanthimons/ComptoxR/tree/83a08563689a5bad5ccdab1bf44ed335142e125e))
-   disabled workflows while debuggin building errors
    ([f56d6b3](https://github.com/seanthimons/ComptoxR/tree/f56d6b36bdb0315621ab4cf00acfa8031506ec6c))
-   workflow updates
    ([ce1ce0b](https://github.com/seanthimons/ComptoxR/tree/ce1ce0bcd574614199d1c284980c8e218763890a))
-   Phase 5 bug fixes and circular reference detection
    ([ab24b92](https://github.com/seanthimons/ComptoxR/tree/ab24b922d041933f26bba5af5d463055ac25f631))
-   update DESCRIPTION + promote some functions to stable
    ([96d91e3](https://github.com/seanthimons/ComptoxR/tree/96d91e3953c1b71c2fc8886279da1f37bf1804b4))
-   update workflow to only run on dev branch
    ([fef0f97](https://github.com/seanthimons/ComptoxR/tree/fef0f97413c2aedfa9e966d54137fcba56eac63e))
-   adjusted search regex for not yet built functions
    ([f785f81](https://github.com/seanthimons/ComptoxR/tree/f785f81e58797adf8439a32d71e4bc487b7231c9))
-   fixed logic and stubbing generation
    ([045ec10](https://github.com/seanthimons/ComptoxR/tree/045ec10cd6142312d803b334496818d97cccb294))
-   Add CRAN mirror to Install dependencies step
    ([c4ecce6](https://github.com/seanthimons/ComptoxR/tree/c4ecce65c755470e798ec322a9d434c44dc3638e))
-   add permissions and fetch-depth for schema PR creation
    ([db1a3f1](https://github.com/seanthimons/ComptoxR/tree/db1a3f1bdf42cd2fc82e3772e861b4de17fb5a6d))
-   add permissions and fetch-depth for schema PR creation
    ([e485842](https://github.com/seanthimons/ComptoxR/tree/e485842eaeb869a5aaff577e0d2111d842058db8))
-   add permissions and fetch-depth for schema PR creation
    ([51b8df5](https://github.com/seanthimons/ComptoxR/tree/51b8df56e3d1bca202e27070b94a520adfa9ee6b))
-   adjusted stubbing for content type
    ([440ef09](https://github.com/seanthimons/ComptoxR/tree/440ef09c510749188a2cc9bc8b6490197286fa4e))
-   adjustment to test YAML
    ([db94f63](https://github.com/seanthimons/ComptoxR/tree/db94f63b0bfc1c7b95b8255bee5bd8366b1f8c83))
-   updated misc functions feat: Adjusted functional usage / exposure
    functions
    ([ff921e7](https://github.com/seanthimons/ComptoxR/tree/ff921e7a1d6abf20992a685294d43935dfd89ace))
-   adjusted the generic functions to handle things like projections.
    ([60d42f6](https://github.com/seanthimons/ComptoxR/tree/60d42f6612355a5c56402958d1baab6e523519fe))
-   updated the loading logic for run\_\* flags
    ([21c8690](https://github.com/seanthimons/ComptoxR/tree/21c86909eb5c0be728b9be5fcd07870938aaa181))
-   added latency calculatiosn to ping test to diagnose routing issues.
    ([08eb2a3](https://github.com/seanthimons/ComptoxR/tree/08eb2a3560e519a3d54e207bc615be95fff28d69))
-   updated generic request to strip out empty strings and NAs
    ([95b0a6b](https://github.com/seanthimons/ComptoxR/tree/95b0a6bb5f6c39136830575823b82ea1d1fe3530))
-   minor update to generic request: now asserts type of query request
    better.
    ([80d5e3b](https://github.com/seanthimons/ComptoxR/tree/80d5e3be9cbd077b1bdf04e29c091e6a0a089beb))
-   type on server pathing
    ([725f552](https://github.com/seanthimons/ComptoxR/tree/725f552bb838bcaeae1ebc077383f96b9a662c56))
-   for smaller queries under batch limit, enclose them into a list.
    ([55bcb36](https://github.com/seanthimons/ComptoxR/tree/55bcb36fd423c13c69806c3cf2debea38cf392c7))
-   updated schema generation and initial load testing for API key
    ([570d513](https://github.com/seanthimons/ComptoxR/tree/570d5137d895ab70f6b7be0b6f7908911ef2095b))
-   updated clustering + resolver services.
    ([7eb455d](https://github.com/seanthimons/ComptoxR/tree/7eb455d8249f782985ddf85358a1696e08d8f3ab))
-   server update
    ([efba09b](https://github.com/seanthimons/ComptoxR/tree/efba09b6d89a82a5822eb279a44af95df19dcb8f))
-   update chemi_classyfire for error message
    ([6d5545c](https://github.com/seanthimons/ComptoxR/tree/6d5545cfd098d7c30fe2791c3c86130fbf1eeff1))
-   update to ct_related
    ([e35fa1a](https://github.com/seanthimons/ComptoxR/tree/e35fa1ad569ceec4dcbb6e2cc8f13bda6d355f92))

#### Refactorings

-   standardize API requests and migrate to httr2
    ([e107a94](https://github.com/seanthimons/ComptoxR/tree/e107a944b7e5fe421158aa449301b0aacfab296c))

#### Tests

-   Phase 6 integration testing with documentation
    ([5d042b2](https://github.com/seanthimons/ComptoxR/tree/5d042b2780086bd1ff16bbf7c06b3f86c711c149))

#### CI

-   add schema update check workflow
    ([7e06f89](https://github.com/seanthimons/ComptoxR/tree/7e06f895ab71eb740edd2282f093470332eab0b8))
-   add schema update check workflow
    ([7338942](https://github.com/seanthimons/ComptoxR/tree/7338942c95322d87a946395ca205aca3e6e4d7d2))
-   add schema update check workflow
    ([edd3bb3](https://github.com/seanthimons/ComptoxR/tree/edd3bb399f315f1d6efff4fd1fc1e5ee7c098b69))

#### Docs

-   Update progress document with Phase 6 blocking issue
    ([312cadd](https://github.com/seanthimons/ComptoxR/tree/312caddc13cc24fe1d19358162b0accc0e277625))
-   Update Phase 5 status with test results
    ([b2cba71](https://github.com/seanthimons/ComptoxR/tree/b2cba715b22d4d7f8baac0d4f2d68e0c06dfe877))
-   Update progress document with Phase 5 completion
    ([5fe3b25](https://github.com/seanthimons/ComptoxR/tree/5fe3b256a17331c9bb965012d006d8c47c7825f8))
-   progress update
    ([72f0e14](https://github.com/seanthimons/ComptoxR/tree/72f0e1419f8ade41606df5528293e9db93362928))

#### Other changes

-   Update NEWS.md \[skip ci\]
    ([48bba0a](https://github.com/seanthimons/ComptoxR/tree/48bba0ab8793cb50e21331392c81656a7f98eca7))
-   Update NEWS.md \[skip ci\]
    ([5d1970a](https://github.com/seanthimons/ComptoxR/tree/5d1970a81ea2ccf0b0e839d4c966c045c038b6fa))
-   Update NEWS.md \[skip ci\]
    ([042d25e](https://github.com/seanthimons/ComptoxR/tree/042d25eb6efa3e3c5a4fda65bee2a41eecf34e56))
-   Update NEWS.md \[skip ci\]
    ([f7e0fef](https://github.com/seanthimons/ComptoxR/tree/f7e0fef9d8aae756c4177a05151fa86716e6be0d))
-   docs update for generic functions
    ([a12cb29](https://github.com/seanthimons/ComptoxR/tree/a12cb292f073f5b59128a8907ff5ede235976e32))
-   docs update
    ([4c6f03e](https://github.com/seanthimons/ComptoxR/tree/4c6f03e7917dc8ad854e24bd2d1af977e8305255))
-   regeneration of docs and wrappers
    ([3b3cb10](https://github.com/seanthimons/ComptoxR/tree/3b3cb102b96d5ec92aa04565cd64692063429a5a))
-   broke up large parsing script into smaller scripts
    ([cd4a3b4](https://github.com/seanthimons/ComptoxR/tree/cd4a3b4f11e77845537f9cddb910e51da7b94ddf))
-   docs update
    ([a47fa01](https://github.com/seanthimons/ComptoxR/tree/a47fa015da24438eeda2f99560fae133ca0b8bf2))
-   update API schemas (#46)
    ([2edf4dc](https://github.com/seanthimons/ComptoxR/tree/2edf4dc9ea97943456b7bfa3ad8dcb5e0aef29ce))
-   update API schemas (#45)
    ([f10c535](https://github.com/seanthimons/ComptoxR/tree/f10c535c3336566eaa371260886b2a9cd469cb12))
-   deleted old testing files
    ([d134fc1](https://github.com/seanthimons/ComptoxR/tree/d134fc12c52b67c8e7b0530310c12b0cbf3b9456))
-   updated NAMESPACE for new functions
    ([8285cda](https://github.com/seanthimons/ComptoxR/tree/8285cdad8f516fa473fe9c5a20409a0f46ef693a))
-   Reorganize repository structure: move dev scripts and test utilities
    to appropriate directories
    ([7668d98](https://github.com/seanthimons/ComptoxR/tree/7668d9837a8f19d3157aec63ba36b57b285b744a))
-   deleted old testing files
    ([95a02ad](https://github.com/seanthimons/ComptoxR/tree/95a02ad727b70f2031e68cd847047977488d5039))
-   updated build process
    ([6180906](https://github.com/seanthimons/ComptoxR/tree/6180906795041a84327291e85d95c21a2ab583e3))
-   updated tests
    ([bab2c46](https://github.com/seanthimons/ComptoxR/tree/bab2c468c92c32b43ac02fabf6d1b29b8d403694))
-   added unit testing boilerplate for offline + live testing.
    ([e429f22](https://github.com/seanthimons/ComptoxR/tree/e429f22edc2cc0cd4fe7edf472a98422626f6ac6))
-   updates to unit testing harness
    ([c6ddbbb](https://github.com/seanthimons/ComptoxR/tree/c6ddbbb9c9e3a92a31628ca0b2cf4caa2a4a895a))
-   Add test infrastructure and tests for ct_env_fate function
    ([de08440](https://github.com/seanthimons/ComptoxR/tree/de08440ce6c952fc7b2a01b9bc73d5bfde12cfbb))

Full set of changes:
[`v1.3.0...e9f93bb`](https://github.com/seanthimons/ComptoxR/compare/v1.3.0...e9f93bb)

## v1.3.0 (2025-10-02)

#### New features

-   updated NEWS.md
    ([d965e6b](https://github.com/seanthimons/ComptoxR/tree/d965e6bd3fb601353beb9ec7a6eb4c41dcf914d6))
-   update input component styles and add new features
    ([f75d782](https://github.com/seanthimons/ComptoxR/tree/f75d7829dcc04473df3f563b82fcf097deac9b00))
-   updated ct_hazard to new endpoints and added GET / POST methods.
    ([f7f94e5](https://github.com/seanthimons/ComptoxR/tree/f7f94e5f0bc82e6a03543472a47351c93db5a13a))
-   added schema download feature
    ([2183b24](https://github.com/seanthimons/ComptoxR/tree/2183b2437c0ecd3a198d778920f53d896cb24360))
-   enhance chemi_resolver output and documentation
    ([0875d41](https://github.com/seanthimons/ComptoxR/tree/0875d41ae313fc8dddba02ba6b530f340f18f4bd))
-   add batch processing for large chemical queries
    ([7289df3](https://github.com/seanthimons/ComptoxR/tree/7289df3cad6f49b6a723698479320ec8fbf55bc7))
-   Add TODO comment for batched query preparation
    ([45244a8](https://github.com/seanthimons/ComptoxR/tree/45244a80e6ef26a3a9e3dc6ad23ee9ea14f346ad))
-   improve parameter validation and error handling in chemi_resolver
    ([27113e4](https://github.com/seanthimons/ComptoxR/tree/27113e471bcf661dd6f95d28137b42ec2e62fc61))
-   enhance chemi_resolver with ID type and fuzzy search options
    ([e341d7d](https://github.com/seanthimons/ComptoxR/tree/e341d7deb3e5cb9c9af850ac2030f449a78829ec))

#### Bug fixes

-   updated documentation
    ([ef36bf9](https://github.com/seanthimons/ComptoxR/tree/ef36bf96fb3c94adab3541dda6a86561d8ffdcff))
-   updated file path for ct_file to reflect new directory structure.
    Began to update chemi_search for updated documentation and new
    features.
    ([dee9f0f](https://github.com/seanthimons/ComptoxR/tree/dee9f0ff77b3d0e75d69c134062970bb769d0650))
-   minor adjustment to server ping test
    ([d69a45d](https://github.com/seanthimons/ComptoxR/tree/d69a45df49a61c782501440b09ef86ed2f63b273))
-   Update server path and added schema download
    ([91c4cc5](https://github.com/seanthimons/ComptoxR/tree/91c4cc586612f0f149690f8bbc9013b42ee4a522))

#### Refactorings

-   simplify column renaming in chemi_resolver using rename_with
    ([f6b9548](https://github.com/seanthimons/ComptoxR/tree/f6b954831e731a5f98b8d069dc0e72ef90a0f7fd))
-   simplify chemi_resolver query handling and response processing
    ([a1b3de4](https://github.com/seanthimons/ComptoxR/tree/a1b3de4d27591f50a5279c75758702035e60217d))

#### Docs

-   Update NEWS.md for release
    ([f7978d4](https://github.com/seanthimons/ComptoxR/tree/f7978d45d14ae885bf331f3afa8927960458c026))
-   improve chemi_resolver function documentation
    ([631ca5d](https://github.com/seanthimons/ComptoxR/tree/631ca5d9aedc0a8eb69d3c7745172883d262bd5a))

#### Other changes

-   update build script and bump minor version
    ([8554127](https://github.com/seanthimons/ComptoxR/tree/85541272044c1732a01ed8421060afd0666a354a))

Full set of changes:
[`v1.2.2.9009...v1.3.0`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9009...v1.3.0)

## v1.2.2.9009 (2025-08-27)

#### New features

-   remove exposure and production volume endpoints
    ([33e8d5b](https://github.com/seanthimons/ComptoxR/tree/33e8d5b1ffde1eb5caf5786ab2c8ccf8ac07fedf))
-   reduce POST request chunk size and standardize pipe operators
    ([8cf27a5](https://github.com/seanthimons/ComptoxR/tree/8cf27a5f994ccf1f221a1b7fbf6dd7c40fd9d717))
-   add base request class implementation
    ([2d7eb89](https://github.com/seanthimons/ComptoxR/tree/2d7eb89b270a7295fec39011611c75724517d1a5))

#### Bug fixes

-   clean up server setup and error messages
    ([ef52836](https://github.com/seanthimons/ComptoxR/tree/ef528360d95f792393e77fc337752487cafd2304))

#### Docs

-   update NEWS.md format and build process
    ([ff29ce3](https://github.com/seanthimons/ComptoxR/tree/ff29ce3a6e835db1d749c663eeeb5a1968086942))

#### Other changes

-   remove unused/ old R functions, now available through stable/
    staging documentation.
    ([546df8f](https://github.com/seanthimons/ComptoxR/tree/546df8fcfb9336c31ccc352e8caced2f0b78fd90))
-   update GitHub Actions workflow with changelog builder
    ([53177fc](https://github.com/seanthimons/ComptoxR/tree/53177fc68bad7d342a6e77294095ec3ee0a68cbc))

Full set of changes:
[`v1.2.2.9008...v1.2.2.9009`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9008...v1.2.2.9009)

## v1.2.2.9008 (2025-08-18)

#### Style

-   replace pipe operator |\> with %\>% for consistency
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
