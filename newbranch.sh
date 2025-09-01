#!/bin/bash

# Setup script for MCP Interceptors - Based on existing catalog-service setup
set -euo pipefail

echo "🚀 Setting up MCP Interceptors for your existing Catalog Service..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if we're in the right directory
check_directory() {
    echo "🔍 Checking project structure..."
    
    if [ ! -f "docker-compose.yml" ]; then
        print_error "docker-compose.yml not found. Please run this from your project root."
        exit 1
    fi
    
    if [ ! -d "agent-service" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
        print_error "Missing expected directories. Please run this from your catalog-service-ai-enhanced root."
        exit 1
    fi
    
    print_status "Project structure validated"
}

# Create interceptor directories and files
create_interceptor_structure() {
    echo "📁 Creating interceptor structure..."
    
    # Create directories
    mkdir -p interceptors/scripts
    mkdir -p interceptors/http/security-service
    mkdir -p interceptors/http/audit-service
    mkdir -p interceptors/docker/content-analyzer
    mkdir -p monitoring/grafana/dashboards
    mkdir -p monitoring/grafana/datasources
    
    # Create environment file
    if [ ! -f ".mcp.env.interceptors" ]; then
        print_warning "Creating .mcp.env.interceptors..."
        cat > .mcp.env.interceptors << 'EOF'
# MCP Gateway Configuration
RUST_LOG=info
MCP_GATEWAY_PORT=8811
MCP_GATEWAY_HOST=0.0.0.0

# Security Interceptor Configuration
SECURITY_MODE=strict
MAX_QUERY_LENGTH=500
RATE_LIMIT_RPM=60
BLOCKED_PATTERNS=password,secret,token,api_key
THREAT_INTEL_ENABLED=false

# Audit Interceptor Configuration
AUDIT_MODE=full
COMPLIANCE_RULES=pii_detection,sensitive_data

# Content Analyzer Configuration
ANALYSIS_MODEL=sentiment,quality
CONFIDENCE_THRESHOLD=0.8
OUTPUT_FORMAT=json

# Monitoring Configuration
LOG_LEVEL=info
EOF
    fi
    
    print_status "Interceptor structure created"
}

# Check if interceptor services exist
check_interceptor_services() {
    echo "🔍 Checking interceptor service implementations..."
    
    if [ ! -f "interceptors/http/security-service/Dockerfile" ]; then
        print_error "Security service implementation missing"
        echo "Please ensure the interceptors/ directory from your feature branch is present"
        exit 1
    fi
    
    if [ ! -f "interceptors/http/audit-service/Dockerfile" ]; then
        print_error "Audit service implementation missing"
        echo "Please ensure the interceptors/ directory from your feature branch is present"
        exit 1
    fi
    
    if [ ! -f "interceptors/docker/content-analyzer/Dockerfile" ]; then
        print_error "Content analyzer implementation missing"
        echo "Please ensure the interceptors/ directory from your feature branch is present"
        exit 1
    fi
    
    print_status "Interceptor services found"
}

# Set permissions for scripts
set_script_permissions() {
    echo "🔐 Setting script permissions..."
    
    if [ -d "interceptors/scripts" ]; then
        find interceptors/scripts -name "*.sh" -exec chmod +x {} \;
        print_status "Script permissions set"
    else
        print_warning "No scripts directory found"
    fi
}

# Create monitoring configuration
create_monitoring_config() {
    echo "📊 Creating monitoring configuration..."
    
    # Prometheus config
    cat > monitoring/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'mcp-gateway'
    static_configs:
      - targets: ['mcp-gateway:8811']
    metrics_path: /metrics
    scrape_interval: 10s

  - job_name: 'security-interceptor'
    static_configs:
      - targets: ['security-interceptor:8080']
    metrics_path: /metrics

  - job_name: 'audit-interceptor'
    static_configs:
      - targets: ['audit-interceptor:8080']
    metrics_path: /metrics

  - job_name: 'agent-service'
    static_configs:
      - targets: ['agent-service:7777']
    metrics_path: /metrics

  - job_name: 'backend'
    static_configs:
      - targets: ['backend:3000']
    metrics_path: /metrics
EOF

    # Grafana datasource
    cat > monitoring/grafana/datasources/datasource.yml << 'EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
EOF

    # Grafana dashboard provisioning
    cat > monitoring/grafana/dashboards/dashboard.yml << 'EOF'
apiVersion: 1
providers:
  - name: 'catalog-dashboards'
    orgId: 1
    folder: 'Catalog Service'
    type: file
    disableDeletion: false
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    print_status "Monitoring configuration created"
}

# Build interceptor images
build_interceptors() {
    echo "🔨 Building interceptor services..."
    
    echo "Building security interceptor..."
    docker build -t catalog-security-interceptor interceptors/http/security-service/ || {
        print_error "Failed to build security interceptor"
        exit 1
    }
    
    echo "Building audit interceptor..."
    docker build -t catalog-audit-interceptor interceptors/http/audit-service/ || {
        print_error "Failed to build audit interceptor"
        exit 1
    }
    
    echo "Building content analyzer..."
    docker build -t catalog-content-analyzer interceptors/docker/content-analyzer/ || {
        print_error "Failed to build content analyzer"
        exit 1
    }
    
    print_status "All interceptor services built successfully"
}

# Validate the compose file
validate_compose() {
    echo "🔍 Validating Docker Compose configuration..."
    
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        print_error "Docker Compose not found"
        exit 1
    fi
    
    if $COMPOSE_CMD -f docker-compose.interceptors.yml config > /dev/null 2>&1; then
        print_status "Docker Compose configuration is valid"
    else
        print_error "Docker Compose configuration is invalid"
        echo "Run: $COMPOSE_CMD -f docker-compose.interceptors.yml config"
        exit 1
    fi
}

# Main execution
main() {
    echo "=================================================="
    echo "🛡️ MCP Interceptors Setup"
    echo "Based on your existing catalog-service-ai-enhanced"
    echo "=================================================="
    
    check_directory
    check_interceptor_services
    create_interceptor_structure
    set_script_permissions
    create_monitoring_config
    build_interceptors
    validate_compose
    
    echo ""
    echo "=================================================="
    print_status "Setup completed successfully!"
    echo "=================================================="
    echo ""
    echo "Your existing services are preserved with these enhancements:"
    echo "✅ Security interceptor added"
    echo "✅ Audit interceptor added"
    echo "✅ Content analysis interceptor added"
    echo "✅ Monitoring (Prometheus + Grafana) added"
    echo ""
    echo "Next steps:"
    echo "1. Review .mcp.env.interceptors configuration"
    echo "2. Start with interceptors: docker compose -f docker-compose.interceptors.yml up -d"
    echo "3. Or start original: docker compose up -d"
    echo ""
    echo "Service URLs with interceptors:"
    echo "• Frontend: http://localhost:5173"
    echo "• Agent Portal: http://localhost:3001"
    echo "• Backend API: http://localhost:3000"
    echo "• Agent Service: http://localhost:7777"
    echo "• MCP Gateway: http://localhost:8811"
    echo "• Security Interceptor: http://localhost:8080"
    echo "• Audit Interceptor: http://localhost:8081"
    echo "• Kafka UI: http://localhost:8082"
    echo "• WireMock: http://localhost:8083"
    echo "• Grafana: http://localhost:3002"
    echo "• Prometheus: http://localhost:9090"
    echo "• pgAdmin: http://localhost:5050"
    echo ""
    echo "Port conflicts resolved:"
    echo "• Kafka UI moved to 8082 (was 8080)"
    echo "• WireMock moved to 8083 (was 8081)"
    echo ""
}

# Run main function
main "$@"
