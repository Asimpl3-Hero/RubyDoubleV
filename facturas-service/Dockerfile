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

# Create necessary directories
RUN mkdir -p /app/public /app/db

# If build context is repo root (Dokploy), copy service files explicitly
# This handles the case where COPY . . copies the entire repo
RUN if [ -d "/app/facturas-service" ]; then \
      cp -r /app/facturas-service/* /app/ && \
      rm -rf /app/facturas-service /app/clientes-service /app/auditoria-service; \
    fi

# Verify openapi.yaml exists
RUN ls -la /app/public/openapi.yaml || echo "WARNING: openapi.yaml not found!"

# Expose port
EXPOSE 4002

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4002", "-e", "development"]
