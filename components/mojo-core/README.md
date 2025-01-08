# Developers note pad

* Carton is used for this project, to lock dependancies and versions
* DZIL was used to create it as a distribution
* main.pl is the primary run script

## Build the image

This assumes you have already built the base, if not read the readme.md in the 
components directory.

To build the core simply issue the following command:

```bash
docker build -t mojocore:mojocore-dev .
```
