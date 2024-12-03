# Developers note pad

* Carton is used for this project, to lock dependancies and versions
* DZIL was used to create it as a distribution
* main.pl is the primary run script

## Dockerfile's

To help speed up the process of creating images, each stage is split away
from one another in controlled steps. Meaning in most cases for development
you will only need to do the entire build once, after that simply do the last
step 'release'.

The order from the start:

* docker build -f Dockerfile.base -t mojocore:base .
* docker build -f Dockerfile.tweaks -t mojocore:tweaks .
* docker build -f Dockerfile.release -t mojocore:release .