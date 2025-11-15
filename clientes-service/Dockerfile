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
COPY clientes-service/Gemfile clientes-service/Gemfile.lock* ./

# Install bundler and gems
RUN gem install bundler -v '~> 2.4' && \
    bundle config set --local deployment 'false' && \
    bundle install --jobs 4 --retry 3

# Copy entire repo (build context is repo root)
COPY . .

# If build context is repo root (Dokploy/docker-compose), reorganize files
RUN if [ -d "/app/clientes-service" ]; then \
      # Backup shared directory from repo root
      cp -r /app/shared /tmp/shared_backup && \
      # Move service files to /app/ root
      mv /app/clientes-service/* /app/ 2>/dev/null || true && \
      mv /app/clientes-service/.??* /app/ 2>/dev/null || true && \
      # Remove service directories
      rm -rf /app/facturas-service /app/clientes-service /app/auditoria-service && \
      # Restore shared directory from backup
      rm -rf /app/shared && \
      mv /tmp/shared_backup /app/shared; \
    fi

# Create necessary directories if they don't exist (after moving service files)
RUN mkdir -p /app/db

# Verify shared directory exists
RUN ls -la /app/shared/ || echo "WARNING: shared directory not found!"

# Verify openapi.yaml exists
RUN ls -la /app/public/openapi.yaml || echo "WARNING: openapi.yaml not found!"

# Expose port
EXPOSE 4001

# Start the application
CMD ["bundle", "exec", "puma", "config.ru", "-p", "4001", "-e", "development"]
