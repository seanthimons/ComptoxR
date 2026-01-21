#!/usr/bin/env Rscript
# Test script for Phase 5
library(tidyverse)
source(here::here("dev", "endpoint_eval_utils.R"))

# Test extract_query_params_with_refs
parameters <- list(
  list(name="request", in="query", schema=list($ref="#/components/schemas/UniversalHarvestRequest")),
  list(name="files[]", in="query", schema=list(type="array", items=list(type="string", format="binary")))
)

components <- list(
  schemas=list(
    UniversalHarvestRequest=list(
      type="object",
      properties=list(
        info=list($ref="#/components/schemas/UniversalHarvestInfo"),
        chemicals=list(type="array", items=list($ref="#/components/schemas/Chemical"))
      )
    ),
    UniversalHarvestInfo=list(
      type="object",
      properties=list(
        keyName=list(type="string"),
        keyType=list(type="string")
      )
    ),
    Chemical=list(
      type="object",
      properties=list(
        sid=list(type="string"),
        smiles=list(type="string")
      )
    )
  )
)

result <- extract_query_params_with_refs(parameters, components)

cat("Result names:", result$names, "\n")
cat("Result metadata names:", names(result$metadata), "\n")

# Print detailed metadata
for (name in names(result$metadata)) {
  meta <- result$metadata[[name]]
  cat(sprintf("%s: type=%s\n", name, meta$type))
}
