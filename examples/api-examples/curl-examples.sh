#!/bin/bash

# API Examples for catalog-service-cagent

BASE_URL="http://localhost:3000"

echo "🤖 Testing cagent-powered catalog service API"

# 1. Health check
echo "1. Health check..."
curl -s "$BASE_URL/health" | jq .

# 2. Agent health
echo -e "\n2. Agent health check..."
curl -s "$BASE_URL/api/agents/health" | jq .

# 3. Submit product for evaluation
echo -e "\n3. Submit product for cagent evaluation..."
curl -s -X POST "$BASE_URL/api/products/evaluate" \
  -H "Content-Type: application/json" \
  -d '{
    "vendorName": "Test Vendor",
    "productName": "AI-Powered Widget",
    "description": "An innovative AI-powered widget that revolutionizes widget technology with machine learning capabilities and smart automation.",
    "price": 149.99,
    "category": "Electronics"
  }' | jq .

# 4. Get products
echo -e "\n4. Get catalog products..."
curl -s "$BASE_URL/api/products?limit=5" | jq .

# 5. Get statistics
echo -e "\n5. Get catalog statistics..."
curl -s "$BASE_URL/api/products/stats/summary" | jq .

echo -e "\n✅ API tests completed!"
