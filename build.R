#Adding new testing chemicals

build_testing_chemicals(chems = c(

))

#Load latest data 
pt <- readRDS("C:\\Users\\STHIMONS\\Documents\\curation\\final\\pt.RDS")
usethis::use_data(pt, overwrite = TRUE)

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
