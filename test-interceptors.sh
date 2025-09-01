#!/bin/bash
# Basic interceptor testing script

echo "🧪 Testing MCP Interceptors..."

# Check if services are running
echo "📊 Checking service health..."

services=(
    "http://localhost:8080/health"  # Security interceptor
    "http://localhost:8081/health"  # Audit interceptor
    "http://localhost:8811/health"  # MCP Gateway
    "http://localhost:3001/health"  # Agent service
)

for service in "${services[@]}"; do
    echo -n "Testing $service... "
    if curl -s -f "$service" > /dev/null; then
        echo "✅ OK"
    else
        echo "❌ FAILED"
    fi
done

# Test basic agent functionality
echo "🤖 Testing agent with interceptors..."

test_query='{
    "agent_name": "test-agent",
    "message": "Test basic interceptor functionality",
    "tools": ["brave_web_search"]
}'

response=$(curl -s -X POST http://localhost:3001/agent/analyze \
    -H "Content-Type: application/json" \
    -d "$test_query")

if echo "$response" | jq . > /dev/null 2>&1; then
    echo "✅ Agent request successful"
    echo "📊 Response received"
else
    echo "❌ Agent request failed"
    echo "$response"
fi

echo "🎉 Basic interceptor testing complete!"
