#!/bin/bash

echo "🔧 Fixing Kafka Configuration"
echo "=============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Stop and remove existing Kafka container
echo "🛑 Stopping Kafka..."
docker compose stop kafka
docker compose rm -f kafka

# 2. Remove Kafka volume to start fresh
echo "🧹 Cleaning Kafka data..."
docker volume rm catalog-service-ai-enhanced_kafka_data 2>/dev/null || true

# 3. Create updated docker-compose.yml with correct Kafka configuration
echo "📝 Creating fixed Kafka configuration..."

cat > docker-compose.kafka.yml << 'EOF'
services:
  kafka:
    image: apache/kafka:latest
    container_name: catalog-kafka
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      # KRaft Configuration
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: 'broker,controller'
      KAFKA_LISTENERS: 'PLAINTEXT://0.0.0.0:29092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:9092'
      KAFKA_ADVERTISED_LISTENERS: 'PLAINTEXT://kafka:29092,EXTERNAL://localhost:9092'
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: 'CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT'
      KAFKA_CONTROLLER_LISTENER_NAMES: 'CONTROLLER'
      KAFKA_CONTROLLER_QUORUM_VOTERS: '1@kafka:9093'
      KAFKA_INTER_BROKER_LISTENER_NAME: 'PLAINTEXT'
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      KAFKA_LOG_DIRS: '/tmp/kafka-logs'
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: 'true'
      CLUSTER_ID: 'MkU3OEVBNTcwNTJENDM2Qk'
    volumes:
      - kafka_data:/tmp/kafka-logs
    networks:
      - catalog-network
    healthcheck:
      test: ["CMD-SHELL", "/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092 || exit 1"]
      interval: 10s
      timeout: 10s
      retries: 10
      start_period: 40s
EOF

# 4. Update main docker-compose.yml to use correct Kafka paths
echo "📝 Updating main docker-compose.yml..."

# Check if docker-compose.yml exists
if [ -f docker-compose.yml ]; then
    # Backup current file
    cp docker-compose.yml docker-compose.backup.yml
    
    # Update Kafka service with correct paths
    python3 - << 'PYTHON_SCRIPT' || {
import yaml
import sys

try:
    with open('docker-compose.yml', 'r') as f:
        compose = yaml.safe_load(f)
    
    # Update Kafka service if it exists
    if 'services' in compose and 'kafka' in compose['services']:
        kafka = compose['services']['kafka']
        
        # Update healthcheck to use correct path
        if 'healthcheck' not in kafka:
            kafka['healthcheck'] = {}
        
        kafka['healthcheck']['test'] = [
            "CMD-SHELL", 
            "/opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092 || exit 1"
        ]
        kafka['healthcheck']['interval'] = "10s"
        kafka['healthcheck']['timeout'] = "10s"
        kafka['healthcheck']['retries'] = 10
        kafka['healthcheck']['start_period'] = "40s"
    
    # Write back
    with open('docker-compose.yml', 'w') as f:
        yaml.dump(compose, f, default_flow_style=False, sort_keys=False)
    
    print("✅ Updated docker-compose.yml")
except Exception as e:
    print(f"⚠️  Could not update with Python, using sed: {e}")
    sys.exit(1)
PYTHON_SCRIPT
        echo "Using sed to update Kafka paths..."
        # Fallback to sed if Python fails
        sed -i.bak 's|kafka-topics\.sh|/opt/kafka/bin/kafka-topics.sh|g' docker-compose.yml
        sed -i.bak 's|kafka-broker-api-versions\.sh|/opt/kafka/bin/kafka-broker-api-versions.sh|g' docker-compose.yml
    }
fi

# 5. Start Kafka
echo ""
echo "🚀 Starting Kafka..."
docker compose up -d kafka

# 6. Wait for Kafka to be ready
echo ""
echo "⏳ Waiting for Kafka to be ready (this may take 40 seconds)..."

MAX_ATTEMPTS=20
ATTEMPT=1

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    echo -n "  Attempt $ATTEMPT/$MAX_ATTEMPTS: "
    
    if docker exec catalog-kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092 &>/dev/null; then
        echo -e "${GREEN}✓ Kafka is ready!${NC}"
        break
    else
        echo "Waiting..."
        sleep 3
    fi
    
    ATTEMPT=$((ATTEMPT + 1))
done

if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
    echo -e "${RED}❌ Kafka failed to start${NC}"
    echo "Checking Kafka logs..."
    docker compose logs --tail=50 kafka
    exit 1
fi

# 7. Create Kafka topics
echo ""
echo "📝 Creating Kafka topics..."

create_topic() {
    local TOPIC=$1
    echo -n "  Creating topic '$TOPIC'... "
    
    if docker exec catalog-kafka /opt/kafka/bin/kafka-topics.sh \
        --create \
        --topic $TOPIC \
        --bootstrap-server localhost:29092 \
        --partitions 3 \
        --replication-factor 1 \
        2>/dev/null; then
        echo -e "${GREEN}✓${NC}"
    else
        # Topic might already exist
        if docker exec catalog-kafka /opt/kafka/bin/kafka-topics.sh \
            --list \
            --bootstrap-server localhost:29092 2>/dev/null | grep -q "^$TOPIC$"; then
            echo -e "${YELLOW}Already exists${NC}"
        else
            echo -e "${RED}Failed${NC}"
        fi
    fi
}

create_topic "product-submissions"
create_topic "product-updates"
create_topic "inventory-changes"
create_topic "agent-evaluations"

# 8. List all topics
echo ""
echo "📋 Kafka topics:"
docker exec catalog-kafka /opt/kafka/bin/kafka-topics.sh \
    --list \
    --bootstrap-server localhost:29092 2>/dev/null | while read topic; do
    echo "  • $topic"
done

# 9. Test Kafka with a message
echo ""
echo "🧪 Testing Kafka messaging..."

# Create a test message
echo "test-message-$(date +%s)" | docker exec -i catalog-kafka \
    /opt/kafka/bin/kafka-console-producer.sh \
    --broker-list localhost:29092 \
    --topic product-updates \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Kafka messaging test successful${NC}"
else
    echo -e "${RED}❌ Kafka messaging test failed${NC}"
fi

# 10. Final health check
echo ""
echo "🔍 Final Health Check:"
echo "====================="

# PostgreSQL
if docker exec catalog-postgres pg_isready -U postgres &>/dev/null; then
    echo -e "${GREEN}✅ PostgreSQL: Healthy${NC}"
else
    echo -e "${RED}❌ PostgreSQL: Not responding${NC}"
fi

# Kafka
if docker exec catalog-kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092 &>/dev/null; then
    echo -e "${GREEN}✅ Kafka: Healthy${NC}"
else
    echo -e "${RED}❌ Kafka: Not responding${NC}"
fi

# MongoDB
if docker exec catalog-mongodb mongosh --eval 'db.adminCommand("ping")' --quiet &>/dev/null 2>&1; then
    echo -e "${GREEN}✅ MongoDB: Healthy${NC}"
else
    echo -e "${RED}❌ MongoDB: Not responding${NC}"
fi

# Model Runner (on host)
if curl -s http://localhost:12434/models &>/dev/null; then
    echo -e "${GREEN}✅ Model Runner: Healthy (host)${NC}"
else
    echo -e "${YELLOW}ℹ️  Model Runner: Not detected (enable in Docker Desktop)${NC}"
fi

# MCP Gateway
if curl -s http://localhost:8811/health &>/dev/null; then
    echo -e "${GREEN}✅ MCP Gateway: Healthy${NC}"
else
    echo -e "${YELLOW}⚠️  MCP Gateway: Not responding${NC}"
fi

# Agent Service
if curl -s http://localhost:7777/health &>/dev/null; then
    echo -e "${GREEN}✅ Agent Service: Healthy${NC}"
else
    echo -e "${YELLOW}⚠️  Agent Service: Not responding${NC}"
fi

echo ""
echo "✅ Kafka setup complete!"
echo ""
echo "📊 Service URLs:"
echo "  • Frontend: http://localhost:5173"
echo "  • Agent Portal: http://localhost:3001"
echo "  • API: http://localhost:3000"
echo "  • Agent Service: http://localhost:7777"
echo "  • pgAdmin: http://localhost:5050"
echo "  • Kafka UI: http://localhost:8080"
echo ""
echo "🧪 Test the complete stack:"
echo '  curl -X POST http://localhost:7777/products/evaluate \'
echo '    -H "Content-Type: application/json" \'
echo '    -d '"'"'{"productName": "Test Product", "price": 99.99}'"'"
