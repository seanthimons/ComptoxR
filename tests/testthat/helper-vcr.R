library(vcr)

# Configure vcr
vcr_dir <- "../testthat/fixtures"
if (!dir.exists(vcr_dir)) dir.create(vcr_dir, recursive = TRUE)

vcr::vcr_configure(
  dir = vcr_dir,
  filter_sensitive_data = list(
    "<<<API_KEY>>>" = Sys.getenv("ctx_api_key")
  )
)
