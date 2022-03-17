library(here)
library(tidymodels)
#library(tidyverse)
#library(parallel)
library(doParallel)
library(finetune)
#library(tune)
#library(dials)

options(tidymodels.dark = TRUE)

source(here("src/functions.R"))

# data <- readRDS(here("data/data.rds")) %>%
#     slice(1:500) %>% # to speed things up
#         select(sud, prev_narc, prev_viol, cvi, prev_psych, 
#                youth_crime, edu, meds, born_outside_nordic,
#                general_crime) %>%
#         rename(outcome = general_crime)
# 
# set.seed(2022)
# data_split <- initial_split(data, strata = outcome)
# data_train <- training(data_split)
# data_test  <- testing(data_split)

# for testing purposes
data_train <- data.frame(outcome = factor(rep(c("yes", "no"), each = 250, times = 2)),
                         x1 = as.numeric(c(rbinom(250, 1, 0.8), rbinom(250, 1, 0.2))),
                         x2 = as.numeric(c(rbinom(250, 1, 0.7), rbinom(250, 1, 0.3))),
                         x3 = as.numeric(c(rbinom(250, 1, 0.6), rbinom(250, 1, 0.4))),
                         x4 = as.numeric(c(rbinom(250, 1, 0.7), rbinom(250, 1, 0.3))),
                         x5 = as.numeric(c(rbinom(250, 1, 0.8), rbinom(250, 1, 0.2))))

data_train$outcome <- relevel(data_train$outcome, ref = "yes")
data_folds <- vfold_cv(data_train, strata = outcome, v = 5, repeats = 5)

sel_outcome <- "general_crime"
cores <- 6 
tune_length <- 20L

bayes_initial <- 5L
bayes_improve <- 5
bayes_iter <- 20

nnet_epochs <- 100
brulee_epochs <- 100
brulee_patience  <- 10
keras_epochs <- 100
keras_patience  <- 10

model_vec <- c("nnet",
               "brulee_dropout",
               "brulee_penalty",
               "xgboost",
               "ranger",
               "dbart",
               "svm_linear",
               "svm_radial",
               "svm_poly")

train_model("nnet")
#lapply(model_vec, train_model)
