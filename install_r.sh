#!/bin/sh
# import proper key 
#sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key 'E298A3A825C0D65DFD57CBB651716619E084DAB9'

# add repository
#echo "deb http://cloud.r-project.org/bin/linux/debian bullseye-cran40/" | sudo tee -a /etc/apt/sources.list
 
# install r and some dependencies
sudo apt update && sudo apt install -y r-base libv8-dev libxml2-dev lubcurl4-openssl-dev libopenblas-dev
