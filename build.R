devtools::document()

fledge::bump_version(which = 'dev')
fledge::update_news()

devtools::build()

devtools::install()
