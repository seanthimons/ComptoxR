Held CheT release-adoption candidate, authentic executor correction

Private development evidence only. Public wrappers, actual hooks, helper,
executor, generic_request, root mapping/configuration and toolkit pin are unchanged.
Candidate client differences are resolved apart from intentional native hard401.
Adoption still requires a released Specmill containing PR167 and a parent-owned
pin update. This proof uses unreleased source, not released v0.1.41.

Corrected proof comment:
  https://github.com/seanthimons/specmill/pull/167#issuecomment-6253236647
Upstream: https://github.com/seanthimons/specmill/pull/167
Exact source: 16928dc49804d8149bbf8e126a3bd02c8a68de75
Git archive SHA256:
  afc11d55ded4c1a7832b77fb0d63ac7d1eef780df376d33c199d39b56b9de3d1
Frozen legacy fixture from a79a16b8, SHA256:
  2c6b418a13a67dbe94ad7e9de7b5466348b4f551e73455fc2c8467ab80d8f802

Scope
  chemi_chet_reaction_searchcounts
    GET /reaction/searchcounts/{search_input}/{search_type}
  chemi_chet_reaction_database_old_by_pagenum_and_searchterm
    GET /reaction/database-old/{pagenum}/{searchterm}
  schema/chemi-chet-prod.json, /api/chet server prefix.

Correction to prior proof 2b555180 and its PR167 comment
  https://github.com/seanthimons/specmill/pull/167#issuecomment-6253164045
  That harness replaced req_perform_sequential with lapply(reqs, ...).
  Named requests therefore produced named responses in the mock. Real httr2
  returns unnamed responses. The claimed 24 outer-list-name differences were
  mock artifacts, not a client or Specmill limitation. They are retracted.
  executor-check.R demonstrates both behaviors with actual httr2 sequential
  execution, mocking only req_perform. No value/attribute stripping is used.
  authentic-baseline.rds repeats the prior candidate with that correction only:
  400/490 exact matches, rather than 376/490. It retains 90 differences:
  24 blank suffix, 24 space suffix and 42 HTTP401-priority rows including six
  space-suffix overlaps. The RDS retains complete baseline diagnostics.

Supported client changes
  service.yml retains explicit any inputs, complete request mappings, native
  fan_out and existing formatter/response policy. No generated file is edited.
  callbacks.R builds the suffix path using the same httr2 path-append semantics
  as the legacy wrapper. Blank suffixes omit the slash; vector/list suffixes
  retain ordered append behavior. Its placeholder origin performs no I/O.
  input-policy.R is a pure operation validate_inputs function. It retains the
  cross-input batching cli_abort, then constructs/parses URLs without sending
  requests, using the configured client endpoint. purrr::map preserves the
  old indexed parse condition and parent before hooks/fan-out/drop handling.
  Thus malformed space suffixes fail with zero sends, including when the
  selected mock status is 401, 404, 500 or transport. No fake hooks or helper,
  executor, generic_request or formatter changes are needed.
  generate.R invokes official specmill::generate_client from the exact archive
  in a disposable root, then copies only the two selected candidate files.
  Runtime evaluation uses a private environment with the unchanged package
  formatter binding because generated formatter lookup is namespace-local.

Reproduce from ComptoxR root, with a clone containing the exact source:
  SPECMILL_SOURCE_REPO=/path/to/specmill Rscript dev/specmill-rebuild/rootheldrelease/install.R
  Rscript dev/specmill-rebuild/rootheldrelease/generate.R
  Rscript dev/specmill-rebuild/rootheldrelease/executor-check.R
  Rscript dev/specmill-rebuild/rootheldrelease/verify.R
  Rscript dev/specmill-rebuild/rootheldrelease/check.R > dev/specmill-rebuild/rootheldrelease/focused-check.txt
  Rscript -e "options(chet.candidate.check=TRUE); source('dev/specmill-rebuild/rootheldrelease/generate.R')"
  Rscript dev/specmill-rebuild/rootheldrelease/summarize.R
  install.R verifies archive and installed source metadata in ignored private
  .toolkit-library. It never installs into the root toolkit library.
  authentic-baseline.rds is a frozen diagnostic baseline; the commands above
  regenerate the final candidate and its current proof, not the old baseline.

Evidence
  results.rds contains the original 490 diagnostics plus 64 URL edge cases.
  518/554 comparisons match exactly, with all result attributes/names, wire
  URL/method/Accept/body, warnings and condition class/message/parent/location.
  The remaining 36 are intentional native hard401 differences. There are no
  other unresolved diagnostics. These counts describe comparisons, not 554
  passing tests. All 64 added whitespace/Unicode/slash/empty-segment cases agree.
  check.R separately asserts public formals; numeric/list normalization;
  once-only full-params preflight; exact cross-input/URL errors and zero sends;
  ignored validator returns, preserved sentinel identity/parent and warnings;
  typed single HTTP404/500 and transport; multi count/NULL slots/warnings and
  exact values/attributes; mixed success/failure; native hard401/config errors.
  Real httr2::req_perform_sequential is used throughout. Only req_perform is
  mocked. Each mock honors request error_is_error and resp_check_status, so
  typed status errors are real httr2 conditions. Actual client hooks stay real.
  Official generation freshness passes byte for byte. summary.json records
  evidence hashes and unchanged package runtime/configuration hashes.

Limits
  No production requests, writes, push or full package check. Mocked response
  bodies prove client behavior under these inputs, not endpoint health/schema
  coverage. Parent owns integration, released-pin verification and broad checks.
