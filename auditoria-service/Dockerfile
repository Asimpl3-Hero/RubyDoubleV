FROM ruby:3.2-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock (if exists) and install gems
COPY Gemfile Gemfile.lock* ./
RUN bundle install

# Copy application code
COPY . .

# Expose port
EXPOSE 4003

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4003", "-e", "development"]
