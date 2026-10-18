# Root v41 integration: 65 operations

This checkpoint adds 24 management bindings, the reviewed CheT chemical download GET, 35 chemical/curator/reaction bindings, four calculation facades and the existing safety-flags facade. All wrappers were emitted from root configuration using the pinned official Specmill v0.1.41; child manifests and desired wrapper bytes were not copied over owned outputs.

Full generation with validation=TRUE and a subsequent check passed, with zero generation/mapping/retained diagnostics or signature drift. All 648 root owner hashes match. The existing reviewed-document policy for the archived invalid AMOS source remains unchanged; the reviewed CheT GET body retains its interoperability warning.

The focused root run passed 2,654 assertions across 41 tests, with zero failures, errors, warnings or skips. It covers management, CheT download and extra routes, four calculations, descriptor null cells and hooks, and the safety-flags facade. These are localhost/controlled tests except the separately archived live evidence. No deployed mutation, upload or session operation was executed.

Mordred's shared formatter now retains NULL descriptor cells as NA instead of deleting list elements. Archived and fresh production results retain one row with 1,613 descriptors and 385 missing values. WebTEST predictions still fail the unchanged post hook when the deployment omits endpoint IDs; migration does not claim usable live predictions.

Root safety-flags uses the existing resolved_chemical_response callback, preserving native hard 401 and configuration semantics. The imported child's held prototype callback and historical typed-401 report are not the adopted root response policy.

The previous checkpoint's package gate was 0/0/0 with tests, examples, vignettes and manual excluded. That package gate and the broad safe suite have not yet been repeated for this batch; focused checks and freshness are the completed gates here. Use a persistent TMPDIR before R starts. No ComptoxR push.
