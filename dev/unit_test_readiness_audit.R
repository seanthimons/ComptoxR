# Development-only readiness adapter; policy remains client-owned YAML.
.readiness_root <- specmill::script_root('unit_test_readiness_audit.R')
.readiness <- new.env(parent = asNamespace('specmill'))
specmill::bind_tools('readiness', .readiness)
.readiness$audit_policy <- .readiness$read_audit_policy(file.path(.readiness_root, 'dev/specmill-readiness.yml'))
list2env(as.list(.readiness, all.names = TRUE), envir = environment())
if (sys.nframe() == 0L) {
  unit_test_readiness_audit_main(root = .readiness_root)
}
