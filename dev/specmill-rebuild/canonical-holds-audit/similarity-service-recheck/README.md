# Similarity-list source/service recheck

The previously declared read-only ethanol self-reference request was replayed on 18 October 2026 at22:56UTC. Production still returns HTTP500 because OrderSimilarityRequest.get_chemicals() is null. Staging returns HTTP400 problem JSON requiring _chemicals to contain1..1000 entries. No underscore alias was sent or adopted.

The freshly retrieved staging OpenAPI3.1 source still declares get_chemicals, not _chemicals, and does not mark main or either array required. staging-source.json records its URL/hash and exact selected request component. This does not resolve Specmill165. There is no positive nonempty similarity result or approved replacement contract; the public wrapper remains retained. The operation is a read-only similarity calculation, with no upload, session or mutation.
