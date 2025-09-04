#!/bin/bash

# Performance testing tool for catalog service

BASE_URL="http://localhost:3000"
NUM_REQUESTS=${1:-10}
CONCURRENT_REQUESTS=${2:-5}

echo "🚀 Performance testing catalog service"
echo "📊 Requests: $NUM_REQUESTS, Concurrent: $CONCURRENT_REQUESTS"

# Test payload
TEST_PAYLOAD='{
  "vendorName": "Performance Test Vendor",
  "productName": "Load Test Product",
  "description": "A product used for performance testing of the cagent-powered evaluation system.",
  "price": 99.99,
  "category": "Electronics"
}'

# Create temporary file for results
RESULTS_FILE="/tmp/catalog_perf_results.txt"
: > "$RESULTS_FILE"

# Function to make single request
make_request() {
    local i=$1
    echo "Request $i starting..." >&2
    
    start_time=$(date +%s%N)
    
    response=$(curl -s -w "%{http_code},%{time_total}" \
      -X POST "$BASE_URL/api/products/evaluate" \
      -H "Content-Type: application/json" \
      -d "$TEST_PAYLOAD")
    
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))  # Convert to ms
    
    http_code=$(echo "$response" | tail -c 10 | cut -d',' -f1)
    curl_time=$(echo "$response" | tail -c 10 | cut -d',' -f2)
    
    echo "$i,$http_code,$duration,$curl_time" >> "$RESULTS_FILE"
    echo "Request $i completed: $http_code ($duration ms)" >&2
}

# Run requests in parallel
echo "🔄 Starting performance test..."
for i in $(seq 1 $NUM_REQUESTS); do
    if [ $((i % CONCURRENT_REQUESTS)) -eq 0 ] || [ $i -eq $NUM_REQUESTS ]; then
        make_request $i &
        wait  # Wait for batch to complete
    else
        make_request $i &
    fi
done

# Wait for all background jobs
wait

# Analyze results
echo "📈 Analyzing results..."

total_requests=$(wc -l < "$RESULTS_FILE")
successful_requests=$(awk -F, '$2 == 200 {count++} END {print count+0}' "$RESULTS_FILE")
avg_response_time=$(awk -F, '{sum += $3; count++} END {print sum/count}' "$RESULTS_FILE")
min_response_time=$(awk -F, '{print $3}' "$RESULTS_FILE" | sort -n | head -1)
max_response_time=$(awk -F, '{print $3}' "$RESULTS_FILE" | sort -n | tail -1)

success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc)

echo ""
echo "📊 Performance Test Results:"
echo "=============================="
echo "Total Requests: $total_requests"
echo "Successful Requests: $successful_requests"
echo "Success Rate: $success_rate%"
echo "Average Response Time: ${avg_response_time}ms"
echo "Min Response Time: ${min_response_time}ms"
echo "Max Response Time: ${max_response_time}ms"
echo ""

if [ "$successful_requests" -gt 0 ]; then
    echo "✅ Performance test completed successfully!"
else
    echo "❌ Performance test failed - no successful requests!"
    exit 1
fi

# Cleanup
rm -f "$RESULTS_FILE"
