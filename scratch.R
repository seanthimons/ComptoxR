test <- tribble(
~compound,~oral_amount,~dermal_amount,~bac_amount,~cancer_amount,
'A',5,5,180,13,
'B', 10, 1,60,12,
'C',15,20,360,NA,
'D', NA, NA, NA,NA,
'E',1,1,NA,NA,
'F',2,2,NA,NA
)

####
#tp <- tp[, which((names(tp) %in% endpoint_filt_weight$endpoint) == TRUE)]


ID <- 'compound'
tp <- test %>% select(c(ID,bias$endpoint))

tp_scores <- tp %>%
  mutate(across(where(is.numeric),
                ~ if(sd(na.omit(.)) == 0)
                {ifelse(is.na(.), NA, 1)}
                else {tp_single_score(.) %>%
                    round(digits = 3)
                }))

tp_scores2 <- tp_scores %>%
  mutate(across(where(is.numeric), ~ {
    min_val <- min(.[-which(. == 0)], na.rm = T)
    replace(., . == 0, 0.5 * min_val)
  })) %>%
  mutate(across(where(is.numeric), ~replace_na(.,0)))


bias <- bias %>%
  select(endpoint, weight) %>%
  pivot_wider(names_from = endpoint,
              values_from = weight)

tp_names <- tp_scores2[,ID]

tp_scores2 <- data.frame(mapply('*',tp_scores2[,2:ncol(tp_scores2)], bias))

tp_scores2 <- cbind(tp_names, tp_scores2)

tp_scores3 <- tp_scores2 %>%
  rowwise() %>%
  mutate(score = sum(c_across(cols = !contains(ID))))
