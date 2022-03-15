#!/bin/sh
# import proper key 
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E298A3A825C0D65DFD57CBB651716619E084DAB9'

# add repository
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"

# install r and some dependencies
sudo apt update && sudo apt install -y r-base libnode-dev libxml2-dev libcurl4-openssl-dev libopenblas-dev

# install r packages
R --slave -e 'install.packages(c("tidyverse", "doParallel", "nnet", "kernlab", "ranger", "xgboost", "dbarts", "devtools"))'

# make sure we get latest versions of these
R --slave -e 'devtools::install_github("tidymodels/tidymodels")'
R --slave -e 'devtools::install_github("tidymodels/tune")'
R --slave -e 'devtools::install_github("tidymodels/finetune")'
R --slave -e 'devtools::install_github("tidymodels/dials")'
