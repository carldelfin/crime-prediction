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

#data <- readRDS(here("data/data.rds")) %>%
data <- readRDS("~/Documents/work/projects/DAABS_ml_recid/data/data.rds") %>%
    slice(1:1000) %>% # to speed things up
        select(sud, prev_narc, prev_viol, cvi, prev_psych, 
               youth_crime, edu, meds, born_outside_nordic,
               general_crime) %>%
        rename(outcome = general_crime)

set.seed(2022)
data_split <- initial_split(data, strata = outcome)
data_train <- training(data_split)
data_test  <- testing(data_split)

# for testing purposes
# set.seed(2020)
# nn <- 1000
# data_train <- data.frame(outcome = factor(rep(c("yes", "no"), each = nn, times = 2)),
#                          x1 = as.numeric(c(rbinom(nn, 1, 0.8), rbinom(nn, 1, 0.2))),
#                          x2 = as.numeric(c(rbinom(nn, 1, 0.7), rbinom(nn, 1, 0.3))),
#                          x3 = as.numeric(c(rbinom(nn, 1, 0.6), rbinom(nn, 1, 0.4))),
#                          x4 = as.numeric(c(rbinom(nn, 1, 0.7), rbinom(nn, 1, 0.3))),
#                          x5 = as.numeric(c(rbinom(nn, 1, 0.8), rbinom(nn, 1, 0.2))),
#                          x6 = as.numeric(c(rbinom(nn, 1, 0.9), rbinom(nn, 1, 0.1))),
#                          x7 = as.numeric(c(rbinom(nn, 1, 0.9), rbinom(nn, 1, 0.1))),
#                          x8 = as.numeric(c(rbinom(nn, 1, 0.9), rbinom(nn, 1, 0.1))))
# 
# data_train$outcome <- relevel(data_train$outcome, ref = "yes")

data_folds <- vfold_cv(data_train, strata = outcome, v = 10, repeats = 10)

sel_outcome <- "general_crime"
cores <- 16 
tune_length <- 500L

bayes_initial <- 10L
bayes_improve <- 10
bayes_iter <- 500

nnet_epochs <- 100
brulee_epochs <- 100
brulee_patience  <- 10
keras_epochs <- 100
keras_patience <- 10

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
