#!/bin/sh

# import proper key and add R repository
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E298A3A825C0D65DFD57CBB651716619E084DAB9'
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# install R and some necessary dependencies
sudo apt update && sudo apt install -y r-base libnode-dev libxml2-dev libcurl4-openssl-dev libopenblas-dev

# install required R packages
R --slave -e 'dir.create(path = Sys.getenv("R_LIBS_USER"), showWarnings = FALSE, recursive = TRUE)'
R --slave -e 'install.packages(c("tidyverse", "doParallel", "nnet", "kernlab", "ranger", "xgboost", "dbarts", "devtools"))'
R --slave -e 'devtools::install_github("tidymodels/tidymodels")'
R --slave -e 'devtools::install_github("tidymodels/tune")'
R --slave -e 'devtools::install_github("tidymodels/finetune")'
R --slave -e 'devtools::install_github("tidymodels/dials")'

# install TensorFlow and Keras
sudo apt install -y python3-dev python3-pip python3-venv
pip3 install tensorflow
R --slave -e 'install.packages(c("tensorflow", "keras"))'

# install torch and brulee
R --slave -e 'devtools::install_github("mlverse/torch")'
R --slave -e 'torch::install_torch()'
R --slave -e 'devtools::install_github("tidymodels/brulee")'
