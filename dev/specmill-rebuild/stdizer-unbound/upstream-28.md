PR345 follow-up on released Specmill v0.1.41, source 05862bee1804806cea157ff1962300d741516301. Three additional unbound canonical standardizer operations hit the existing binary-query hold:

- `chemi_stdizer_groups_preflight_post`: POST `/api/stdizer/groups/preflight`
- `chemi_stdizer_groups_by_id_add_post`: POST `/api/stdizer/groups/{id}/add`
- `chemi_stdizer_groups_by_id_replace_post`: POST `/api/stdizer/groups/{id}/replace`

Source `schema/chemi-stdizer-prod.json`, unchanged. All declare required query `files[]`, array of binary strings. Add also declares optional nested query `request` referencing GroupAddRequest. There are no previous wrappers for these operations; existing group creation and bulk facades remain untouched.

Minimal reproduction: select these method/path keys in a service config using this canonical schema, `.ct_request`, `implementation: generated`, and `server: {resolver: .ct_server_url, key: chemi_burl}`. Run `specmill::generate_client(root=project, config='specmill.yml', mode='plan', validation=TRUE, artifacts=c('wrappers','documentation'))` on official v41. Each returns `review_required`, code `binary_parameter`, reason `Binary parameter requires source contract review (#16)`; add also reports `Unsupported nested parameter object`. These operations emit no usable native wrapper. We retain the canonical declaration and do not invent multipart or JSON alternatives. No deployed mutation or upload was executed.

Blocks the remaining native bindings in https://github.com/seanthimons/ComptoxR/pull/345. Candidate config and diagnostic proof will be committed under `dev/specmill-rebuild/stdizer-unbound/`.
