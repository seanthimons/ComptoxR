toxprints_canonical_body <- function(operation) substitute(.api_validation$body_value(base::list(chemicals = base::as.list(params$query)), SCHEMA), list(SCHEMA = operation$schema_body))
