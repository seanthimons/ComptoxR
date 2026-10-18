Independent exact-source replay of **5566da87ae5acc7a95e10eaa209dbc18a290f498** against the actual held ComptoxR facades for [ComptoxR PR345](https://github.com/seanthimons/ComptoxR/pull/345). This is private proof only; no runtime, pin, helper or wrapper adoption.

Three remaining contract gaps:

1. **`chemi_search`, POST `/api/search`, `schema/chemi-search-prod.json`: deferred original transport control is overwritten by a partial hook update.** Actual old facade excludes `all_pages` from its initial 16 hook params and uses the original lazy public `all_pages` for transport, regardless of `req_data$params$all_pages`. Configure the actual 17 public inputs with `defer_inputs: [all_pages]`, `pre_params` excluding all_pages, `request.pagination.when` callback emitting `params[['all_pages']]()`, `post_state: hook_state`, `post_on_skip: true`, combined post-response. Replace the pre-hook return with:
   ```r
   list(params = list(query = 'changed', all_pages = FALSE), marker = 'keep',
        request = list(body = list(searchType = 'MASS', params = list(limit = 1)),
                       options = list(limit = 1)))
   ```
   Call `chemi_search(all_pages = TRUE)`. Frozen old facade makes two real localhost requests for recordsCount=1/totalRecordsCount=2. Official candidate makes zero and errors `attempt to apply non-function`: emitted `params[changed] <- state$params[changed]` replaces the deferred callable. Keeping this extra field in returned post state is required; it must not replace the original transport argument.

2. **Same search operation: NULL result key presence still differs.** Pre returns `list(params=list(query='partial'), skip_request=TRUE, marker='kept', result=NULL)`, post returns its input unchanged, and caller supplies `all_pages=stop('forced')`. Both skip lazily and run one pre/post cycle, but old `post_data$result <- result` removes `result`; generated `state['result'] <- list(result)` retains a named NULL. Other state is identical. Fixing full-state preservation must preserve this observable legacy key behavior too.

3. **`chemi_resolver_getpubchemlist`, POST `/api/resolver/getpubchemlist`, `schema/chemi-resolver-prod.json`: dynamic max_pages is not expressible.** Its exact public formals are `query, idType='AnyId', section=NULL, all_pages=TRUE, max_pages=100`; the old facade applies partial hook updates to max_pages, then passes the resulting value to the existing pager. `request.pagination.max_pages: {from: [params, max_pages]}` or a callback binding is rejected: `request.pagination.max_pages must be a positive integer below .Machine$integer.max`. The renderer also casts this setting directly to integer. Fixed 100 generation is diagnostic only: `max_pages=1` stops old at one request but the candidate continues. Please support a binding without adding public formals or executing hooks per page.

The independent replay uses official emitted scaffold/wrappers, validation=TRUE against both canonical schemas, freshness and every private ownership hash, plus actual localhost HTTP and real `httr2::req_perform_sequential`. No native executor mocks or helper patches. The PR's own exact-source `tests/request-pagination.R` passes, but it does not cover these actual facade inputs.

Separate source/service hold remains for PubChem: old wrapped ChemicalRecord/options payload versus declared flat Chemical input with five required query controls; source responses use `items/total`, old collector reads `records/totalRecordsCount`. Changing those is an explicit source/service correction, not facade parity. No deployed service calls, mutations, uploads or sessions were made. Released-only adoption remains held.
