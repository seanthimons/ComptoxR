ComptoxR PR345: https://github.com/seanthimons/ComptoxR/pull/345

Released Specmill 0.1.41, exact source `05862bee1804806cea157ff1962300d741516301`, git-archive SHA256 `70e51d935055847ac14b26e188f38835aa68ccccb5024cefcc8f9d62d0aa0afc`.

Wrapper `chemi_search`, POST `/api/search`, `apis/search-pilot.yml`, archived source `schema/chemi-search-prod.json`.

The retained facade's public `all_pages = FALSE` argument is transport-only. Its pre-request `params` contains the other 16 arguments, excluding `all_pages`. It calls the pre hook once, then optionally pages, then calls post once with the **entire pre-hook return**, plus result. `all_pages` is forced only on a non-skipped request, after pre hooks. Partial returned `params` and additional state fields remain intact.

Minimal released reproduction: take current `apis/search-pilot.yml`, change only `implementation: existing` to `generated`, generate with the existing `preserve_choice_defaults`, `hook_config`, and request bindings. The generated public signature is correct, but its initial `params` includes `all_pages` and forces it before the pre hook. Replacement hook:

```r
run_hook <- function(name, stage, data) {
  if (stage == 'pre_request') {
    stopifnot(!'all_pages' %in% names(data$params))
    return(list(params = list(query = 'changed'), skip_request = TRUE,
                result = 'skipped', marker = 'preserve'))
  }
  stopifnot(identical(data$marker, 'preserve'))
  data$result
}
chemi_search(all_pages = stop('must remain lazy on skip'))
```

Original returns `skipped`; generated errors `must remain lazy on skip` before pre. With `all_pages=FALSE`, original pre has 16 params, generated has 17. Existing `defer_inputs` stores a thunk in params, which still changes the state; `post_params` only affects post state and is incompatible with `post_state: hook_state`.

A native mapping adds further constraints. Current generated pagination permits page/cursor only, appends public `all_pages=TRUE,max_pages=100` and executes pre/post inside each send. This facade needs numeric **body offset**, its original 17-argument signature with no max_pages, pre once/post once, and complete hook-state preservation across combined paging. `post_response_scope: combined` currently requires fan-out/split and rejects `post_state: hook_state`. A fake batch/hook or wrapper/helper patch is not an acceptable workaround.

Please support selecting initial hook params independently from transport inputs while preserving laziness, plus facade paging without changing its signature or hook cycle. Keep dynamic request bindings and full returned state. ComptoxR leaves the old wrapper bytes intact until released support is proven against HTTP, skips, partial updates and conditions.
