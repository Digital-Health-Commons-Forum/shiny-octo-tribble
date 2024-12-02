FROM perl:5.40.0-slim AS builder

# Set working directory
WORKDIR /app

# Copy application files
COPY * /app

# Remove unrequired things
RUN rm -rf cpanfile.snapshot Dockerfile README.md

# cpanfile  cpanfile.snapshot  Dockerfile  lib  local  main.perl  README.md  schema.yml  vendor
