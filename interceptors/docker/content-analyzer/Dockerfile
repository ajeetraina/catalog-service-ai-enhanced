FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY analyzer.py .

# Non-root user for security
RUN useradd -m -u 1000 analyzer && \
    chown -R analyzer:analyzer /app
USER analyzer

ENTRYPOINT ["python", "analyzer.py"]
