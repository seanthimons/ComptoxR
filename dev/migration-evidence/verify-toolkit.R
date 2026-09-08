verify_toolkit <- function(root = '.') {
  devtools::test(
    pkg = root,
    filter = 'generate_tests_pipeline|stub_generation_call_shape|stub_generation_multischema|diff_schemas_counts|hooks'
  )
}
if (sys.nframe() == 0L) {
  verify_toolkit()
}
