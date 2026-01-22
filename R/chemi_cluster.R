# R/chemi_cluster.R
#' Get chemical similarity map
#'
#' @param chemicals vector of chemical names
#' @param sort boolean to sort or not
#' @param hclust_method character string indicating which clustering method to use in `hclust`.
#'   Defaults to "complete". See `?hclust` for available methods.
#'
#' @return List
#' @export

chemi_cluster <- function(
	chemicals,
	sort = TRUE,
	hclust_method = "complete"
) {
	if (is.null(sort) | missing(sort)) {
		cli::cli_abort('Missing sort!')
	}

	chemicals <- chemi_resolver(chemicals, id_type = 'DTXSID', mol = FALSE)

	cli_rule(left = "Similarity payload options")
	cli_dl(
		c(
			"Number of compounds" = "{length(chemicals)}",
			"Sort" = "{sort}"
		)
	)
	cli_rule()
	cli_end()

	req <- request(
		Sys.getenv('chemi_burl')
	) %>%
		req_method("POST") %>%
		req_url_path_append("resolver/getsimilaritymap") %>%
		req_url_query(sort = tolower(as.character(sort))) %>%
		req_headers(
			accept = "application/json, text/plain, */*"
		) %>%
		req_body_json(
			list(
				'chemicals' = chemicals
			)
		)

	if (Sys.getenv("run_debug") == "TRUE") {
		cli::cli_alert_info('DEBUGGING REQUEST')
		print(req)
	}

	resp <- req %>%
		req_retry(max_tries = 3, is_transient = \(resp) {
			resp_status(resp) %in% c(429, 500, 502, 503, 504)
		}) %>%
		req_perform()

	parsed_resp <- resp %>%
		resp_body_json()

	# Check if any data was found.
	if (length(parsed_resp) > 0) {} else {
		cli::cli_alert_danger('No data found!')
		return(NULL)
	}

	mol_names <- parsed_resp %>%
		pluck(., 'order') %>%
		map(., ~ pluck(.x, 'chemical')) %>%
		map(
			.,
			~ keep(
				.x,
				names(.x) %in%
					c(
						# TODO removed the DTXSID field as some compounds don't have it? Very odd.
						#	'sid',
						'name'
					)
			)
		) %>%
		map(., as_tibble) %>%
		list_rbind() %>%
		select(
			# TODO removed the DTXSID field as some compounds don't have it? Very odd.
			#dtxsid = sid,
			name = name
		)

	# Is there a way to fix this locally by altering the lists when there is no color, which indicates perfect similarity?
	similarity <- parsed_resp %>%
		pluck(., 'similarity') %>%
		map(
			.,
			~ map(., ~ discard_at(.x, 'cl')) %>%
				list_flatten() %>%
				unname() %>%
				list_c()
		)

	# ! NOTE removed the %>% replace(., . == 0, 1), as that was giving false positives.

	hc <- matrix(unlist(similarity), nrow = length(similarity), byrow = TRUE) %>%
		`colnames<-`(mol_names$name) %>%
		`row.names<-`(mol_names$name) %>%
		# Creates Tanimoto matrix
		{
			1 - .
		} %>%
		as.dist(.) %>%
		hclust(method = hclust_method)

	# Final output -----------------------------------------------------------

	list(
		mol_names = mol_names,
		similarity = similarity,
		hc = hc
	)
}

#' Create a similarity list from chemical cluster data
#'
#' @description Converts a similarity matrix into a long-format data frame.
#'
#' @param chemi_cluster_data A list object containing chemical cluster data, including `mol_names` and a `similarity` matrix.
#'
#' @returns A tibble with columns for parent and child chemical identifiers, their names, and the similarity value between them. The function will error if `chemi_cluster_data` is `NULL` or missing.
#'
#' @export
chemi_cluster_sim_list <- function(chemi_cluster_data) {
	if (missing(chemi_cluster_data) || is.null(chemi_cluster_data)) {
		cli::cli_abort("Missing chemi_cluster_data!")
	}

	mol_names <- chemi_cluster_data$mol_names
	similarity <- chemi_cluster_data$similarity

	sim_list <- similarity %>%
		set_names(., mol_names$name) %>%
		map(., ~ set_names(.x, mol_names$name)) %>%
		map(., ~ enframe(.x, name = 'child', value = 'value')) %>%
		list_rbind(., names_to = 'parent') %>%
	# ! NOTE Removes perfect correlations
		filter(parent != child) #%>%
	# ! NOTE Commented out due to DTXSID not always being present.
	# left_join(., mol_names, join_by('parent' == 'name')) %>%
	# left_join(., mol_names, join_by('child' == 'name')) %>%
	# select(
	# 	parent,
	# 	parent_name = name.x,
	# 	child,
	# 	child_name = name.y,
	# 	value
	# )
	return(sim_list)
}
