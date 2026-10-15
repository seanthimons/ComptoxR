# Fixed expectations reviewed against the client helper contract, not rendered code.
# Run before generation when intentionally updating these fixtures.
response <- tibble::tibble(dtxsid = 'DTXSID7020182', name = 'Benzene')
contract <- function(inputs, arguments, response, result = response, helper = 'generic_request', environment = NULL) {
  out <- list(
    inputs = inputs,
    calls = list(list(helper = helper, arguments = arguments, response = response)),
    result = result
  )
  if (!is.null(environment)) {
    out$environment <- environment
  }
  out
}
contracts <- list(
  epi_search = contract(
    list(query = 'benzene'),
    list(
      endpoint = 'search',
      method = 'GET',
      batch_limit = 0,
      server = 'epi_burl',
      auth = FALSE,
      tidy = FALSE,
      query_params = list(query = 'benzene', limit = 20)
    ),
    list(list(name = 'Benzene', smiles = 'c1ccccc1', cas = '71-43-2')),
    tibble::tibble(name = 'Benzene', smiles = 'c1ccccc1', cas = '71-43-2')
  ),
  chemi_alerts_groups_by_id = contract(
    list(id = 'group-1'),
    list(
      query = 'group-1',
      endpoint = 'alerts/groups/',
      method = 'GET',
      batch_limit = 1,
      server = 'chemi_burl',
      auth = FALSE,
      tidy = FALSE
    ),
    list(list(id = 'group-1'))
  ),
  ct_chemical_detail_search = contract(
    list(dtxsid = 'DTXSID7020182'),
    list(
      query = 'DTXSID7020182',
      endpoint = 'chemical/detail/search/by-dtxsid/',
      method = 'GET',
      batch_limit = 1,
      projection = 'chemicaldetailall'
    ),
    response
  ),
  ct_chemical_detail_search_bulk = contract(
    list(query = c('DTXSID7020182', 'DTXSID1024122')),
    list(
      query = c('DTXSID7020182', 'DTXSID1024122'),
      endpoint = 'chemical/detail/search/by-dtxsid/',
      method = 'POST',
      batch_limit = 2,
      projection = 'chemicaldetailall'
    ),
    response,
    environment = list(batch_limit = '2')
  ),
  ct_chemical_list_all = contract(
    list(return_dtxsid = TRUE),
    list(endpoint = 'chemical/list/all', method = 'GET', batch_limit = 0, projection = 'chemicallistwithdtxsids'),
    tibble::tibble(listName = 'pilot', dtxsids = 'DTXSID7020182')
  ),
  chemi_search = contract(
    list(search_type = 'features'),
    list(
      endpoint = 'search',
      body = list(
        inputType = 'MOL',
        searchType = 'FEATURES',
        params = list(limit = 50),
        query = "\n  Ketcher  4112412132D 1   1.00000     0.00000     0\n\n  0  0  0     0  0            999 V2000\nM  END\n"
      ),
      options = list(limit = 50),
      tidy = FALSE,
      paginate = FALSE,
      max_pages = 100,
      pagination_strategy = 'offset_limit'
    ),
    list(totalRecordsCount = 1, records = list(list(sid = 'DTXSID7020182'))),
    tibble::tibble(sid = 'DTXSID7020182'),
    helper = 'generic_chemi_request'
  )
)
# Independent expectations for the lookup expansion. Paths retain trailing slashes.
lookups <- list(
  chemi_alerts_alerts = list(endpoint = 'alerts/alerts'),
  chemi_alerts_operations = list(endpoint = 'alerts/operations'),
  chemi_amos_release_notes = list(endpoint = 'amos/release_notes'),
  chemi_amos_get_data_source_info = list(endpoint = 'amos/get_data_source_info/'),
  chemi_amos_get_ir_spectrum = list(endpoint = 'amos/get_ir_spectrum/', parameter = 'internal_id', value = 'ir-1'),
  chemi_amos_get_nmr_spectrum = list(endpoint = 'amos/get_nmr_spectrum/', parameter = 'internal_id', value = 'nmr-1'),
  chemi_amos_get_mass_spectrum = list(endpoint = 'amos/get_mass_spectrum/', parameter = 'internal_id', value = 'ms-1'),
  chemi_amos_get_info_by_id = list(endpoint = 'amos/get_info_by_id/', parameter = 'internal_id', value = 'record-1'),
  chemi_amos_get_classification_for_dtxsid = list(
    endpoint = 'amos/get_classification_for_dtxsid/',
    parameter = 'dtxsid',
    value = 'DTXSID7020182'
  ),
  chemi_amos_by_text = list(endpoint = 'amos/search_by_text/', parameter = 'substr', value = 'benzene')
)
for (name in names(lookups)) {
  lookup <- lookups[[name]]
  inputs <- if (is.null(lookup$parameter)) list() else setNames(list(lookup$value), lookup$parameter)
  arguments <- list(
    endpoint = lookup$endpoint,
    method = 'GET',
    batch_limit = if (length(inputs)) 1 else 0,
    server = 'chemi_burl',
    auth = FALSE,
    tidy = FALSE
  )
  if (length(inputs)) {
    arguments <- c(list(query = lookup$value), arguments)
  }
  contracts[[name]] <- contract(inputs, arguments, list(list(id = 'record-1')))
}
saveRDS(contracts, 'tests/testthat/fixtures/specmill-pilot-contracts.rds', version = 3)
