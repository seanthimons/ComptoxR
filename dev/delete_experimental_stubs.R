# Delete experimental stubs except manually maintained ones

# Manually maintained functions (do NOT delete these)
keep_files <- c(
  "R/ct_hazard.R",
  "R/ct_cancer.R",
  "R/ct_env_fate.R",
  "R/ct_genotox.R",
  "R/ct_skin_eye.R",
  "R/ct_similar.R",
  "R/ct_compound_in_list.R",
  "R/ct_list.R",
  "R/ct_lists_all.R",
  "R/chemi_toxprint.R",
  "R/chemi_safety.R",
  "R/chemi_hazard.R",
  "R/chemi_rq.R",
  "R/chemi_classyfire.R"
)

# Find all files with lifecycle badges
all_r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
experimental_files <- character()

for (file in all_r_files) {
  content <- readLines(file, warn = FALSE)
  if (any(grepl('lifecycle::badge\\("experimental"\\)', content, fixed = FALSE))) {
    experimental_files <- c(experimental_files, file)
  }
}

# Exclude manually maintained files
files_to_delete <- setdiff(experimental_files, keep_files)

cat("Total files with lifecycle badge:", length(experimental_files), "\n")
cat("Manually maintained (will keep):", length(keep_files), "\n")
cat("Files to delete:", length(files_to_delete), "\n\n")

if (length(files_to_delete) > 0) {
  cat("Deleting experimental stubs...\n")
  deleted_count <- 0
  for (file in files_to_delete) {
    if (file.remove(file)) {
      deleted_count <- deleted_count + 1
    }
  }
  cat("Deleted", deleted_count, "experimental stub files\n")
} else {
  cat("No files to delete\n")
}
