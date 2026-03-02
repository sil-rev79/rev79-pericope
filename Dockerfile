FROM ruby:3.4.1-slim

# Install build dependencies for gems with native extensions
RUN apt-get update -qq && apt-get install -y build-essential git

WORKDIR /app

# Copy dependency files first for better caching
COPY Gemfile rev79-pericope.gemspec ./
COPY lib/pericope/version.rb ./lib/pericope/version.rb

# Copy the rest of the application
COPY . .

RUN bundle install

# Default command to run tests
CMD ["bundle", "exec", "rspec"]
