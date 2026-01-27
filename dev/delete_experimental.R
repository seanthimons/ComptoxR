library(tidyverse)
target_dir <- 'R'
r_files <- list.files(target_dir, pattern = "\\.R$", full.names = TRUE) %>%
  .[grep('^ct_*', basename(.), invert = FALSE)]

experimental_files <- character()
for (file in r_files) {
  content <- readLines(file, warn = FALSE)
  if (any(str_detect(content, fixed('lifecycle::badge("experimental")')))) {
    experimental_files <- c(experimental_files, file)
  }
}
cat('Deleting', length(experimental_files), 'files\n')
file.remove(experimental_files)
cat('Done\n')
