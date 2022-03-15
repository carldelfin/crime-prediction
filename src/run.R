library(here)
library(tidymodels)
library(tidyverse)
library(parallel)
library(doParallel)
library(finetune)
library(tune)
library(dials)

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
library(titanic)
data_train <- titanic_train %>%
    mutate(outcome = factor(ifelse(Survived == 1, "yes", "no")))
data_train$outcome <- relevel(data_train$outcome, ref = "yes")
data_train <- data_train %>%
    mutate(class = ifelse(Pclass == 1, 1, 0),
           male = ifelse(Sex == "male", 1, 0),
           fare = ifelse(Fare > 20, 1, 0),
           embarked = ifelse(Embarked == "S", 1, 0)) %>%
    dplyr::select(outcome, class, male, fare, embarked)

data_folds <- vfold_cv(data_train, strata = outcome, v = 10, repeats = 10)

sel_outcome <- "general_crime"
cores <- 12 
tune_length <- 20L

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
