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
COPY config/ ./config/ || true

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
