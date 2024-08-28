ct_file <- function(query, ccte_api_key = NULL){

  if (is.null(ccte_api_key)) {
    token <- ct_api_key()
  }

  # request -----------------------------------------------------------------

  burl <- Sys.getenv('burl')

  # df <- map(query, function(x){
  #
  # #cat(x, '\n')
  #
  # response <- GET(
  #     url = paste0(burl, 'chemical-file/mol/search/by-dtxsid/', x),
  #     add_headers(`x-api-key` = token)
  # )
  #
  # if(response$status_code == 200){
  #   df <- content(response, "text", encoding = "UTF-8")
  # }else{paste0('Bad file request: ', x)}
  #
  # }, .progress = T)
  #
  # return(df)

    response <- GET(
      url = paste0(burl, 'chemical-file/mol/search/by-dtxsid/', query),
      add_headers(`x-api-key` = token)
    )

    if(response$status_code == 200){
      df <- content(response, "text", encoding = "UTF-8")
      return(df)
    }else{paste0('Bad file request: ', x)}

}
