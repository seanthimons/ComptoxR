# PURPOSE: Helper script for local development and preparing for a release.
# Note: Official releases are now handled via GitHub Actions (release.yml).

# 1. Update testing chemicals if needed
# build_testing_chemicals(chems = c('DTXSID401337424'))

# 2. Local Documentation and Style check
devtools::document()
# styler::style_pkg() # Optional: if you use styler

# 3. Local Checks (Run these before pushing)
# devtools::check()

get_missing_global_variables <- function(wd = getwd()) {
  
  # Run devtools::check() and reprex the results
  check_output <- reprex::reprex(input = sprintf("devtools::check(pkg = '%s', vignettes = FALSE)\n", wd), 
                                 comment = "")
  
  # Get the lines which are notes about missing global variables, extract the variables and 
  # construct a vector as a string
  missing_global_vars <- check_output %>% 
    stringr::str_squish() %>% 
    paste(collapse = " ") %>% 
    stringr::str_extract_all("no visible binding for global variable '[^']+'") %>% 
    `[[`(1) %>% 
    stringr::str_extract("'.+'$") %>%
    stringr::str_remove("^'") %>%
    stringr::str_remove("'$") %>%
    unique() %>%
    sort()
  
  # Get a vector to paste into `globalVariables()`
  to_print <- if (length(missing_global_vars) == 0) {
    "None" 
  } else { 
    missing_global_vars %>% 
      paste0('"', ., '"', collapse = ", \n  ") %>% 
      paste0("c(", ., ")")
  }
  
  # Put the global variables in the console
  cat("Missing global variables:\n", to_print)
  
  # Return the results of the check
  invisible(missing_global_vars)
  
}

# Run manually when you want to detect missing global variables:
# get_missing_global_variables()
# 4. Local Install
# devtools::install(dependencies = TRUE, reload = TRUE)

# TO RELEASE A NEW VERSION:
# 1. Ensure all changes are committed and pushed to 'main'.
# 2. Go to GitHub Actions -> "Release" workflow.
# 3. Click "Run workflow" and choose the version bump type.
