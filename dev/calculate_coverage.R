#!/usr/bin/env Rscript
# Calculate API schema coverage for CCD and Cheminformatic services
# This script counts the number of API endpoints defined in schema files
# and compares them to the number of implemented R wrapper functions

library(jsonlite)
library(here)

# Function to count endpoints in schema files
count_schema_endpoints <- function(schema_pattern) {
  schema_files <- list.files(
    here::here("schema"),
    pattern = schema_pattern,
    full.names = TRUE
  )
  
  if (length(schema_files) == 0) {
    warning(sprintf("No schema files found matching pattern: %s", schema_pattern))
    return(0)
  }
  
  # Use production schema if available, otherwise use first available
  prod_file <- grep("-prod\\.json$", schema_files, value = TRUE)
  schema_file <- if (length(prod_file) > 0) prod_file[1] else schema_files[1]
  
  tryCatch({
    schema <- jsonlite::fromJSON(schema_file, simplifyVector = FALSE)
    
    # Count paths (endpoints) in the schema
    if (!is.null(schema$paths)) {
      return(length(schema$paths))
    } else {
      warning(sprintf("No 'paths' found in schema file: %s", schema_file))
      return(0)
    }
  }, error = function(e) {
    warning(sprintf("Error reading schema file %s: %s", schema_file, e$message))
    return(0)
  })
}

# Function to count all endpoints across multiple schema files
count_all_schema_endpoints <- function(schema_pattern) {
  schema_files <- list.files(
    here::here("schema"),
    pattern = schema_pattern,
    full.names = TRUE
  )
  
  if (length(schema_files) == 0) {
    warning(sprintf("No schema files found matching pattern: %s", schema_pattern))
    return(0)
  }
  
  # For chemi services, we need to count across all service schemas
  # Use production schemas only
  prod_files <- grep("-prod\\.json$", schema_files, value = TRUE)
  
  if (length(prod_files) == 0) {
    prod_files <- schema_files
  }
  
  total_endpoints <- 0
  
  for (schema_file in prod_files) {
    tryCatch({
      schema <- jsonlite::fromJSON(schema_file, simplifyVector = FALSE)
      
      if (!is.null(schema$paths)) {
        total_endpoints <- total_endpoints + length(schema$paths)
      }
    }, error = function(e) {
      warning(sprintf("Error reading schema file %s: %s", schema_file, e$message))
    })
  }
  
  return(total_endpoints)
}

# Function to count implemented R functions
count_r_functions <- function(function_prefix) {
  r_files <- list.files(
    here::here("R"),
    pattern = "\\.R$",
    full.names = TRUE
  )
  
  # Read all R files and search for function definitions
  function_count <- 0
  
  for (r_file in r_files) {
    lines <- readLines(r_file, warn = FALSE)
    
    # Look for function definitions starting with the prefix
    # Pattern: ^prefix_name <- function( or ^prefix_name = function(
    pattern <- sprintf("^%s[a-zA-Z0-9_]* ?(<-|=) ?function\\(", function_prefix)
    matches <- grep(pattern, lines, value = FALSE)
    function_count <- function_count + length(matches)
  }
  
  return(function_count)
}

# Calculate coverage for CCD (Common Chemistry Database)
cat("Calculating CCD (Common Chemistry) coverage...\n")
ccd_endpoints <- count_schema_endpoints("^commonchemistry-prod\\.json$")
ccd_functions <- count_r_functions("cc_")
ccd_coverage_raw <- if (ccd_endpoints > 0) (ccd_functions / ccd_endpoints) * 100 else 0
ccd_coverage <- min(round(ccd_coverage_raw, 1), 100.0)

cat(sprintf("CCD Endpoints: %d\n", ccd_endpoints))
cat(sprintf("CCD Functions: %d\n", ccd_functions))
cat(sprintf("CCD Coverage: %.1f%%\n\n", ccd_coverage))

# Calculate coverage for Cheminformatic services
cat("Calculating Cheminformatic coverage...\n")
chemi_endpoints <- count_all_schema_endpoints("^chemi-.*-prod\\.json$")
chemi_functions <- count_r_functions("chemi_")
chemi_coverage_raw <- if (chemi_endpoints > 0) (chemi_functions / chemi_endpoints) * 100 else 0
chemi_coverage <- min(round(chemi_coverage_raw, 1), 100.0)

cat(sprintf("Cheminformatic Endpoints: %d\n", chemi_endpoints))
cat(sprintf("Cheminformatic Functions: %d\n", chemi_functions))
cat(sprintf("Cheminformatic Coverage: %.1f%%\n\n", chemi_coverage))

# Determine badge colors based on coverage percentage
get_badge_color <- function(coverage) {
  if (coverage >= 80) {
    return("brightgreen")
  } else if (coverage >= 60) {
    return("green")
  } else if (coverage >= 40) {
    return("yellow")
  } else if (coverage >= 20) {
    return("orange")
  } else {
    return("red")
  }
}

ccd_color <- get_badge_color(ccd_coverage)
chemi_color <- get_badge_color(chemi_coverage)

# Create output for GitHub Actions
if (Sys.getenv("GITHUB_OUTPUT") != "") {
  output_file <- Sys.getenv("GITHUB_OUTPUT")
  cat(sprintf("ccd_coverage=%.1f\n", ccd_coverage), file = output_file, append = TRUE)
  cat(sprintf("ccd_color=%s\n", ccd_color), file = output_file, append = TRUE)
  cat(sprintf("chemi_coverage=%.1f\n", chemi_coverage), file = output_file, append = TRUE)
  cat(sprintf("chemi_color=%s\n", chemi_color), file = output_file, append = TRUE)
  cat(sprintf("ccd_endpoints=%d\n", ccd_endpoints), file = output_file, append = TRUE)
  cat(sprintf("ccd_functions=%d\n", ccd_functions), file = output_file, append = TRUE)
  cat(sprintf("chemi_endpoints=%d\n", chemi_endpoints), file = output_file, append = TRUE)
  cat(sprintf("chemi_functions=%d\n", chemi_functions), file = output_file, append = TRUE)
  
  cat("Coverage data written to GITHUB_OUTPUT\n")
}

# Print summary
cat("\n=== Summary ===\n")
cat(sprintf("CCD Coverage: %.1f%% (%d/%d) - Color: %s\n", 
            ccd_coverage, ccd_functions, ccd_endpoints, ccd_color))
cat(sprintf("Cheminformatic Coverage: %.1f%% (%d/%d) - Color: %s\n", 
            chemi_coverage, chemi_functions, chemi_endpoints, chemi_color))
