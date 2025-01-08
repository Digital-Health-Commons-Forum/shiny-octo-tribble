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

First the base:

```bash
    cd repo-base/components && docker build -t mojocore:base .
```

Then whichever component you which to build (lets say core):

```bash
    cd repo-base/components/mojo-core && docker build -t mojocore:core-dev .
```

Or perhaps you wish to build worker-minio:

```bash
    cd repo-base/components/worker-minio && docker build -t mojocore:minio-dev .
```

Then if you wish to build a release:

```bash
    cd repo-base/components/mojo-core && docker build -f Dockerfile.release -t mojocore:release .
```
