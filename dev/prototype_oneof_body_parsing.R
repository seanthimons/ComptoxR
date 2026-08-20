# PROTOTYPE: inspect how generated wrappers could flatten top-level oneOf bodies.

one_of_shape <- function(path, route) {
  schema <- jsonlite::fromJSON(path, simplifyVector = FALSE)$paths[[route]]$post$requestBody$content[[
    "application/json"
  ]]$schema
  branches <- schema$oneOf
  properties <- lapply(branches, function(branch) names(branch$properties))
  required <- lapply(branches, function(branch) unlist(branch$required %||% character()))

  list(
    route = route,
    branches = properties,
    common_properties = Reduce(intersect, properties),
    union_properties = unique(unlist(properties)),
    common_required = Reduce(intersect, required),
    alternative_required = lapply(required, setdiff, y = Reduce(intersect, required))
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

cases <- list(
  one_of_shape("schema/chemi-predictor_models-staging.json", "/api/predictor_models/predict"),
  one_of_shape("schema/chemi-opera-staging.json", "/api/opera")
)

for (case in cases) {
  cat("\n", case$route, "\n", sep = "")
  print(case)
}

stopifnot(
  identical(cases[[1]]$common_required, "model_id"),
  identical(cases[[1]]$alternative_required, list("smiles", "chemicals")),
  identical(cases[[2]]$alternative_required, list("smiles", "chemicals"))
)
