context("CTX Dashboard Connectivity")

test_that("ct_env_fate connects to production and returns data", {
  skip_if_offline()
  skip_if_no_key() # Only runs if a real key is present
  
  vcr::use_cassette("ct_env_fate_simple", {
    # We use a single DTXSID to keep the cassette small
    res <- ct_env_fate(test_dtxsid)
    
    expect_valid_tibble(res)
    # The result should contain typical fate columns for Benzene if found
    # But for connectivity, we just care that it's a valid tibble
  })
})

test_that("ct_hazard connects to production and returns data", {
  skip_if_offline()
  skip_if_no_key()
  
  vcr::use_cassette("ct_hazard_simple", {
    res <- ct_hazard(test_dtxsid)
    expect_valid_tibble(res)
  })
})
