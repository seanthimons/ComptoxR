.onAttach <- function(libname, ComptoxR) {

  if(Sys.getenv('burl') == "" | Sys.getenv("chemi_burl") == ""){
    ct_server()
    chemi_server()
  }

  packageStartupMessage(
    .header()
  )
}

.header <- function(){

  if(is.na(build_date <- utils::packageDate('ComptoxR'))){
    build_date <- as.character(Sys.Date())
  }else{
    build_date <- as.character(utils::packageDate('ComptoxR'))
  }

  cli::cli({
    cli::cli_rule()

    cli::cli_alert_success(
      c("This is version ", {as.character(utils::packageVersion('ComptoxR'))}," of ComptoxR"))
    cli::cli_alert_success(
      c('Built on: ', {build_date})
    )
    cli::cli_rule()
    cli::cli_alert_warning('Available API endpoints:')
    cli::cli_dl(c(
      'CompTox' = '{Sys.getenv("burl")}',
      'Cheminformatics' =  '{Sys.getenv("chemi_burl")}'
    ))
  })

  run_setup()

}
