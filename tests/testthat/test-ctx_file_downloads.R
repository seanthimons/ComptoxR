test_that("CTX file downloads decode each identifier's image or mol text", {
  withr::local_envvar(ctx_api_key = "local-test-key")
  png <- magick::image_write(magick::image_blank(2, 3, color = "white"), format = "png")
  mol <- "example\n  CTX\n\n  0  0  0  0  0  0            999 V2000\nM  END\n"
  paths <- character()
  testthat::local_mocked_bindings(
    req_perform = function(req, ...) {
      paths <<- c(paths, httr2::url_parse(req$url)$path)
      image <- grepl("/image/", req$url, fixed = TRUE)
      httr2::response(
        status_code = 200,
        headers = list(`Content-Type` = if (image) "image/png" else "text/plain; charset=utf-8"),
        body = if (image) png else charToRaw(mol)
      )
    },
    .package = "httr2"
  )
  images <- list(
    ct_chemical_file_image_search = c("DTXSID7020182", "DTXSID1024122"),
    ct_chemical_file_image_search_by_dtxcid = c("DTXCID505", "DTXCID30182"),
    ct_chemical_file_image_search_by_gsid = c("1", "2")
  )
  for (name in names(images)) {
    result <- do.call(get(name), list(images[[name]]))
    expect_type(result, "list")
    expect_length(result, 2)
    for (image in result) {
      expect_s3_class(image, "magick-image")
      expect_identical(magick::image_data(image), magick::image_data(magick::image_read(png)))
    }
    expect_true(all(endsWith(tail(paths, 2), images[[name]])))
    expect_length(do.call(get(name), list(images[[name]][1])), 1)
  }
  expect_identical(ct_chemical_file_mol_search(c("DTXSID7020182", "DTXSID1024122")), list(mol, mol))
  expect_identical(ct_chemical_file_mol_search_by_dtxcid("DTXCID505"), list(mol))
})

test_that("CTX file policy preserves undecodable image bytes", {
  bytes <- charToRaw("invalid image")
  response <- httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "image/png"),
    body = bytes
  )
  expect_identical(.ct_request_decode(response, response_policy = .ct_file), bytes)
})
