FROM perl:5.40.0 AS mojocore_base

# Set working directory
WORKDIR /build

# Copy required application deps
COPY mojo-core/vendor /build/vendor
COPY mojo-core/cpanfile /build

# Install the required packages (csharp)
RUN  apt-get install -y apt-transport-https \
    && wget https://packages.microsoft.com/config/debian/10/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update -y \
    && apt-get install -y dotnet-sdk-6.0

RUN apt-get install -y wget apt-transport-https \
    && wget https://packages.microsoft.com/config/debian/11/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get install -y dotnet-sdk-6.0 \
    && rm -f packages-microsoft-prod.deb

# Install the required packages (python)
RUN apt update -y \
    && apt install -y \
        build-essential \
        sqlite3 \
        libexpat1-dev \
        libxml2 \
        libxml2-dev \
        libxml-simple-perl \
        python3-full \
        python3-requests \
        python3-boto3 \
        python3-venv \
        nano

# Create a symlink for python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Install the required packages (perl)
RUN cpanm --from "$PWD/vendor/cache" --installdeps --notest --quiet .

# Install the MinIO client
COPY mojo-core/tools/install-minio.sh /tmp/install-minio.sh
RUN chmod +x /tmp/install-minio.sh && /tmp/install-minio.sh

# Add a user to run the application
RUN useradd -m -d /app worker && useradd -m -d /service service
RUN chown worker:worker /app && chown service:service /service

# Clean up the image
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /app/* \
    && rm -rf /build/* \
    && rm -Rf /tmp/*

# Flatten the image
FROM scratch AS flatten

COPY --from=mojocore_base / /

# Set a generic command
RUN echo "Base built, now use the Dockerfile's in the components directory."
CMD ["/bin/bash"]