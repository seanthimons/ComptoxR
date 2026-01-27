# Check the actual OpenAPI schema for /chemical/search/equal endpoint
library(jsonlite)

schema <- fromJSON("schema/ctx_chemical_prod.json", simplifyVector = FALSE)
endpoint <- schema$paths[["/chemical/search/equal/"]]$post

cat("=== ENDPOINT SUMMARY ===\n")
cat("Summary:", endpoint$summary, "\n")
cat("Operation ID:", endpoint$operationId, "\n\n")

cat("=== REQUEST BODY ===\n")
body_schema <- endpoint$requestBody$content[["application/json"]]$schema

cat("Type:", body_schema$type, "\n")
cat("Description:", body_schema$description, "\n\n")

if (!is.null(body_schema$items)) {
  cat("Items type:", body_schema$items$type, "\n")
  cat("Items description:", body_schema$items$description, "\n")
}

if (!is.null(body_schema$properties)) {
  cat("\nProperties:\n")
  print(names(body_schema$properties))
  for (prop_name in names(body_schema$properties)) {
    prop <- body_schema$properties[[prop_name]]
    cat(sprintf("  %s: type=%s, desc=%s\n", prop_name, prop$type %||% "NA", prop$description %||% ""))
  }
}

cat("\n=== RAW BODY SCHEMA ===\n")
print(str(body_schema))
