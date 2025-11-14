FROM ruby:3.2-slim

# Install system dependencies required for building gems
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
    libyaml-dev \
    git \
    curl && \
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

# Expose port
EXPOSE 4003

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4003", "-e", "development"]
