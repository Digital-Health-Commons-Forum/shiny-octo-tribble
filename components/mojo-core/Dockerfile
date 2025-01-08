FROM mojocore:mojobase-dev

# Make a working directory
RUN mkdir /install

# Copy the Mojo-Core-* files
COPY Mojo-Core-* /install/

# Set the working directory
WORKDIR /install

# Install the application (latest version)
RUN cpanm $(ls Mojo-Core-*.tar.gz | sort -V | tail -n 1)

# Switch to the worker user
USER worker

# Set the working directory
WORKDIR /worker

# Copy the application files
COPY ./main.pl /worker/main.pl

# Add in the schema
COPY schema.json /worker/schema.json

# Remove the old install directory
USER root
RUN rm -rf /install

# And back to worker
USER worker

# Run the application
CMD ["perl", "main.pl", "daemon"]