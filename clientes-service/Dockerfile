FROM ruby:3.2-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libsqlite3-dev \
    sqlite3 \
    pkg-config \
    libssl-dev \
    libyaml-dev \
    git && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock* ./

# Install bundler and gems
RUN gem install bundler -v '~> 2.4' && \
    bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create database directory
RUN mkdir -p db

# Expose port
EXPOSE 4001

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4001", "-e", "development"]
