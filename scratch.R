groq <- function(query) {
  GROQ_API_KEY <- "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"

  headers <- c(
    `Authorization` = paste("Bearer ", GROQ_API_KEY, sep = ""),
    `Content-Type` = "application/json"
  )

  data <- jsonlite::toJSON(
    list(
      messages = list(
        list(
          role = "user",
          content = query
        )
      ),
      model = "mixtral-8x7b-32768"
    ),
    auto_unbox = T
  )

  res <- httr::POST(
    url = "https://api.groq.com/openai/v1/chat/completions",
    httr::add_headers(.headers = headers),
    body = data,
    httr::progress()
  )

  res <- httr::content(
    res
    # , as = 'text'
  )
  res <- purrr::pluck(res, "choices", 1, "message", "content") %>% cat("\n", .)

  return(res)
}

# testing ----

df <- chemi_predict(query = "DTXSID1034187")

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "exact"
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "substructure",
  min_similarity = 0.8
)

df <- chemi_search(
  query = "DTXSID9025114",
  searchType = "similar",
  min_similarity = 0.8
)

df <- chemi_search(
  searchType = "features",
  element_inc = "Cr",
  element_exc = "ALL"
)

df <- ct_details(query = df$sid, projection = "structure")

###########################

query <- as.list(dtx_list$dtxsid[1:5])

burl <- paste0(Sys.getenv("chemi_burl"), "api/toxprints/calculate")

options <- list(
  "OR" = 3L,
  "PV1" = 0.05,
  "TP" = 3
)

chemicals <- vector(mode = "list", length = length(query))

chemicals <- map(query, ~ {
  list(
    sid = .x
  )
})

{
  chemicals <- list(
    list(
      # "id"= "34187",
      # "cid"= "DTXCID9014187",
      "sid" = "DTXSID1034187",
      # "casrn"= "10540-29-1",
      # "name"= "Tamoxifen",
      "smiles" = "C(/C1C=CC=CC=1)(\\C1=CC=C(C=C1)OCCN(C)C)=C(/CC)\\C1=CC=CC=C1"
      # "canonicalSmiles"= "CC/C(=C(\\C1C=CC=CC=1)/C1C=CC(=CC=1)OCCN(C)C)/C1C=CC=CC=1",
      # "inchi"= "InChI=1S/C26H29NO/c1-4-25(21-11-7-5-8-12-21)26(22-13-9-6-10-14-22)23-15-17-24(18-16-23)28-20-19-27(2)3/h5-18H,4,19-20H2,1-3H3/b26-25-",
      # "inchiKey"= "NKANXQFJJICGDU-QPLCGJKRSA-N",
      # "checked"= 'true'
    )
  )

  payload <- list(
    "chemicals" = chemicals,
    "options" = options
  ) %>%
    jsonlite::toJSON(., auto_unbox = T)

  df <- POST(
    url = burl,
    body = payload,
    content_type("application/json"),
    encode = "json",
    progress()
  ) %>%
    content(., "text", encoding = "UTF-8") %>%
    fromJSON(simplifyVector = TRUE)
}

# ct_search ---------------------------------------------------------------

ct_search <- function(
    type = c(
      "string",
      "mass"
      # ,'formula'
    ),
    search_param = c(
      "equal",
      "start-with",
      "substring"
    ),
    query,
    suggestions = TRUE,
    ccte_api_key = NULL) {
  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  {
    burl <- Sys.getenv("burl")
    string_url <- "chemical/search/equal/"
    formula_url <- "chemical/msready/search/by-formula/"
    mass_url <- "chemical/msready/search/by-mass/"
  }

  if (missing(type)) {
    cli::cli_abort("Missing type search")
  }

  # Mass --------------------------------------------------------------------


  if (type == "mass" & missing(search_param)) {
    cli::cli_abort("Missing mass range!")
  }

  if (type == "mass" & !missing(search_param)) {
    if (!is.numeric(query)) {
      query <- as.numeric(query)
    }

    if (!is.numeric(search_param)) {
      search_param <- as.numeric(search_param)
    }

    payload <- list(
      masses = query,
      error = search_param
    )

    cli::cli_rule(left = "Mass Payload options")
    cli::cli_dl(c(
      "Masses" = "{query}",
      "Error" = "{search_param}"
    ))

    df <- POST(
      url = paste0(burl, mass_url),
      body = jsonlite::toJSON(payload, auto_unbox = T),
      add_headers(`x-api-key` = token),
      content_type("application/json"),
      accept("application/json"),
      encode = "json",
      progress() # progress bar
    )

    df <- content(df, "text", encoding = "UTF-8") %>%
      jsonlite::fromJSON(simplifyVector = FALSE)

    return(df)
  }

  # String ------------------------------------------------------------------

  if (missing(suggestions)) {
    cli::cli_alert_warning("Defaulting to including suggestions!")
    cli::cli_alert_warning("Did you forget to specify `suggestions`?")
    cli::cli_text("")

    suggestions <- TRUE
  }

  if (type == "string" & missing(search_param)) {
    cli::cli_alert_warning("Defaulting to exact search!")
    cli::cli_alert_warning("Did you forget to specify which `search_param`?")

    # search_param <- match.arg(search_param, c('equal', 'start-with', 'substring'))

    df <- .string_search(query, sp = "equal", sugs = suggestions)
  } else {
    search_param <- match.arg(search_param, c("equal", "start-with", "substring"))

    df <- .string_search(query, sp = search_param, sugs = suggestions)
  }

  if (suggestions == FALSE) {
    df <- df %>%
      filter(!is.na(rank)) %>%
      select(!(contains("suggestion_")))
  } else {
    return(df)
  }
}

string_search <- function(query, sp = 'equal') {
  headers <- c(
    `x-api-key` = ct_api_key()
  )

  burl <- Sys.getenv("burl")

  # cli::cli_rule(left = "String Payload options")
  # cli::cli_dl(c(
  #   "Compound count" = "{length(query)}",
  #   "Search type" = "{sp}",
  #   "Suggestions" = "{sugs}"
  # ))

  query_search <- query #%>% str_replace_all(., pattern = " ", replacement = "%20")

  # Exact -------------------------------------------------------------------

  if (sp == "equal") {
    surl <- "chemical/search/"

    urls <- do.call(paste0, expand.grid(burl, surl, sp, "/", query_search))

    df <- map(urls, possibly(~ {
      response <- VERB("GET", url = .x, add_headers("x-api-key" = ct_api_key()))
      df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
    }, otherwise = NULL), .progress = T) %>%
      compact() %>%
      set_names(., query) %>%
      map_if(.,
        .p = is.data.frame, ~ {
          select(., -searchValue)
        },
        .else = ~ {
          pluck(., "suggestions") %>%
            as_tibble() %>%
            mutate(idx = 1:n(), .before = value) %>%
            pivot_wider(., names_prefix = "suggestion_", names_from = idx)
        }
      ) %>%
      list_rbind(., names_to = "searchValue")

    # string_url <- 'chemical/search/equal/'
    #
    # if(length(query) > 200){
    #
    #   cli::cli_alert_warning('Large request detected!')
    #
    #   sublists <- split(query, rep(1:ceiling(length(query)/200), each = 200, length.out = length(query)))
    #   sublists <- map(sublists, as.list)
    #
    #   df <- map(sublists, ~{
    #
    #     .x <- paste0(.x)
    #
    #     .x <- POST(
    #       url = paste0(burl, string_url),
    #       body = .x,
    #       add_headers(.headers = headers),
    #       content_type("application/json"),
    #       accept("application/json"),
    #       encode = "json",
    #       progress() # progress bar
    #     )
    #
    #     .x <- content(.x, "text", encoding = "UTF-8") %>%
    #       jsonlite::fromJSON(simplifyVector = TRUE)
    #
    #   }) %>% list_rbind()
    #
    # }else{
    #
    #   response <- POST(
    #     url = paste0(burl, string_url),
    #     body = query,
    #     content_type("application/json"),
    #     accept("application/json"),
    #     encode = 'json',
    #     add_headers(`x-api-key` = ct_api_key()),
    #     progress() #progress bar
    #   )
    #
    #   df <- content(response, "text", encoding = 'UTF-8') %>%
    #     jsonlite::fromJSON(simplifyVector = TRUE)
  } else {
    # Substring ---------------------------------------------------------------


    if (sp %in% c("start-with", "substring")) {
      surl <- "chemical/search/"

      urls <- do.call(paste0, expand.grid(burl, surl, search_param, "/", query_search))

      df <- map(urls, possibly(~ {
        response <- VERB("GET", url = .x, add_headers("x-api-key" = ct_api_key()))
        df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))
      }, otherwise = NULL), .progress = T) %>%
        compact() %>%
        set_names(., query) %>%
        map_if(.,
          .p = is.data.frame, ~ {
            select(., -searchValue)
          },
          .else = ~ {
            pluck(., "suggestions") %>%
              as_tibble() %>%
              mutate(idx = 1:n(), .before = value) %>%
              pivot_wider(., names_prefix = "suggestion_", names_from = idx)
          }
        ) %>%
        list_rbind(., names_to = "searchValue")
    } else {
      cli::cli_abort("Search parameter for `string` search failed!")
    }
  }
}
