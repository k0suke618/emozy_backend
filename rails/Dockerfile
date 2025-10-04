# syntax=docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.9
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /rails

# Install all packages needed for BOTH running the app AND building gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    # Packages for building gems
    build-essential git pkg-config libpq-dev libyaml-dev \
    # Packages for running the app
    curl libjemalloc2 libvips postgresql-client imagemagick && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Configure Bundler
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
    PATH="/usr/local/bundle/bin:/rails/bin:${PATH}"

# Copy dependency files
COPY Gemfile Gemfile.lock ./

# Install gems
# This command will be run during the build process
RUN bundle install

# Copy the rest of the application code
COPY . .

# Expose port 3000 to the host
EXPOSE 3333

# The main command to run when the container starts
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
