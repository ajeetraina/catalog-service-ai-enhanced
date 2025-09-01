#!/bin/bash
# Correct PII Detection Test using proper MCP response format

echo "🔍 Testing PII Detection with Proper MCP Response Format:"
echo ""

# Test 1: MCP response with PII content
echo "Test 1: Customer data with email, phone, and sensitive info"
curl -X POST http://localhost:8081/log \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "customer-lookup-1",
    "result": {
      "content": [
        {
          "type": "text",
          "text": "Customer Details:\nName: John Smith\nEmail: john.smith@company.com\nPhone: (555) 123-4567\nSSN: 123-45-6789\nAPI Key: sk-abc123def456ghi789\nPassword: mySecretPass123"
        }
      ],
      "toolName": "customer_lookup"
    },
    "meta": {
      "sessionId": "pii-test-session-1"
    }
  }'

echo -e "\n\nTest 2: Multiple sensitive data types"
curl -X POST http://localhost:8081/log \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0", 
    "id": "sensitive-data-2",
    "result": {
      "content": [
        {
          "type": "text",
          "text": "User Profile Update:\nEmail changed to: jane.doe@example.com\nNew phone: 555-987-6543\nAPI token updated: bearer_abc123xyz789\nTemporary password: TempPass456!"
        },
        {
          "type": "text", 
          "text": "Additional info: Credit card ending in 4532, expires 12/26"
        }
      ],
      "toolName": "profile_update"
    },
    "meta": {
      "sessionId": "pii-test-session-2"
    }
  }'

echo -e "\n\nTest 3: Clean response (should score 1.0)"
curl -X POST http://localhost:8081/log \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "clean-response-3", 
    "result": {
      "content": [
        {
          "type": "text",
          "text": "Product search completed successfully. Found 15 products matching your criteria. All products are in stock and available for immediate shipping."
        }
      ],
      "toolName": "product_search"
    },
    "meta": {
      "sessionId": "clean-test-session"
    }
  }'

echo -e "\n\nTest 4: Error response with sensitive info"
curl -X POST http://localhost:8081/log \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": "error-response-4",
    "error": {
      "code": -32000,
      "message": "Database connection failed",
      "data": {
        "connection_string": "postgresql://user:password123@db.internal.com:5432/proddb",
        "api_key": "sk-prod-abc123def456"
      }
    },
    "meta": {
      "sessionId": "error-test-session"
    }
  }'

echo -e "\n\n📊 Checking audit interceptor logs:"
echo "Recent audit activity:"
docker logs catalog-audit-interceptor --tail=10 2>/dev/null | grep "AUDIT LOG" | tail -5

echo -e "\n🔍 Let's also create the audit database table for proper storage:"
echo "Creating audit_logs table in PostgreSQL..."

docker exec -it catalog-postgres psql -U postgres -d catalog_db -c "
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    session_id VARCHAR(255),
    tool_name VARCHAR(100),
    is_error BOOLEAN DEFAULT FALSE,
    sensitive_count INTEGER DEFAULT 0,
    compliance_score DECIMAL(3,2),
    sensitive_types TEXT[],
    response_id VARCHAR(255),
    content_length INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
" 2>/dev/null && echo "✅ Audit table created successfully!" || echo "⚠️  Table may already exist or need manual creation"

echo -e "\n🎯 PII Detection Test Complete!"
echo "Check the responses above - you should see:"
echo "• Test 1 & 2: pii_detected: true, high sensitive_count"
echo "• Test 3: pii_detected: false, compliance_score: 1.0"
echo "• Test 4: Error handling with sensitive data detection"
