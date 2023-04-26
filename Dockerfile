# Set the base image to Ubuntu 20.04
FROM ubuntu:20.04

# Set environment variables
ENV R_VERSION=4.2.2
ENV NODE_VERSION=16

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        r-base=${R_VERSION}* \
        curl \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libjq-dev \
        jq \
        nodejs \
        npm \
        git \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install R dependencies
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org')"

# Install Node.js
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs

# Create app directory
RUN mkdir /app
WORKDIR /app

# Copy the application code
COPY . /app

# Extract the R version from the lockfile
RUN printf 'R_VERSION=%s\n' "$(jq --raw-output .R.Version renv.lock)" >> $GITHUB_ENV

# Sync renv with the lockfile
RUN Rscript -e "options(renv.config.cache.symlinks = FALSE); renv::restore(clean = TRUE)"

# Install Shiny package
RUN R -e "install.packages('shiny', repos = 'https://cloud.r-project.org')"

# Lint R
RUN Rscript -e "rhino::lint_r()"

# Lint JavaScript
RUN Rscript -e "rhino::lint_js()"

# Lint Sass
RUN Rscript -e "rhino::lint_sass()"

# Build JavaScript
RUN Rscript -e "rhino::build_js()"

# Build Sass
RUN Rscript -e "rhino::build_sass()"

# Run R unit tests
RUN Rscript -e "rhino::test_r()"

# Start the R Shiny app
CMD ["R", "-e", "shiny::runApp('/app/app.R', host = '0.0.0.0', port = 3838)"]
