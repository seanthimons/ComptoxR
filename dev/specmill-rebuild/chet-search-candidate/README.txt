Held CheT search/page migration candidate

Both public wrappers remain unchanged at baseline 2b88f70f. No generated
candidate in this directory belongs to the package's runtime R/ directory.
No shared ledger, PR checkpoint, pin, helper or executor was changed.

Scope
  chemi_chet_reaction_searchcounts
    GET /reaction/searchcounts/{search_input}/{search_type}
  chemi_chet_reaction_database_old_by_pagenum_and_searchterm
    GET /reaction/database-old/{pagenum}/{searchterm}
  Source schema: schema/chemi-chet-prod.json, server path /api/chet.
  Existing chemical counts and modern chemical/reaction database pagers already
  have native bindings. These legacy operations are distinct, so no additional
  pager bindings were added. No chemical list-name/resolved payload work.

Blocker
  https://github.com/seanthimons/specmill/issues/166
  Verification: https://github.com/seanthimons/specmill/issues/166#issuecomment-6252993064
  Blocker link: https://github.com/seanthimons/ComptoxR/pull/345#issuecomment-6252938208

  Explicit client inputs cannot select native fan-out. Retaining source parameter
  types allows generation but rejects inputs accepted by the old facades.
  A request-path projection cannot perform cross-input validation before fan-out:
  the multiple/drop handler swallows the old preflight error. Both facades must
  remain retained until a released generator supports their contract.

  counts(c('one', 'two'), 'chemical') and page(c(1L, 2L), 'chemical'):
    old: rlang_error, zero HTTP requests
    candidate: list(NULL, NULL), no error/warning, zero HTTP requests
  counts(1L):
    old: sends /api/chet/reaction/searchcounts/1
    candidate: Invalid path parameter search_input: Invalid scalar type,
               zero HTTP requests

Reproduce from the package root after installing the pinned development toolkit
through dev/install_specmill.R:
  Rscript dev/specmill-rebuild/chet-search-candidate/generate.R
  Rscript dev/specmill-rebuild/chet-search-candidate/verify.R
  Rscript dev/specmill-rebuild/chet-search-candidate/check.R

Generation copies the runtime definitions/schema into a fresh temporary root and
writes only the two held candidate files back here. Supported request/response
projections live in callbacks.R. There are no fake lifecycle hooks. The candidate
uses the existing collection policy and final formatter. Both public signatures
match the frozen originals exactly.

rejected-any.yml is the permissive-input candidate that the generator rejects.
To reproduce that rejection in a fresh R process:
  options(chet.candidate.mapping = 'rejected-any.yml')
  source('dev/specmill-rebuild/chet-search-candidate/generate.R')

The optional chet.candidate.toolkit R option passes lib/lock to verify_specmill.
Official v0.1.41 was installed independently through dev/install_specmill.R, with
source 05862bee1804806cea157ff1962300d741516301 and git-archive SHA256
70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc.
Generation and permissive-input rejection reproduce on both v0.1.40 and v0.1.41.
The parent owns integrating the release pin. No toolkit lock is included here.

Evidence
  originals.rds: frozen parsed old definitions, evaluated in the real namespace.
  results.rds: 490 comparisons of value/attributes, warnings, error class/message/
    parent/location and built request URL/method/Accept/body. These are diagnostic
    comparisons, not 490 passing tests. Native hard401 is an intentional difference.
    Inputs include scalar/vector/duplicate/NA/empty/list/numeric; optional trailing
    inputs include NULL/blank/vector/slash/space; statuses include 200/404/500/401/
    transport, plus valid/empty/null/malformed JSON bodies.
  check.R: asserts positive scalar parity, authentic received404/500 and transport
    parity, concrete held preflight/type regressions, native hard401 and hard
    configuration errors during multiple-input execution.
  HTTP mocks honor req$policies$error_is_error and httr2::resp_check_status.
    Legacy sequential mocks continue with authentic per-request error objects.
  live-read.json: credential-free GET probes. Search counts returns HTTP200 JSON
    []; legacy page/search returns HTTP500 application/problem+json. That500 is
    not evidence of successful page behavior. No credentials or auth headers saved.

The unchanged full root generation freshness check passes. No full R CMD check,
production writes/uploads, push, merge, or endpoint-completion claim.
