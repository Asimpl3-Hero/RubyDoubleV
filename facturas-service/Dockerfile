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

# Copy Gemfile and Gemfile.lock (from repo root when using docker-compose)
COPY facturas-service/Gemfile facturas-service/Gemfile.lock* ./

# Install bundler and gems
RUN gem install bundler -v '~> 2.4' && \
    bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy entire repo (build context is repo root)
COPY . .

# If build context is repo root (Dokploy/docker-compose), reorganize files
# This handles the case where COPY . . copies the entire repo
RUN if [ -d "/app/facturas-service" ]; then \
      # Backup shared directory from repo root
      cp -r /app/shared /tmp/shared_backup && \
      # Copy all files from service directory to /app/ (including hidden files)
      cp -a /app/facturas-service/. /app/ && \
      # Remove service directories
      rm -rf /app/facturas-service /app/clientes-service /app/auditoria-service && \
      # Restore shared directory from backup
      rm -rf /app/shared && \
      mv /tmp/shared_backup /app/shared; \
    fi

# Create db directory if it doesn't exist
RUN mkdir -p /app/db

# Verify critical files exist
RUN ls -la /app/shared/ || echo "ERROR: shared directory not found!" && \
    ls -la /app/public/openapi.yaml || echo "ERROR: openapi.yaml not found!" && \
    echo "✓ Directory structure verified"

# Expose port
EXPOSE 4002

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4002", "-e", "development"]
