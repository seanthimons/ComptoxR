
# ct_search_mass <- function(start, end, ccte_api_key = NULL, debug = F){

#   if (is.null(ccte_api_key)) {
#     token <- ct_api_key()
#   }

#   burl <- Sys.getenv('burl')
#   surl <- "chemical/msready/search/by-mass/"
#   start_mass <- start
#   end_mass <- end
#   urls <- paste0(burl, surl, start_mass, '/', end_mass)

#   df <- map_dfr(urls, ~{

#     if (debug == TRUE) {
#       cat(.x, "\n")
#     }


#     response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
#     df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
#   })

#   df <- ct_details(df$value) %>%
#     filter(multicomponent != 1) %>%
#     filter(monoisotopicMass >= start_mass & monoisotopicMass <= end_mass)

#   return(df)
# }

# ct_search_formula <- function(query, ccte_api_key = NULL, debug = F){

#   if (is.null(ccte_api_key)) {
#     token <- ct_api_key()
#   }

#   burl <- Sys.getenv('burl')
#   surl <- "chemical/msready/search/by-formula/"

#   urls <- paste0(burl, surl, query)

#   df <- map_dfr(urls, ~{

#     if (debug == TRUE) {
#       cat(.x, "\n")
#     }

#     response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
#     df <- fromJSON(content(response, as = "text", encoding = "UTF-8")) %>% as_tibble()
#   })

#   df <- ct_details(df$value) %>% filter(multicomponent != 1)

#   return(df)
# }


# ct_name <- function(query,
#                     param = c('start-with',
#                               'equal',
#                               'contain'),

#                     ccte_api_key = NULL,
#                     debug = F){

#   if (is.null(ccte_api_key)) {
#     token <- ct_api_key()
#   }
#   burl <- Sys.getenv('burl')

#   if(identical(c('start-with',
#                  'equal',
#                  'contain'),param)){
#     cli_alert_warning('Large request detected!')
#     cli_alert_warning('Request may time out!')
#     cli_alert_warning('Recommend to change search parameters or break up requests!\n')
#   }else{cat('\nParameter(s) declared:',param)}

#   cat("\nRequesting valid names by provided search parameters....\n\n")

#   surl <- "chemical/search/"

#   urls <- do.call(paste0, expand.grid(burl,surl,param,'/',query))

#   df <- map(urls, possibly(~{

#     if (debug == TRUE) {
#       cat(.x, "\n")
#     }

#     response <- VERB("GET", url = .x, add_headers("x-api-key" = token))
#     df <- fromJSON(content(response, as = "text", encoding = "UTF-8"))

#   }, otherwise = NULL)) %>%
#     compact %>%
#     map_dfr(as.data.frame)

#   df <- if('rank' %in% colnames(df)){arrange(df,rank)} else{df}
#   df <-df %>% as_tibble()
#   return(df)
# }


# colorize <- function(text, fg = "white", bg = NULL) {

#   col <- .fg_colours[tolower(fg)]
#   #print(col)

#   if (!is.null(bg)) {
#     col <- paste0(col, ";",.bg_colours[tolower(bg)])
#     #print(col)
#   }

#   paste0("\033[",col,';m', text, "\033[0m")
# }

# .fg_colours <- c(
#   "black" = "0;30",
#   "blue" = "0;34",
#   "green" = "0;32",
#   "cyan" = "0;36",
#   "red" = "0;31",
#   "purple" = "0;35",
#   "brown" = "0;33",
#   "light gray" = "0;37",
#   "dark gray" = "1;30",
#   "light blue" = "1;34",
#   "light green" = "1;32",
#   "light cyan" = "1;36",
#   "light red" = "1;31",
#   "light purple" = "1;35",
#   "yellow" = "1;33",
#   "white" = "1;37"
# )

# .bg_colours <- c(
#   "black" = "40",
#   "red" = "41",
#   "green" = "42",
#   "brown" = "43",
#   "blue" = "44",
#   "purple" = "45",
#   "cyan" = "46",
#   "light gray" = "47"
# )




