#!/bin/bash

# Quick fix for broken Dockerfiles
echo "🔧 Fixing Dockerfile syntax issues..."

# Fix security service Dockerfile
cat > interceptors/http/security-service/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create log directory
RUN mkdir -p /var/log/mcp

# Non-root user for security
RUN useradd -m -u 1000 interceptor && \
    chown -R interceptor:interceptor /app /var/log/mcp
USER interceptor

# Health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["python", "app.py"]
EOF

# Fix audit service Dockerfile
cat > interceptors/http/audit-service/Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Create log directory
RUN mkdir -p /var/log/mcp

# Non-root user for security
RUN useradd -m -u 1000 auditor && \
    chown -R auditor:auditor /app /var/log/mcp
USER auditor

# Health check
HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

EXPOSE 8080

CMD ["python", "app.py"]
EOF

echo "✅ Dockerfiles fixed!"
echo "You can now run the setup script again or build manually:"
echo "  docker build -t catalog-security-interceptor interceptors/http/security-service/"
echo "  docker build -t catalog-audit-interceptor interceptors/http/audit-service/"
