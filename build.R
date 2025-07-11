#Adding new testing chemicals

build_testing_chemicals(chems = c(

))

#Checks documentation
devtools::document()

#Adds NEWS
fledge::bump_version(which = 'dev')
fledge::update_news()

#Builds Windows ZIP
devtools::build(binary = TRUE)

#Clean, build, and install, reload
#Cntrl + Shift + B
devtools::install(pkg = ".", dependencies = TRUE, reload = TRUE)
