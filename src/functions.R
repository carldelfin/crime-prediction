train_model <- function(model) {
    
    cat("\n", model, "training started on:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

    data_train_pred <- data_train %>% select(-outcome)
    mod_rec <- recipe(outcome ~ ., data = data_train)
    log_loss_res <- metric_set(mn_log_loss)

    mod_t1 <- Sys.time()

    # ----------------------------------------------------------------------------------------------
    # mlp with 'nnet' engine
    # ----------------------------------------------------------------------------------------------

    if (model == "nnet") {
        mod_spec <- mlp(epochs = nnet_epochs,
                        hidden_units = tune(),
                        penalty = tune()) %>% 
        set_engine("nnet", 
                   trace = 0,
                   MaxNWts = 100000) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # mlp with 'brulee' engine + penalty
    # ----------------------------------------------------------------------------------------------

    } else if (model == "brulee_penalty") {

        mod_spec <- mlp(epochs = brulee_epochs,
                        hidden_units = tune(),
                        penalty = tune(),
                        learn_rate = tune(),
                        activation = tune()) %>% 
        set_engine("brulee",
                   verbose = FALSE) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # mlp with 'brulee' engine + dropout 
    # ----------------------------------------------------------------------------------------------
    
    } else if (model == "brulee_dropout") {

        mod_spec <- mlp(epochs = brulee_epochs,
                        hidden_units = tune(),
                        dropout = tune(),
                        learn_rate = tune(),
                        activation = tune()) %>% 
        set_engine("brulee",
                   verbose = FALSE) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # mlp with 'keras' engine + penalty 
    # ----------------------------------------------------------------------------------------------
    
    } else if (model == "keras_penalty") {
        
        keras_callbacks <- list(
            keras::callback_early_stopping(monitor = "loss",
                                           mode = "min",
                                           min_delta = 0,
                                           patience = keras_patience,
                                           restore_best_weights = TRUE))

        mod_spec <- mlp(epochs = keras_epochs,
                        activation = "relu", 
                        hidden_units = tune(),
                        penalty = tune()) %>% 
        set_engine("keras",
                   verbose = 0,
                   callbacks = keras_callbacks) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # mlp with 'keras' engine + dropout 
    # ----------------------------------------------------------------------------------------------

    } else if (model == "keras_dropout") {
        
        keras_callbacks <- list(
            keras::callback_early_stopping(monitor = "loss",
                                           mode = "min",
                                           min_delta = 0,
                                           patience = keras_patience,
                                           restore_best_weights = TRUE))

        mod_spec <- mlp(epochs = keras_epochs,
                        activation = "relu", 
                        hidden_units = tune(),
                        dropout = tune()) %>% 
        set_engine("keras",
                   verbose = 0,
                   callbacks = keras_callbacks) %>% 
        set_mode("classification")

    # ----------------------------------------------------------------------------------------------
    # xgboost
    # ----------------------------------------------------------------------------------------------

    } else if (model == "xgboost") {

        mod_spec <- boost_tree(trees = 10000,
                               learn_rate = 0.001, 
                               tree_depth = tune(), 
                               mtry = tune(),
                               loss_reduction = tune(), 
                               min_n = tune(), 
                               sample_size = tune()) %>%  
        set_engine("xgboost", 
                   nthread = 1, 
                   verbose = 0, 
                   event_level = "first") %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # ranger 
    # ----------------------------------------------------------------------------------------------
    
    } else if (model == "ranger") {
        mod_spec <- rand_forest(trees = 10000,
                                mtry = tune(),
                                min_n = tune()) %>% 
        set_engine("ranger",
                   regularization.factor = tune("regularization"),
                   num.threads = 1) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # dbart
    # ----------------------------------------------------------------------------------------------

    } else if (model == "dbart") {
        mod_spec <- bart(trees = tune(),
                         prior_terminal_node_coef = tune(),
                         prior_terminal_node_expo = tune(),
                         prior_outcome_range = tune()) %>% 
        set_engine("dbarts",
                   nthread = 1,
                   seed = 2022) %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # svm_linear
    # ----------------------------------------------------------------------------------------------

    } else if (model == "svm_linear") {
        mod_spec <- svm_linear(cost = tune()) %>% 
        set_engine("kernlab") %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # svm_radial
    # ----------------------------------------------------------------------------------------------

    } else if (model == "svm_radial") {
        mod_spec <- svm_rbf(cost = tune(),
                            rbf_sigma = tune()) %>% 
        set_engine("kernlab") %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # svm_poly
    # ----------------------------------------------------------------------------------------------

    } else if (model == "svm_poly") {
        mod_spec <- svm_poly(cost = tune(),
                             degree = tune(),
                             scale_factor = tune()) %>% 
        set_engine("kernlab") %>% 
        set_mode("classification")
    
    # ----------------------------------------------------------------------------------------------
    # mars 
    # ----------------------------------------------------------------------------------------------

    } else if (model == "mars") {
        mod_spec <- mars(num_terms = tune("mars terms"),
                         prod_degree = tune(),
                         prune_method = "none") %>% 
        set_engine("earth") %>% 
        set_mode("classification")
    }
    
    # ==============================================================================================
    # create workflow and start modeling
    # ==============================================================================================

    mod_param <- extract_parameter_set_dials(mod_spec)
    mod_param <- finalize(mod_param, data_train_pred)

    mod_wf <- workflow() %>% 
        add_model(mod_spec) %>% 
        add_recipe(mod_rec)

    # parallel processing?
    #if (model %in% c("keras_dropout", "keras_penalty")) {
        #cl <- makeCluster(cores, type = "FORK")
    #} else {
    cl <- makePSOCKcluster(cores)
    registerDoParallel(cl)
    #}


    # start model
    mod_tuned <- mod_wf %>%
        tune_bayes(resamples = data_folds,
                   metrics = log_loss_res,
                   initial = bayes_initial,
                   param_info = mod_param,
                   iter = bayes_iter,
                   control = control_bayes(verbose = TRUE,
                                           no_improve = bayes_improve,
                                           uncertain = Inf,
                                           seed = 2022,
                                           event_level = "first",
                                           parallel_over = "everything"))
#     set.seed(2022)
#     search_grid <- grid_latin_hypercube(mod_param,
#                                         size = tune_length,
#                                         original = TRUE)
# 
#     mod_tuned <- mod_wf %>%
#         #tune_race_anova(resamples = data_folds,
#         tune_race_win_loss(resamples = data_folds,
#                         metrics = log_loss_res,
#                         param_info = mod_param,
#                         grid = search_grid,
#                         control = control_race(verbose = FALSE,
#                                                verbose_elim = TRUE,
#                                                burn_in = 5,
#                                                num_ties = 10,
#                                                event_level = "first",
#                                                parallel_over = "everything"))
# 
    # stop parallel processing?
    #if (exists("cl")) {
    stopCluster(cl)
    registerDoSEQ()
    #}

    best_log_loss <- show_best(mod_tuned) %>% 
        select(mean, std_err) %>% 
        as.data.frame() %>% 
        mutate_all(round, 3) %>%
        slice(1)
    
    best_param <- select_best(mod_tuned, metric = "mn_log_loss")
    final_mod_wf <- mod_wf %>% finalize_workflow(best_param)
    final_mod_fit <- final_mod_wf %>% fit(data_train)
   
    # stop timer
    mod_t2 <- Sys.time()
    mod_exec_time <- lubridate::seconds_to_period(round(difftime(mod_t2, mod_t1, units = "secs")[[1]], 2))
    cat("",
        model,
        "training complete on:", 
        format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
        "after",
        mod_exec_time@hour,
        "hour(s) and", 
        mod_exec_time@minute,
        "minute(s)\n",
        "estimated log loss:",
        best_log_loss$mean,
        "with std. err.",
        best_log_loss$std_err,
        "\n")
    
    # save
    saveRDS(best_param, here(paste0("output/param_", tune_length, "_", sel_outcome, "_", model, ".rds")))
    saveRDS(final_mod_fit, here(paste0("output/mod_", tune_length, "_", sel_outcome, "_", model, ".rds")))
    saveRDS(mod_exec_time, here(paste0("output/time_", tune_length, "_", sel_outcome, "_", model, ".rds")))
}
