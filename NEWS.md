

# ComptoxR NEWS

## Unreleased (2026-01-22)

#### Breaking changes

-   migrate from httr to httr2 across all API functions
    ([5636653](https://github.com/seanthimons/ComptoxR/tree/563665333fba97755222a2d04de0c03237125901))
-   migrate from httr to httr2 across all API functions
    ([d772b99](https://github.com/seanthimons/ComptoxR/tree/d772b993a2604d016ba508ccbde1d1afe17b93cb))

#### New features

-   add ‘none’ option to release workflow for creating releases without
    version bump
    ([907429a](https://github.com/seanthimons/ComptoxR/tree/907429a55ca3e849edb1f4dbbc35479748db7a09))
-   update to 1.4.0 with new functions and features
    ([d8c46b3](https://github.com/seanthimons/ComptoxR/tree/d8c46b3ac586720bab28bfca5a53401faf57240f))
-   updated common_chemistry functions, promoted some to `stable`
    ([455f566](https://github.com/seanthimons/ComptoxR/tree/455f566c533b346e5af02a1b65b8592bf5710a10))
-   added Common Chemistry auth, schema, and loading functions. Updated
    workflow to also check for schema updates.
    ([560ea56](https://github.com/seanthimons/ComptoxR/tree/560ea56f70e62ded7b1abf6bdffbebed3a7d4081))
-   stable promotion for chemi_resolver functions (they work as-is).
    ([4ed1784](https://github.com/seanthimons/ComptoxR/tree/4ed1784050ad71908c7a4404464ef98318150af8))
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
    ([e2108a9](https://github.com/seanthimons/ComptoxR/tree/e2108a963e8747dbee4e5649400c2ed0009c17b3))
-   Phase 5 - Query parameter $ref resolution
    ([d3a1e77](https://github.com/seanthimons/ComptoxR/tree/d3a1e778fe17059e544ceacd7d78fe018d91fb39))
-   Phase 4 - Code generation updates using request_type classification
    ([499bac5](https://github.com/seanthimons/ComptoxR/tree/499bac5d66d506150bd536159d132682066c4a09))
-   RQ codes now return tidy data or NULL, depreciated chemi_rq
    function.
    ([ecbe0be](https://github.com/seanthimons/ComptoxR/tree/ecbe0be91ce92494a366ab1aa1e2c42d86aeed6a))
-   added stubbed out chemi\_ functions + docuementation
    ([85d53b4](https://github.com/seanthimons/ComptoxR/tree/85d53b495a045b94965481766dc47bad97846a93))
-   updated chemi_search
    ([4b6ea16](https://github.com/seanthimons/ComptoxR/tree/4b6ea168a3a74938da96600f2a47bca3e6be39df))
-   updated chemi_search
    ([62f0098](https://github.com/seanthimons/ComptoxR/tree/62f0098335957816830f2b1507caba96e38a4e67))
-   finished scaffolding other functions
    ([0e8f3d4](https://github.com/seanthimons/ComptoxR/tree/0e8f3d40d11bd18848d8ef54003c90c40cd05cc9))
-   finished scaffolding other functions
    ([f9751d6](https://github.com/seanthimons/ComptoxR/tree/f9751d6bddee320eb064ad99a0a4dbb98e7028b0))
-   built out chemi scaffolding
    ([5b0bcb0](https://github.com/seanthimons/ComptoxR/tree/5b0bcb0f867a7c11953b365e938a7ca5fc3fbdf7))
-   built out chemi scaffolding
    ([9b4f71b](https://github.com/seanthimons/ComptoxR/tree/9b4f71bd2e9473162f6f7e1f22101da6bfa547cf))
-   added endpoint evaluation + stubbing functions.
    ([b6f9e45](https://github.com/seanthimons/ComptoxR/tree/b6f9e452ded34ad8c419745e2d6d6edb97bf6c09))
-   added endpoint evaluation + stubbing functions.
    ([fbd5aff](https://github.com/seanthimons/ComptoxR/tree/fbd5affc6dd739d3a8004a826b72f9bbc6f86f58))
-   added unicode cleaning function
    ([a280939](https://github.com/seanthimons/ComptoxR/tree/a280939d14ea60f87a26ca860e2f5cbf51be0fe4))
-   added unicode cleaning function
    ([f2bef81](https://github.com/seanthimons/ComptoxR/tree/f2bef81d4453ba892d701b204197afef1319b09f))
-   added support files and hashes for file age on schema
    ([a1b5cd8](https://github.com/seanthimons/ComptoxR/tree/a1b5cd8dfe3886c3385536488bffdb754b78e036))
-   added support files and hashes for file age on schema
    ([29eaac3](https://github.com/seanthimons/ComptoxR/tree/29eaac3302513e7696607dbe3284af78d28756e6))
-   adds schema updates and initial loading behavior based upon status.
    ([61f93c5](https://github.com/seanthimons/ComptoxR/tree/61f93c59c73fba6e318d1bd0f9e259092001a80e))
-   adds schema updates and initial loading behavior based upon status.
    ([7efc4ae](https://github.com/seanthimons/ComptoxR/tree/7efc4ae5448b4d4382aefb70e13b48334d21c1e1))
-   added two compounds to testing set, and rebuilt ct_details.
    ([9136500](https://github.com/seanthimons/ComptoxR/tree/9136500dbe5bf4a554fe39197b58772b50a0270a))
-   added two compounds to testing set, and rebuilt ct_details.
    ([ad3918d](https://github.com/seanthimons/ComptoxR/tree/ad3918dfb4be91babeac827a3e91dc4b2d26744b))
-   server pathing updates, documentation updates
    ([f78a3e0](https://github.com/seanthimons/ComptoxR/tree/f78a3e00b14cfe492b07bb207c2664f1d58f914c))
-   server pathing updates, documentation updates
    ([19a1bd9](https://github.com/seanthimons/ComptoxR/tree/19a1bd96932cad87e34d6f9699559a96f34c9812))
-   fixed ct_env_fate(), now should return more informative errors and
    final data as tibble.
    ([72cba9d](https://github.com/seanthimons/ComptoxR/tree/72cba9d868154aab24a041ff1c2e780da3856c0e))
-   fixed ct_env_fate(), now should return more informative errors and
    final data as tibble.
    ([f21821f](https://github.com/seanthimons/ComptoxR/tree/f21821f1b23e6be40f7bfd7acdf10ec3811ff6d3))
-   update to schema and servers; will now try all servers and allows
    for fallback to developement to generate endpoint lists.
    ([8892314](https://github.com/seanthimons/ComptoxR/tree/8892314b11b176199d539010a4f255e3c933aa86))
-   update to schema and servers; will now try all servers and allows
    for fallback to developement to generate endpoint lists.
    ([7616228](https://github.com/seanthimons/ComptoxR/tree/76162285eafe996b7de76674b2d9212f7ac6184b))
-   schema now checks latest server for all endpoints, removed hardcoded
    endpoint list.
    ([7911a1e](https://github.com/seanthimons/ComptoxR/tree/7911a1eff38183cd5b191c03e200a1921250b7ba))
-   schema now checks latest server for all endpoints, removed hardcoded
    endpoint list.
    ([6e03284](https://github.com/seanthimons/ComptoxR/tree/6e032845455c66ed7bc972798cab206200c220f8))
-   updated older functions
    ([2ffa413](https://github.com/seanthimons/ComptoxR/tree/2ffa4134e5a3eb53b2a9727bd597cc7922b93595))
-   updated older functions
    ([0e0ee5f](https://github.com/seanthimons/ComptoxR/tree/0e0ee5f8b2deb73b40f4e66f84f1833aec706c55))
-   added global POST request limit, now sets on initial load
    ([7eb301d](https://github.com/seanthimons/ComptoxR/tree/7eb301d6c858556f99dbb0a0fab5a5372f6557f2))
-   added global POST request limit, now sets on initial load
    ([b18a623](https://github.com/seanthimons/ComptoxR/tree/b18a623f2fe1764c6324183be4cff72622d9b897))
-   added ct_bioactivity_models for grabbing ToxCast model outputs.
    ([f134136](https://github.com/seanthimons/ComptoxR/tree/f13413620884c77e62a25d4ed4c72b3637eec8fc))
-   added ct_bioactivity_models for grabbing ToxCast model outputs.
    ([a579681](https://github.com/seanthimons/ComptoxR/tree/a5796816df62df21e1add207b8d29a8e0aa59d47))
-   added chemi\_ schema downloading
    ([3c698b8](https://github.com/seanthimons/ComptoxR/tree/3c698b84b16206bd55d1f4051c9e1ce298309454))
-   added chemi\_ schema downloading
    ([753add5](https://github.com/seanthimons/ComptoxR/tree/753add5a8c346951285dea68efa7341553710691))
-   added chemi_functional_use for export
    ([8c4623f](https://github.com/seanthimons/ComptoxR/tree/8c4623f007aab9b5a191d882236715e9227bfa3a))
-   added chemi_functional_use for export
    ([04f4272](https://github.com/seanthimons/ComptoxR/tree/04f4272c820e4c480e16f76b1819f02d55c33ce3))

#### Bug fixes

-   updated workflows to not infinite-trigger
    ([cf85cb6](https://github.com/seanthimons/ComptoxR/tree/cf85cb66d1e0eb63165c188f7ad6dff3d4e052e9))
-   disabled workflows while debuggin building errors
    ([94712a0](https://github.com/seanthimons/ComptoxR/tree/94712a0619c9938c1ad32ca3dd1dc14e8b17515f))
-   workflow updates
    ([d047790](https://github.com/seanthimons/ComptoxR/tree/d047790d0cb8d1e1c6411b97d6c7c6833ccd326a))
-   Phase 5 bug fixes and circular reference detection
    ([cb91fd3](https://github.com/seanthimons/ComptoxR/tree/cb91fd3473d7668179f920f52f6e47f3792ad17c))
-   update DESCRIPTION + promote some functions to stable
    ([643a24c](https://github.com/seanthimons/ComptoxR/tree/643a24cb9f27d2fe977ec412bb7e4d14db65e420))
-   update workflow to only run on dev branch
    ([26df779](https://github.com/seanthimons/ComptoxR/tree/26df77956473c7f6826fcb0b119f0544cb13fef7))
-   adjusted search regex for not yet built functions
    ([a544a2e](https://github.com/seanthimons/ComptoxR/tree/a544a2ee79d4652308e3abc6a4a806a397433254))
-   fixed logic and stubbing generation
    ([2f32d9f](https://github.com/seanthimons/ComptoxR/tree/2f32d9f6d74a9e9ee727491a912cd665af92fe21))
-   Add CRAN mirror to Install dependencies step
    ([ec39fe6](https://github.com/seanthimons/ComptoxR/tree/ec39fe670e882f7d481ccdcbfd100a754d7b5175))
-   add permissions and fetch-depth for schema PR creation
    ([08e6e13](https://github.com/seanthimons/ComptoxR/tree/08e6e1309929c26fc716331a074a1c0a3ae51cfb))
-   add permissions and fetch-depth for schema PR creation
    ([120ee29](https://github.com/seanthimons/ComptoxR/tree/120ee29283893899099dce4b0c4df352003e8641))
-   add permissions and fetch-depth for schema PR creation
    ([29cd148](https://github.com/seanthimons/ComptoxR/tree/29cd148c4d29117e2a4b2ae00abf6989193bdcd8))
-   adjusted stubbing for content type
    ([e3fd8e6](https://github.com/seanthimons/ComptoxR/tree/e3fd8e669fb1732aee08248440dd42ef4495d8a1))
-   adjusted stubbing for content type
    ([e30ed48](https://github.com/seanthimons/ComptoxR/tree/e30ed48db257c04f5ba136fd8b7af99ba0980866))
-   adjustment to test YAML
    ([a8429aa](https://github.com/seanthimons/ComptoxR/tree/a8429aa057715a7cf88c7430d1eebebc161f6b7c))
-   adjustment to test YAML
    ([2f9cba4](https://github.com/seanthimons/ComptoxR/tree/2f9cba4f9dd61d513881ad05c020d53a7112ace2))
-   updated misc functions feat: Adjusted functional usage / exposure
    functions
    ([59856a6](https://github.com/seanthimons/ComptoxR/tree/59856a67918e6361b8b79157b7104d2680706d70))
-   updated misc functions feat: Adjusted functional usage / exposure
    functions
    ([98352f4](https://github.com/seanthimons/ComptoxR/tree/98352f48d9c83e45951e540b7a93a6ce6e4781ac))
-   adjusted the generic functions to handle things like projections.
    ([26b1fda](https://github.com/seanthimons/ComptoxR/tree/26b1fda84b48f13ac6c0a841353fcc4d80137c92))
-   adjusted the generic functions to handle things like projections.
    ([ff77c88](https://github.com/seanthimons/ComptoxR/tree/ff77c88b823a4f2930ff1fcb329a3a4e74c2181c))
-   updated the loading logic for run\_\* flags
    ([a9d85c5](https://github.com/seanthimons/ComptoxR/tree/a9d85c504c73fd19e02e13c988b31dadf6f9a760))
-   updated the loading logic for run\_\* flags
    ([f27aedd](https://github.com/seanthimons/ComptoxR/tree/f27aedd2ff2845cb10ad5a59f9ef4405bf66aa4b))
-   added latency calculatiosn to ping test to diagnose routing issues.
    ([683c291](https://github.com/seanthimons/ComptoxR/tree/683c2911da5d0d473b4ce2e8ffbafd2f9bd767cc))
-   added latency calculatiosn to ping test to diagnose routing issues.
    ([1803e08](https://github.com/seanthimons/ComptoxR/tree/1803e082787031426e6cccf6b55428e8ec817cbc))
-   updated generic request to strip out empty strings and NAs
    ([f203fe6](https://github.com/seanthimons/ComptoxR/tree/f203fe62279a706d88dbf9d2d06c1d8e60b964e7))
-   updated generic request to strip out empty strings and NAs
    ([627197f](https://github.com/seanthimons/ComptoxR/tree/627197f9f10660491f2b343603fac5fd013a4150))
-   minor update to generic request: now asserts type of query request
    better.
    ([bbf8cb2](https://github.com/seanthimons/ComptoxR/tree/bbf8cb2f5ba4ad5f8dafb346ca371730e6a340ae))
-   minor update to generic request: now asserts type of query request
    better.
    ([7b99335](https://github.com/seanthimons/ComptoxR/tree/7b9933576100976f661a8ac0f4ab099e3c999c90))
-   type on server pathing
    ([6c5a963](https://github.com/seanthimons/ComptoxR/tree/6c5a96398a53e01157cdf71f1062a9815c51151a))
-   type on server pathing
    ([14e9817](https://github.com/seanthimons/ComptoxR/tree/14e981778c014df5652e0522f3cc89442315a695))
-   for smaller queries under batch limit, enclose them into a list.
    ([0fef1b1](https://github.com/seanthimons/ComptoxR/tree/0fef1b1e97f109dc295c6912fdce0427a8011e3e))
-   for smaller queries under batch limit, enclose them into a list.
    ([4add90e](https://github.com/seanthimons/ComptoxR/tree/4add90e82dc08c8b8f15f1840c65786c1b6fe09d))
-   updated schema generation and initial load testing for API key
    ([a33424d](https://github.com/seanthimons/ComptoxR/tree/a33424dd6a5299d0111fa179970c4f4d4569ff13))
-   updated schema generation and initial load testing for API key
    ([20a61b3](https://github.com/seanthimons/ComptoxR/tree/20a61b3bf3b4967b3ecd8c3bdea781aaac1cae8c))
-   updated clustering + resolver services.
    ([76a1873](https://github.com/seanthimons/ComptoxR/tree/76a187302701172230c5c62c0a48ccf2bc07c39d))
-   updated clustering + resolver services.
    ([52ba517](https://github.com/seanthimons/ComptoxR/tree/52ba517085a83dcf9c8b8a0134872b0d4b678868))
-   server update
    ([134622f](https://github.com/seanthimons/ComptoxR/tree/134622f7132741d8ea5c61fa46cf9bf48688bc3b))
-   server update
    ([6a25f57](https://github.com/seanthimons/ComptoxR/tree/6a25f57c76c238b778a822d328bb00357a11d383))
-   update chemi_classyfire for error message
    ([23e7056](https://github.com/seanthimons/ComptoxR/tree/23e70566dfd364c7673e19a1de79f7bb4f30a794))
-   update chemi_classyfire for error message
    ([8de88d5](https://github.com/seanthimons/ComptoxR/tree/8de88d5b1201d4e414803262d60617d3e9e1b996))
-   update to ct_related
    ([cb2abf5](https://github.com/seanthimons/ComptoxR/tree/cb2abf5b45206088a916666df9399d42f0f096c3))
-   update to ct_related
    ([129e206](https://github.com/seanthimons/ComptoxR/tree/129e2064ac3ae82412c24da1a1119ba89f870a71))

#### Refactorings

-   standardize API requests and migrate to httr2
    ([34b1dc3](https://github.com/seanthimons/ComptoxR/tree/34b1dc353378e24baced4aed04e8a958d4155633))
-   standardize API requests and migrate to httr2
    ([1ce02ea](https://github.com/seanthimons/ComptoxR/tree/1ce02ea9f32d9a22be6ce524c602a35f1cf462c9))

#### Tests

-   Phase 6 integration testing with documentation
    ([1aee618](https://github.com/seanthimons/ComptoxR/tree/1aee618394c6d433d89ebec1df64dc6398ef1eed))

#### CI

-   add schema update check workflow
    ([4894340](https://github.com/seanthimons/ComptoxR/tree/489434044cf2822408dce62f63d5fafb042cb2ea))
-   add schema update check workflow
    ([ebc32e6](https://github.com/seanthimons/ComptoxR/tree/ebc32e6bf32d09933d2093acaa935e1547f2cab2))
-   add schema update check workflow
    ([e726a5e](https://github.com/seanthimons/ComptoxR/tree/e726a5e477de2ae0b8f8dd1a1bb8099f1b2eaa1e))

#### Docs

-   Update progress document with Phase 6 blocking issue
    ([dc56b98](https://github.com/seanthimons/ComptoxR/tree/dc56b987bd68ab9b578d71f0c77963b13e455c66))
-   Update Phase 5 status with test results
    ([13c6d87](https://github.com/seanthimons/ComptoxR/tree/13c6d87e57c1b1cb3fcf5ec3e013241a991b8755))
-   Update progress document with Phase 5 completion
    ([32d1379](https://github.com/seanthimons/ComptoxR/tree/32d137967a7fff31adb9d04a98a10856d919f72a))
-   progress update
    ([aa96ccc](https://github.com/seanthimons/ComptoxR/tree/aa96ccc7602664dfc0768791eb99a0016358ca17))

#### Other changes

-   Update NEWS.md \[skip ci\]
    ([afcaabd](https://github.com/seanthimons/ComptoxR/tree/afcaabdc8e42a40fe0bd3679f63de8546a8a22f1))
-   Update NEWS.md \[skip ci\]
    ([8813f0e](https://github.com/seanthimons/ComptoxR/tree/8813f0e9c930307b1bbb418f38498d8a9ef7eb16))
-   docs update for generic functions
    ([d42eaee](https://github.com/seanthimons/ComptoxR/tree/d42eaee206fc068acd0e39a1776af0c3fa801ae1))
-   docs update
    ([268a1c5](https://github.com/seanthimons/ComptoxR/tree/268a1c551b6211aa301c16f2d4afd3d3e1f86805))
-   regeneration of docs and wrappers
    ([6ddd1fb](https://github.com/seanthimons/ComptoxR/tree/6ddd1fb3f1872e5d521f4282a9c6484cb374a763))
-   broke up large parsing script into smaller scripts
    ([04b30f9](https://github.com/seanthimons/ComptoxR/tree/04b30f946b02f67285bb59a02ca8d706bc1439fe))
-   docs update
    ([856f522](https://github.com/seanthimons/ComptoxR/tree/856f522f3be03312c94cce2eaa9419f38e95b9c3))
-   update API schemas (#46)
    ([16c56ca](https://github.com/seanthimons/ComptoxR/tree/16c56ca0baf432e11410b8034370742655d43fcf))
-   update API schemas (#45)
    ([cffcea2](https://github.com/seanthimons/ComptoxR/tree/cffcea2fda24a5ee873536df9a662504b1422005))
-   deleted old testing files
    ([513a945](https://github.com/seanthimons/ComptoxR/tree/513a94558d331c76770a450d968feb27a61cc892))
-   updated NAMESPACE for new functions
    ([9a0459a](https://github.com/seanthimons/ComptoxR/tree/9a0459ab1d726c20b2589b93e5b192d9d2cf9e2d))
-   Reorganize repository structure: move dev scripts and test utilities
    to appropriate directories
    ([1c8c393](https://github.com/seanthimons/ComptoxR/tree/1c8c393802db55e5c2a5f3e20f06e159fd31bb67))
-   deleted old testing files
    ([4be0678](https://github.com/seanthimons/ComptoxR/tree/4be067841fbb8ac7b6db825705462bddd6858b24))
-   deleted old testing files
    ([03f4515](https://github.com/seanthimons/ComptoxR/tree/03f451528d6998d64826a61d859aff5763d4f8fd))
-   updated build process
    ([6f47d40](https://github.com/seanthimons/ComptoxR/tree/6f47d40b58abe888a0f37264c34031569724876d))
-   updated build process
    ([8cf3365](https://github.com/seanthimons/ComptoxR/tree/8cf33655576e17f72adefef692c6a2a7e3989538))
-   updated tests
    ([85d3555](https://github.com/seanthimons/ComptoxR/tree/85d3555ff1da7c671e16e34610a72fa242ca3b37))
-   updated tests
    ([2f2bb25](https://github.com/seanthimons/ComptoxR/tree/2f2bb25931d1365fa68b764ee0993da8d5cca43b))
-   added unit testing boilerplate for offline + live testing.
    ([0f3568b](https://github.com/seanthimons/ComptoxR/tree/0f3568bed2d7bae845eb3daa4ffe501632305eff))
-   added unit testing boilerplate for offline + live testing.
    ([fa29138](https://github.com/seanthimons/ComptoxR/tree/fa29138dc2af4f1888767b4c498f9d378e02372d))
-   updates to unit testing harness
    ([ad0e413](https://github.com/seanthimons/ComptoxR/tree/ad0e4139eca5eedbf09dce8d8d9400d0ab450687))
-   updates to unit testing harness
    ([d6b9571](https://github.com/seanthimons/ComptoxR/tree/d6b9571aa6f12a4d1ee7066c99817b15472bb091))
-   Add test infrastructure and tests for ct_env_fate function
    ([bad15bc](https://github.com/seanthimons/ComptoxR/tree/bad15bcc64c7457401090ee83b0889ef9fb12abd))
-   Add test infrastructure and tests for ct_env_fate function
    ([e035f64](https://github.com/seanthimons/ComptoxR/tree/e035f6470a49619f088a70e4cd8e8eb9e6156b45))

Full set of changes:
[`v1.3.0...111a1e4`](https://github.com/seanthimons/ComptoxR/compare/v1.3.0...111a1e4)

## v1.3.0 (2025-10-02)

#### New features

-   updated NEWS.md
    ([967e114](https://github.com/seanthimons/ComptoxR/tree/967e1143125dcf2651e5d768b21a6eba135afa22))
-   updated NEWS.md
    ([694390c](https://github.com/seanthimons/ComptoxR/tree/694390c250c4137d9fd771c279f008b6360fc50e))
-   update input component styles and add new features
    ([0262182](https://github.com/seanthimons/ComptoxR/tree/026218262c0686d1d1a82a9a5bae399b99c0a3e3))
-   update input component styles and add new features
    ([3076ce7](https://github.com/seanthimons/ComptoxR/tree/3076ce7f89cd939d0c89c856fc5a47d203f4556c))
-   updated ct_hazard to new endpoints and added GET / POST methods.
    ([d68e11d](https://github.com/seanthimons/ComptoxR/tree/d68e11da9765e5dc680aeb950fb7077fdcbd9f05))
-   updated ct_hazard to new endpoints and added GET / POST methods.
    ([4017449](https://github.com/seanthimons/ComptoxR/tree/40174495727dff69d58c4fb5a2d4c848549adb5d))
-   added schema download feature
    ([ae21a68](https://github.com/seanthimons/ComptoxR/tree/ae21a688c3739a7d98722c46ab0580903fdba937))
-   added schema download feature
    ([c161f9a](https://github.com/seanthimons/ComptoxR/tree/c161f9aeb7c35b58b682ee4b74f37b42c3eb12e3))
-   enhance chemi_resolver output and documentation
    ([7c284eb](https://github.com/seanthimons/ComptoxR/tree/7c284eb9cca4d7376cca6da996f518c42fb10bc1))
-   enhance chemi_resolver output and documentation
    ([45cf080](https://github.com/seanthimons/ComptoxR/tree/45cf080aa8e66897ca1dced0c895bc33ca50c904))
-   add batch processing for large chemical queries
    ([ed1b5c3](https://github.com/seanthimons/ComptoxR/tree/ed1b5c3e29684672b0ac7bf33ca96e6cf9b8f669))
-   add batch processing for large chemical queries
    ([c0de4cc](https://github.com/seanthimons/ComptoxR/tree/c0de4cc81e16ea49fa3a254f0f5f21636b8ab47e))
-   Add TODO comment for batched query preparation
    ([cae89c7](https://github.com/seanthimons/ComptoxR/tree/cae89c7e19e946dc11e457696077895ca105ed9f))
-   Add TODO comment for batched query preparation
    ([9ca7779](https://github.com/seanthimons/ComptoxR/tree/9ca7779d6ce4967274e7f68c41122f017b458b75))
-   improve parameter validation and error handling in chemi_resolver
    ([609f673](https://github.com/seanthimons/ComptoxR/tree/609f67322ae68bf324b64644cf4f92a1d83037d5))
-   improve parameter validation and error handling in chemi_resolver
    ([9ad65b0](https://github.com/seanthimons/ComptoxR/tree/9ad65b0bec70d86759b29d86d5213b646bbfa529))
-   enhance chemi_resolver with ID type and fuzzy search options
    ([e66c86f](https://github.com/seanthimons/ComptoxR/tree/e66c86f53244cd72b0481d6dd45273a2fe3d19f2))
-   enhance chemi_resolver with ID type and fuzzy search options
    ([5d20be4](https://github.com/seanthimons/ComptoxR/tree/5d20be44225144b5cccfb64164ba982a92332e7c))

#### Bug fixes

-   updated documentation
    ([5205621](https://github.com/seanthimons/ComptoxR/tree/5205621229e307825bdfe5572030f34d6dedc237))
-   updated documentation
    ([4966a93](https://github.com/seanthimons/ComptoxR/tree/4966a93e98db69eade53edbb0a1aadd2306e59d2))
-   updated file path for ct_file to reflect new directory structure.
    Began to update chemi_search for updated documentation and new
    features.
    ([db7c1d6](https://github.com/seanthimons/ComptoxR/tree/db7c1d6a39c9e7e14348ee25d1ec66f59e924ef0))
-   updated file path for ct_file to reflect new directory structure.
    Began to update chemi_search for updated documentation and new
    features.
    ([adf981e](https://github.com/seanthimons/ComptoxR/tree/adf981e994b089c7f517bcd63f45047ca0f38555))
-   minor adjustment to server ping test
    ([20f70b3](https://github.com/seanthimons/ComptoxR/tree/20f70b3dbf4473365d16000a85f773d0789447ec))
-   minor adjustment to server ping test
    ([b6dc2c2](https://github.com/seanthimons/ComptoxR/tree/b6dc2c2600ec162b9b81bd2fb14f1f46f4083589))
-   Update server path and added schema download
    ([310203d](https://github.com/seanthimons/ComptoxR/tree/310203d9a4b30887fc09dddd242f430e8b9a2ae5))
-   Update server path and added schema download
    ([91c2c82](https://github.com/seanthimons/ComptoxR/tree/91c2c8239408b8b0a7a1dcb2c251a227bfac6c2c))

#### Refactorings

-   simplify column renaming in chemi_resolver using rename_with
    ([d13fea9](https://github.com/seanthimons/ComptoxR/tree/d13fea9f20bc22472dbe7381c7630c87bebd5b1c))
-   simplify column renaming in chemi_resolver using rename_with
    ([5d3bf43](https://github.com/seanthimons/ComptoxR/tree/5d3bf43fbe36a6618ef6712b7c3fc43a0e5ee3d2))
-   simplify chemi_resolver query handling and response processing
    ([6e93660](https://github.com/seanthimons/ComptoxR/tree/6e936604f0fc4c03b60f2a24f7aca5ac78965c55))
-   simplify chemi_resolver query handling and response processing
    ([66ab0df](https://github.com/seanthimons/ComptoxR/tree/66ab0df17a77af127e59a5a6bb73fe2f1749488f))

#### Docs

-   Update NEWS.md for release
    ([c05d07a](https://github.com/seanthimons/ComptoxR/tree/c05d07a37ac64d5834a13b45b565523a95c1b835))
-   Update NEWS.md for release
    ([79ffe73](https://github.com/seanthimons/ComptoxR/tree/79ffe731d6f352aa91f4927bb55bf0dabd5fba8d))
-   improve chemi_resolver function documentation
    ([d21172e](https://github.com/seanthimons/ComptoxR/tree/d21172ede9e3bffa167a85e969cdf581fb67f256))
-   improve chemi_resolver function documentation
    ([7ac9134](https://github.com/seanthimons/ComptoxR/tree/7ac913433b22e1e922da681032d4bc915a78b8ee))

#### Other changes

-   update build script and bump minor version
    ([0a5aabc](https://github.com/seanthimons/ComptoxR/tree/0a5aabc9e7a50ac031d72a8e8534275980e0f199))
-   update build script and bump minor version
    ([eb55780](https://github.com/seanthimons/ComptoxR/tree/eb557803f4a98bc1b9d94b6fb8a1afe4c67ff367))

Full set of changes:
[`v1.3.0...v1.3.0`](https://github.com/seanthimons/ComptoxR/compare/v1.3.0...v1.3.0)

## v1.2.2.9009 (2025-08-27)

#### New features

-   remove exposure and production volume endpoints
    ([6d1e946](https://github.com/seanthimons/ComptoxR/tree/6d1e94673ee21e279d922bcdf08cb61c2c5381f8))
-   remove exposure and production volume endpoints
    ([7ec5355](https://github.com/seanthimons/ComptoxR/tree/7ec5355e4fdaec492529d4c1f773ea19ae84d7d6))
-   reduce POST request chunk size and standardize pipe operators
    ([e0ef96f](https://github.com/seanthimons/ComptoxR/tree/e0ef96fc051a1a6545075b5ef7ea1b10c1748a4e))
-   reduce POST request chunk size and standardize pipe operators
    ([52c4696](https://github.com/seanthimons/ComptoxR/tree/52c469631868e02eddf0d9c4eed5a5f38f0b69cc))
-   add base request class implementation
    ([95c9c6e](https://github.com/seanthimons/ComptoxR/tree/95c9c6e6ce3b6857b76dbc31efa345c18ce48327))
-   add base request class implementation
    ([6ce800f](https://github.com/seanthimons/ComptoxR/tree/6ce800f01e3cce6ebd17cff51fa26281eed0b595))

#### Bug fixes

-   clean up server setup and error messages
    ([5f39cbf](https://github.com/seanthimons/ComptoxR/tree/5f39cbf2d9806cef290139e602affcbcdcdcdbd0))
-   clean up server setup and error messages
    ([ca5b04d](https://github.com/seanthimons/ComptoxR/tree/ca5b04d447f69f09c91279f82c1d419b03445ae1))

#### Docs

-   update NEWS.md format and build process
    ([528b1c4](https://github.com/seanthimons/ComptoxR/tree/528b1c4300d03b433b681313b23d179b260dd2fa))
-   update NEWS.md format and build process
    ([cb9b9d0](https://github.com/seanthimons/ComptoxR/tree/cb9b9d046a4be5a810729367a0a5510d9a0c6fb5))

#### Other changes

-   remove unused/ old R functions, now available through stable/
    staging documentation.
    ([09526ef](https://github.com/seanthimons/ComptoxR/tree/09526ef49ebbcb5d1383aaf224f3a57d8a19aff6))
-   remove unused/ old R functions, now available through stable/
    staging documentation.
    ([25369ce](https://github.com/seanthimons/ComptoxR/tree/25369ce69e8d69d756134c3e8ffd27c87e613e42))
-   update GitHub Actions workflow with changelog builder
    ([bd86b4f](https://github.com/seanthimons/ComptoxR/tree/bd86b4f8cc2b12bee69e9d6477f62bd6cdca5fb3))
-   update GitHub Actions workflow with changelog builder
    ([dc9f918](https://github.com/seanthimons/ComptoxR/tree/dc9f9181f8c3dc7a8a6580b26a94f6cc7c483222))

Full set of changes:
[`v1.2.2.9008...v1.2.2.9009`](https://github.com/seanthimons/ComptoxR/compare/v1.2.2.9008...v1.2.2.9009)

## v1.2.2.9008 (2025-08-18)

#### Style

-   replace pipe operator |\> with %\>% for consistency
    ([577d215](https://github.com/seanthimons/ComptoxR/tree/577d215c4d1565d9f58b986c5afe3cdd6eaa7833))
-   replace pipe operator |\> with %\>% for consistency
    ([e90c4d6](https://github.com/seanthimons/ComptoxR/tree/e90c4d6deb5057875b991208da8bf4fca4ccaa7c))

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
[`9a3b104...v1.0.0`](https://github.com/seanthimons/ComptoxR/compare/9a3b104...v1.0.0)
