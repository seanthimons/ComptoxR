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
saveRDS(contracts, 'tests/testthat/fixtures/specmill-pilot-contracts.rds', version = 3)
