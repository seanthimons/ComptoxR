test_that('banned endpoints cannot be selected or exported', {
  root <- test_path('../..')
  skip_if_not(file.exists(file.path(root, 'dev/endpoint-policy.json')))
  policy <- jsonlite::read_json(file.path(root, 'dev/endpoint-policy.json'), simplifyVector = TRUE)
  config <- yaml::read_yaml(file.path(root, 'specmill.yml'))
  for (file in config$services) {
    service <- yaml::read_yaml(file.path(root, file))
    selected <- union(service$selection$include, names(service$operations))
    banned <- unlist(policy$banned_operations, use.names = FALSE)
    expect_true(all(sub(' .*', '', selected) %in% policy$allowed_methods), info = file)
    expect_false(any(selected %in% banned), info = file)
    if (any(startsWith(basename(unlist(service$schemas$files)), 'chemi-chet'))) {
      expect_false(any(grepl(policy$chet_banned_path_pattern, sub('^[^ ]+ ', '', selected))), info = file)
    }
  }
  expect_true(all(grepl(policy$chet_banned_path_pattern,
    c('/auth/login', '/auth/new-route', '/admin/new-route', '/chemicals/chemdelete'))))
  expect_false(any(grepl(policy$chet_banned_path_pattern,
    c('/chemicals/chemical_DL', '/curators/login', '/chemicals/chemdelete-other'))))
  removed <- c(
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-354/removed-bindings.json')),
    jsonlite::read_json(file.path(root, 'dev/specmill-rebuild/issue-355/removed-bindings.json')))
  for (binding in removed) {
    expect_false(binding$name %in% getNamespaceExports('ComptoxR'))
    expect_false(file.exists(file.path(root, binding$file)))
    expect_false(file.exists(file.path(root, 'man', paste0(binding$name, '.Rd'))))
  }
})
