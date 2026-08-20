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

generate_wrapper <- function(shape) {
  optional <- setdiff(shape$union_properties, shape$common_required)
  formals <- c("request", shape$common_required, paste0(optional, " = NULL"))
  alternatives <- vapply(
    shape$alternative_required,
    function(fields) {
      paste0(
        "all(!vapply(list(",
        paste(fields, collapse = ", "),
        "), is.null, logical(1)))"
      )
    },
    character(1)
  )
  body <- paste0(shape$union_properties, " = ", shape$union_properties, collapse = ", ")

  paste0(
    "function(",
    paste(formals, collapse = ", "),
    ") {\n",
    "  if (sum(c(",
    paste(alternatives, collapse = ", "),
    ")) != 1L) ",
    "stop('Supply exactly one oneOf body shape.')\n",
    "  body <- Filter(Negate(is.null), list(",
    body,
    "))\n",
    "  request(endpoint = '",
    shape$route,
    "', method = 'POST', body = body)\n",
    "}"
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
  cat("\nGenerated wrapper:\n", generate_wrapper(case), "\n", sep = "")
}

stopifnot(
  identical(cases[[1]]$common_required, "model_id"),
  identical(cases[[1]]$alternative_required, list("smiles", "chemicals")),
  identical(cases[[2]]$alternative_required, list("smiles", "chemicals"))
)

test_generated_wrapper <- function() {
  wrapper <- eval(parse(text = generate_wrapper(cases[[1]])))
  request <- function(...) list(...)

  smiles <- wrapper(request, model_id = 1065, smiles = c("CC", "CCC"))
  chemicals <- wrapper(request, model_id = 1065, chemicals = list(list(id = 1, smiles = "CC")))

  stopifnot(
    identical(smiles$method, "POST"),
    identical(smiles$body, list(model_id = 1065, smiles = c("CC", "CCC"))),
    identical(chemicals$body, list(model_id = 1065, chemicals = list(list(id = 1, smiles = "CC")))),
    inherits(try(wrapper(request, 1065), silent = TRUE), "try-error"),
    inherits(try(wrapper(request, 1065, smiles = "CC", chemicals = list()), silent = TRUE), "try-error")
  )
}

test_generated_wrapper()
