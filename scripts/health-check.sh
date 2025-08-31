#!/bin/bash

echo "🔍 Checking service health..."

# Check PostgreSQL
if docker exec catalog-postgres pg_isready &> /dev/null; then
    echo "✅ PostgreSQL is healthy"
else
    echo "❌ PostgreSQL is not responding"
fi

# Check Kafka
if docker exec catalog-kafka kafka-broker-api-versions.sh --bootstrap-server localhost:9092 &> /dev/null; then
    echo "✅ Kafka is healthy"
else
    echo "❌ Kafka is not responding"
fi

# Check Model Runner
if curl -s http://localhost:12434/models &> /dev/null; then
    echo "✅ Model Runner is healthy"
else
    echo "❌ Model Runner is not responding"
fi

# Check MCP Gateway
if curl -s http://localhost:8811/health &> /dev/null; then
    echo "✅ MCP Gateway is healthy"
else
    echo "❌ MCP Gateway is not responding"
fi
