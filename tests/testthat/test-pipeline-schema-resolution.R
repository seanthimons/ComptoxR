# Test schema resolution functions from 01_schema_resolution.R

describe("detect_schema_version()", {
  test_that("detects OpenAPI 3.0 from openapi field", {
    skip_on_cran()
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-openapi-3.json")
    result <- detect_schema_version(schema)

    expect_equal(result$type, "openapi")
    expect_equal(result$version, "3.0.0")
    expect_true(grepl("^3\\.", result$version))
  })

  test_that("detects Swagger 2.0 from swagger field", {
    skip_on_cran()
    source_pipeline_files()
    schema <- load_fixture_schema("minimal-swagger-2.json")
    result <- detect_schema_version(schema)

    expect_equal(result$type, "swagger")
    expect_equal(result$version, "2.0")
    expect_true(grepl("^2\\.", result$version))
  })

  test_that("returns unknown for missing version fields", {
    skip_on_cran()
    source_pipeline_files()
    schema <- list(info = list(title = "Test"))
    result <- detect_schema_version(schema)

    expect_equal(result$type, "unknown")
    expect_equal(result$version, "unknown")
  })

  test_that("handles empty schema", {
    skip_on_cran()
    source_pipeline_files()
    result <- detect_schema_version(list())

    expect_equal(result$type, "unknown")
    expect_equal(result$version, "unknown")
  })
})

describe("validate_schema_ref()", {
  test_that("accepts valid OpenAPI 3.0 internal references", {
    skip_on_cran()
    source_pipeline_files()

    expect_true(validate_schema_ref("#/components/schemas/Chemical"))
    expect_true(validate_schema_ref("#/components/schemas/ChemicalRecord"))
  })

  test_that("accepts valid Swagger 2.0 internal references", {
    skip_on_cran()
    source_pipeline_files()

    expect_true(validate_schema_ref("#/definitions/Chemical"))
    expect_true(validate_schema_ref("#/definitions/User"))
  })

  test_that("errors on empty references", {
    skip_on_cran()
    source_pipeline_files()

    expect_error(validate_schema_ref(""), "empty or non-character")
    expect_error(validate_schema_ref(NULL), "empty or non-character")
  })

  test_that("errors on external file references", {
    skip_on_cran()
    source_pipeline_files()

    expect_error(
      validate_schema_ref("file.json#/components/schemas/Test"),
      "External file reference"
    )
    expect_error(
      validate_schema_ref("schemas.yaml#/definitions/User"),
      "External file reference"
    )
  })

  test_that("warns on unusual reference paths", {
    skip_on_cran()
    source_pipeline_files()

    expect_warning(
      validate_schema_ref("#/paths/test"),
      "Unusual reference path"
    )
  })

  test_that("errors on references without hash prefix", {
    skip_on_cran()
    source_pipeline_files()

    expect_error(
      validate_schema_ref("components/schemas/Chemical"),
      "must start with"
    )
  })
})

describe("resolve_schema_ref()", {
  test_that("resolves normal OpenAPI 3.0 references", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    # Create test schema with resolvable reference
    components <- list(
      schemas = list(
        TestSchema = list(
          type = "object",
          properties = list(
            name = list(type = "string")
          )
        )
      )
    )

    schema_version <- list(type = "openapi", version = "3.0.0")
    result <- resolve_schema_ref(
      "#/components/schemas/TestSchema",
      components,
      schema_version
    )

    expect_equal(result$type, "object")
    expect_true(!is.null(result$properties))
    expect_equal(result$properties$name$type, "string")
  })

  test_that("resolves normal Swagger 2.0 references with fallback", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    # For Swagger 2.0, definitions might be at root or normalized to components
    components <- list(
      TestSchema = list(
        type = "object",
        properties = list(
          id = list(type = "integer")
        )
      )
    )

    schema_version <- list(type = "swagger", version = "2.0")
    result <- resolve_schema_ref(
      "#/definitions/TestSchema",
      components,
      schema_version
    )

    expect_equal(result$type, "object")
    expect_true(!is.null(result$properties))
  })

  test_that("handles circular references without infinite loop", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    schema <- load_fixture_schema("circular-refs.json")
    components <- schema$components

    # Node references itself via children array
    # Should return sentinel without error
    result <- resolve_schema_ref(
      "#/components/schemas/Node",
      components,
      list(type = "openapi", version = "3.0.0")
    )

    # Should not error (no infinite loop)
    expect_true(!is.null(result))
    # It might return the actual schema or a circular_ref sentinel
    # Either way, no infinite loop = success
  })

  test_that("enforces depth limit", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    # Create deeply nested references
    components <- list(
      schemas = list(
        Level1 = list(`$ref` = "#/components/schemas/Level2"),
        Level2 = list(`$ref` = "#/components/schemas/Level3"),
        Level3 = list(`$ref` = "#/components/schemas/Level4"),
        Level4 = list(`$ref` = "#/components/schemas/Level5"),
        Level5 = list(type = "string")
      )
    )

    # max_depth = 3 should fail on 4+ levels
    expect_error(
      resolve_schema_ref(
        "#/components/schemas/Level1",
        components,
        list(type = "openapi", version = "3.0.0"),
        max_depth = 3
      ),
      "depth limit exceeded"
    )
  })

  test_that("returns input unchanged if not a character reference", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    # Non-reference schema (already resolved)
    schema <- list(type = "string", format = "uuid")
    result <- resolve_schema_ref(schema, list(), NULL)

    expect_equal(result, schema)
  })

  test_that("handles nested $ref in resolved schema", {
    skip_on_cran()
    source_pipeline_files()
    clear_stubgen_env()

    components <- list(
      schemas = list(
        Wrapper = list(`$ref` = "#/components/schemas/Inner"),
        Inner = list(type = "string")
      )
    )

    result <- resolve_schema_ref(
      "#/components/schemas/Wrapper",
      components,
      list(type = "openapi", version = "3.0.0")
    )

    expect_equal(result$type, "string")
  })
})

describe("extract_swagger2_body_schema()", {
  test_that("extracts body from parameters with in=body", {
    skip_on_cran()
    source_pipeline_files()

    parameters <- list(
      list(
        name = "body",
        `in` = "body",
        schema = list(
          type = "object",
          properties = list(
            name = list(type = "string"),
            age = list(type = "integer")
          ),
          required = c("name")
        )
      )
    )

    result <- extract_swagger2_body_schema(parameters, list())

    expect_equal(result$type, "object")
    expect_true(!is.null(result$properties))
    expect_equal(length(result$properties), 2)
    expect_true(result$properties$name$required)
    expect_false(result$properties$age$required)
  })

  test_that("returns unknown for empty parameters", {
    skip_on_cran()
    source_pipeline_files()

    result <- extract_swagger2_body_schema(list(), list())
    expect_equal(result$type, "unknown")
    expect_equal(length(result$properties), 0)
  })

  test_that("returns unknown for NULL parameters", {
    skip_on_cran()
    source_pipeline_files()

    result <- extract_swagger2_body_schema(NULL, list())
    expect_equal(result$type, "unknown")
  })

  test_that("handles object schemas with properties", {
    skip_on_cran()
    source_pipeline_files()

    parameters <- list(
      list(
        name = "data",
        `in` = "body",
        schema = list(
          type = "object",
          properties = list(
            id = list(type = "string")
          )
        )
      )
    )

    result <- extract_swagger2_body_schema(parameters, list())
    expect_equal(result$type, "object")
    expect_true("id" %in% names(result$properties))
  })

  test_that("handles string array schemas", {
    skip_on_cran()
    source_pipeline_files()

    parameters <- list(
      list(
        name = "queries",
        `in` = "body",
        schema = list(
          type = "array",
          items = list(type = "string")
        )
      )
    )

    result <- extract_swagger2_body_schema(parameters, list())
    expect_equal(result$type, "string_array")
    expect_equal(result$item_type, "string")
  })

  test_that("handles parameters with no in=body", {
    skip_on_cran()
    source_pipeline_files()

    parameters <- list(
      list(name = "id", `in` = "query", type = "string"),
      list(name = "limit", `in` = "query", type = "integer")
    )

    result <- extract_swagger2_body_schema(parameters, list())
    expect_equal(result$type, "unknown")
  })
})

describe("extract_body_properties()", {
  test_that("delegates to Swagger 2.0 extraction when schema_version is swagger", {
    skip_on_cran()
    source_pipeline_files()

    # For Swagger 2.0, request_body is actually parameters array
    parameters <- list(
      list(
        name = "body",
        `in` = "body",
        schema = list(type = "string")
      )
    )

    schema_version <- list(type = "swagger", version = "2.0")
    result <- extract_body_properties(parameters, list(), schema_version)

    expect_equal(result$type, "string")
  })

  test_that("handles OpenAPI 3.0 requestBody structure", {
    skip_on_cran()
    source_pipeline_files()

    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(
            type = "object",
            properties = list(
              query = list(type = "string")
            ),
            required = c("query")
          )
        )
      )
    )

    components <- list(schemas = list())
    schema_version <- list(type = "openapi", version = "3.0.0")
    result <- extract_body_properties(request_body, components, schema_version)

    expect_equal(result$type, "object")
    expect_true("query" %in% names(result$properties))
  })

  test_that("returns empty list for NULL request body", {
    skip_on_cran()
    source_pipeline_files()

    result <- extract_body_properties(NULL, list(), NULL)
    expect_equal(length(result), 0)
  })

  test_that("returns empty list for missing request body", {
    skip_on_cran()
    source_pipeline_files()

    result <- extract_body_properties(list(), list(), NULL)
    expect_equal(length(result), 0)
  })

  test_that("handles simple string type in OpenAPI 3.0", {
    skip_on_cran()
    source_pipeline_files()

    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(type = "string")
        )
      )
    )

    result <- extract_body_properties(
      request_body,
      list(),
      list(type = "openapi", version = "3.0.0")
    )

    expect_equal(result$type, "string")
    expect_true("query" %in% names(result$properties))
  })

  test_that("handles array type with items", {
    skip_on_cran()
    source_pipeline_files()

    request_body <- list(
      content = list(
        "application/json" = list(
          schema = list(
            type = "array",
            items = list(type = "string")
          )
        )
      )
    )

    result <- extract_body_properties(
      request_body,
      list(),
      list(type = "openapi", version = "3.0.0")
    )

    expect_equal(result$type, "string_array")
    expect_equal(result$item_type, "string")
  })
})
