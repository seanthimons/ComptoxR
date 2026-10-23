# Isolated released generation. Never writes the parent pin/helper/manifest/config.
folder <- 'dev/specmill-rebuild/released-facades-v42'
lib <- Sys.getenv('SPECMILL_LIBRARY', '/home/sxthi/Documents/Projects/ComptoxR/dev/specmill-pilot/artifacts/toolkit-library/0.1.42')
loadNamespace('specmill', lib.loc = lib)
metadata <- utils::packageDescription('specmill', lib.loc = lib)
stopifnot(identical(metadata$Version, '0.1.42'),
  identical(metadata[['Config/specmill/source-commit']], 'b17a0856263e0179a164a9673399f221168cda6d'),
  identical(metadata[['Config/specmill/source-archive-sha256']], 'dbd15b2509171431f00a193a648f426a02873aee5e16a73de740d30b56792351'))
callbacks <- new.env(parent = baseenv())
sys.source('dev/specmill_callbacks.R', callbacks)
sys.source('dev/specmill-rebuild/rootheldrelease/callbacks.R', callbacks)
sys.source(file.path(folder, 'callbacks.R'), callbacks)
