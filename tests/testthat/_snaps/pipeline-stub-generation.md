# snapshot test - simple GET endpoint

    Code
      cat("Function signature:\n")
    Output
      Function signature:
    Code
      signature <- stringr::str_extract(stub, "test_function <- function\\([^)]*\\)")
      cat(signature)
    Output
      test_function <- function()
    Code
      cat("\n\nGeneric request call:\n")
    Output
      
      
      Generic request call:
    Code
      request_call <- stringr::str_extract(stub, "generic_request\\([^}]+endpoint")
      cat(request_call)
    Output
      generic_request(
          endpoint = "/test/endpoint

# snapshot test - POST with body params

    Code
      cat("Function signature:\n")
    Output
      Function signature:
    Code
      signature <- stringr::str_extract(stub, "test_function <- function\\([^)]+\\)")
      cat(signature)
    Output
      test_function <- function(data, optional = NULL)
    Code
      cat("\n\nBody building:\n")
    Output
      
      
      Body building:
    Code
      body_code <- stringr::str_extract(stub,
        "# Build request body[^}]+body \\<- list\\(\\)")
      if (!is.na(body_code)) cat(body_code)
    Output
      # Build request body
        body <- list()

# snapshot test - endpoint with path parameters

    Code
      cat("Path parameter handling:\n")
    Output
      Path parameter handling:
    Code
      path_code <- stringr::str_extract(stub, "path_params = c\\([^)]+\\)")
      cat(path_code)
    Output
      path_params = c(id = id)

# snapshot test - paginated offset_limit endpoint

    Code
      cat("Function signature:\n")
    Output
      Function signature:
    Code
      signature <- stringr::str_extract(stub, "test_function <- function\\([^)]+\\)")
      cat(signature)
    Output
      test_function <- function(limit, offset = 0, all_pages = TRUE)
    Code
      cat("\n\nGeneric request call:\n")
    Output
      
      
      Generic request call:
    Code
      request_call <- stringr::str_extract(stub, "generic_request\\([\\s\\S]*?\\)")
      cat(request_call)
    Output
      generic_request(
          query = limit,
          endpoint = "/test/endpoint",
          method = "GET",
          batch_limit = 1,
          path_params = c(offset = offset)

