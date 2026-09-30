#' Resolver lookupCASRN
#'
#' @md
#' @description
#' `r lifecycle::badge("experimental")`
#' @param query Required parameter
#' @return Returns a list with result object
#' @apiStage public
#' @export
#' @examples
#' \dontrun{
#' chemi_resolver_lookupCASRN(query = "DTXSID7020182")
#' }
# Generated with specmill; do not edit by hand.
chemi_resolver_lookupCASRN <- function(query) {
  if (base::is.null(query)) {
    base::stop("Required input: query")
  }
  base::evalq(
    function(values, schemas, validate) {
      for (name in names(values)) {
        value <- values[[name]]
        if (is.null(value)) {
          next
        }
        schema <- schemas[[name]]
        if (
          identical(schema$type, "array") &&
            is.atomic(value) &&
            !is.object(value) &&
            is.null(dim(value)) &&
            is.null(names(value))
        ) {
          value <- as.list(value)
        }
        tryCatch(validate(value, schema), error = function(e) {
          stop("Invalid public input ", name, ": ", conditionMessage(e), call. = FALSE)
        })
      }
      invisible(NULL)
    },
    envir = base::baseenv()
  )(
    base::list("query" = query),
    list(query = list(type = "string", description = "Required parameter")),
    base::evalq(
      function(value, schema) {
        nodes <- 0L
        check_json <- function(value, depth = 0L) {
          nodes <<- nodes + 1L
          if (depth > 32L) {
            stop("Body depth limit exceeded (32); possible cycle")
          }
          if (nodes > 20000L) {
            stop("Body node limit exceeded (20000)")
          }
          if (is.environment(value)) {
            stop("Body contains an environment or cycle")
          }
          if (is.list(value)) {
            for (child in value) {
              check_json(child, depth + 1L)
            }
          }
        }
        check_json(value)
        definitions <- list()
        collect <- function(node) {
          id <- attr(node, "specmill_id")
          if (!is.null(id)) {
            definitions[[id]] <<- node
          }
          for (child in node$properties) {
            collect(child)
          }
          for (field in c("items", "additionalProperties")) {
            if (is.list(node[[field]])) {
              collect(node[[field]])
            }
          }
          for (field in c("allOf", "anyOf", "oneOf")) {
            for (child in node[[field]]) {
              collect(child)
            }
          }
        }
        collect(schema)
        validations <- 0L
        equal_json <- function(x, y) {
          if (is.list(x) || is.list(y)) {
            if (!is.list(x) || !is.list(y) || !identical(is.null(names(x)), is.null(names(y)))) {
              return(FALSE)
            }
            if (is.null(names(x))) {
              return(length(x) == length(y) && all(mapply(equal_json, x, y)))
            }
            if (!setequal(names(x), names(y))) {
              return(FALSE)
            }
            return(all(vapply(sort(names(x)), function(name) equal_json(x[[name]], y[[name]]), logical(1))))
          }
          if (is.numeric(x) && is.numeric(y)) {
            return(length(x) == 1L && length(y) == 1L && !is.na(x) && !is.na(y) && x == y)
          }
          identical(x, y)
        }
        validate <- function(value, schema, strict = FALSE) {
          validations <<- validations + 1L
          if (validations > 20000L) {
            stop("Body validation node limit exceeded (20000)")
          }
          ref <- attr(schema, "specmill_ref")
          if (!is.null(ref)) {
            schema <- definitions[[ref]]
            if (is.null(schema)) {
              stop("Missing recursive body definition")
            }
          }
          type <- unlist(schema$type, use.names = FALSE)
          strict <- strict || length(type) > 1L || any(c("oneOf", "anyOf", "allOf") %in% names(schema))
          if (is.object(value) || !is.null(dim(value))) {
            stop("Body must contain plain JSON values")
          }
          scalar <- is.atomic(value) && length(value) == 1L && !anyNA(value) && is.null(names(value))
          shape <- if (is.null(value)) {
            "null"
          } else if (is.list(value)) {
            if (is.null(names(value))) {
              "array"
            } else {
              "object"
            }
          } else if (!scalar) {
            ""
          } else if (is.character(value)) {
            "string"
          } else if (is.logical(value)) {
            "boolean"
          } else if (is.numeric(value) && is.finite(value) && value == trunc(value)) {
            "integer"
          } else if (is.numeric(value) && is.finite(value)) {
            "number"
          } else {
            ""
          }
          if (!nzchar(shape)) {
            stop("Invalid body scalar type")
          }
          legacy_empty_object <- !strict && identical(shape, "array") && !length(value) && identical(type, "object")
          if (
            shape != "null" &&
              length(type) &&
              !legacy_empty_object &&
              !(shape %in% type || (shape == "integer" && "number" %in% type))
          ) {
            stop("Invalid body scalar type")
          }
          if (shape == "null") {
            if (length(type) && !("null" %in% type) && !isTRUE(schema$nullable)) {
              stop("Explicit null body is not nullable")
            }
          } else if (shape == "object" || legacy_empty_object) {
            keys <- names(value)
            if (is.null(keys)) {
              keys <- character()
            }
            if (anyNA(keys) || anyDuplicated(keys) || any(!nzchar(keys))) {
              stop("Invalid body object names")
            }
            if (!all(unlist(schema$required) %in% keys)) {
              stop("Missing required body fields")
            }
            if (
              any(vapply(
                schema$properties[intersect(keys, names(schema$properties))],
                function(property) isTRUE(property$readOnly),
                logical(1)
              ))
            ) {
              stop("Read-only body fields are not allowed")
            }
            unknown <- setdiff(keys, names(schema$properties))
            if (length(unknown) && isFALSE(schema$additionalProperties)) {
              stop("Unknown body fields")
            }
            value <- lapply(seq_along(value), function(i) {
              child <- schema$properties[[keys[[i]]]]
              if (is.null(child)) {
                child <- if (is.list(schema$additionalProperties)) {
                  schema$additionalProperties
                } else {
                  list()
                }
              }
              validate(value[[i]], child, strict)
            })
            names(value) <- keys
          } else if (shape == "array") {
            if (
              (!is.null(schema$minItems) && length(value) < schema$minItems) ||
                (!is.null(schema$maxItems) && length(value) > schema$maxItems)
            ) {
              stop("Invalid body array length")
            }
            value <- lapply(value, validate, schema = schema$items, strict = strict)
          }
          numeric_value <- shape %in% c("integer", "number")
          if (
            numeric_value &&
              ((!is.null(schema$minimum) && value < schema$minimum) ||
                (!is.null(schema$maximum) && value > schema$maximum) ||
                (isTRUE(schema$exclusiveMinimum) && !is.null(schema$minimum) && value <= schema$minimum) ||
                (isTRUE(schema$exclusiveMaximum) && !is.null(schema$maximum) && value >= schema$maximum) ||
                (!is.null(schema$exclusiveMinimum) &&
                  is.numeric(schema$exclusiveMinimum) &&
                  value <= schema$exclusiveMinimum) ||
                (!is.null(schema$exclusiveMaximum) &&
                  is.numeric(schema$exclusiveMaximum) &&
                  value >= schema$exclusiveMaximum))
          ) {
            stop("Invalid body numeric bounds")
          }
          if (
            numeric_value &&
              !is.null(schema$multipleOf) &&
              abs(value / schema$multipleOf - round(value / schema$multipleOf)) > sqrt(.Machine$double.eps)
          ) {
            stop("Invalid body multipleOf")
          }
          if (
            shape == "string" &&
              ((!is.null(schema$minLength) && nchar(value) < schema$minLength) ||
                (!is.null(schema$maxLength) && nchar(value) > schema$maxLength) ||
                (!is.null(schema$pattern) && !grepl(schema$pattern, value, perl = TRUE)))
          ) {
            stop("Invalid body string")
          }
          if (!is.null(schema$enum) && !any(vapply(schema$enum, equal_json, logical(1), y = value))) {
            stop("Invalid body enum")
          }
          if ("const" %in% names(schema) && !equal_json(value, schema$const)) {
            stop("Invalid body const")
          }
          if (
            ((!is.null(schema$minProperties) &&
              is.list(value) &&
              !is.null(names(value)) &&
              length(value) < schema$minProperties) ||
              (!is.null(schema$maxProperties) &&
                is.list(value) &&
                !is.null(names(value)) &&
                length(value) > schema$maxProperties))
          ) {
            stop("Invalid body object size")
          }
          if (
            isTRUE(schema$uniqueItems) &&
              shape == "array" &&
              any(vapply(
                seq_along(value),
                function(i) {
                  any(vapply(value[seq_len(i - 1L)], equal_json, logical(1), y = value[[i]]))
                },
                logical(1)
              ))
          ) {
            stop("Duplicate body array items")
          }
          for (field in c("allOf", "anyOf", "oneOf")) {
            if (!field %in% names(schema)) {
              next
            }
            branches <- schema[[field]]
            if (is.null(branches)) {
              branches <- list()
            }
            matches <- vapply(
              branches,
              function(branch) {
                !inherits(try(validate(value, branch, TRUE), silent = TRUE), "try-error")
              },
              logical(1)
            )
            if (field == "allOf" && !all(matches)) {
              stop("Body allOf requires every branch")
            }
            if (field == "anyOf" && !any(matches)) {
              stop("Body anyOf matched no branches")
            }
            if (field == "oneOf" && sum(matches) != 1L) {
              stop("Body oneOf matched ", sum(matches), " branches; expected exactly one")
            }
          }
          value
        }
        validate(value, schema)
      },
      envir = base::baseenv()
    )
  )
  params <- base::list("query" = query)
  if (base::is.character(params[["query"]]) && base::any(!base::nzchar(params[["query"]]))) {
    base::stop("Empty query parameter: query")
  }
  result <- generic_request(
    "endpoint" = "resolver/lookupCASRN",
    "method" = "GET",
    "batch_limit" = 0,
    "server" = "chemi_burl",
    "auth" = FALSE,
    "tidy" = FALSE,
    "options" = base::local({
      .body <- base::Filter(base::Negate(base::is.null), base::list("query" = params[["query"]]))
      if (base::length(.body)) .body else base::list()
    })
  )
  result
}
