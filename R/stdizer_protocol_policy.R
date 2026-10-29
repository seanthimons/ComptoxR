# An empty optional sort vector selects omission, like NULL.
.ct_protocol_sort <- function(value) if (identical(value, character())) NULL else value
