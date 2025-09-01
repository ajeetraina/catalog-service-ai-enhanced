#!/bin/bash
set -euo pipefail

# Read the JSON tool call from stdin
TOOL_CALL_JSON=$(cat)

# Extract session ID and tool name
SESSION_ID=$(echo "$TOOL_CALL_JSON" | jq -r '.meta.sessionId // "anonymous"')
TOOL_NAME=$(echo "$TOOL_CALL_JSON" | jq -r '.params.name // "unknown"')
TIMESTAMP=$(date +%s)

# Rate limiting configuration
RATE_LIMIT_RPM=${RATE_LIMIT_RPM:-60}  # requests per minute
RATE_LIMIT_WINDOW=60  # 60 seconds

# Session tracking file
SESSION_DIR="/tmp/mcp-sessions"
mkdir -p "$SESSION_DIR"
SESSION_FILE="$SESSION_DIR/rate-limit-$SESSION_ID"

# Read current request count and timestamps
if [[ -f "$SESSION_FILE" ]]; then
    # Filter out old timestamps (outside the window)
    CUTOFF=$((TIMESTAMP - RATE_LIMIT_WINDOW))
    grep -v "^[0-9]*$" "$SESSION_FILE" | \
    awk -v cutoff="$CUTOFF" '$1 > cutoff' > "$SESSION_FILE.tmp" || true
    mv "$SESSION_FILE.tmp" "$SESSION_FILE" 2>/dev/null || true
fi

# Count current requests in window
CURRENT_COUNT=$(wc -l < "$SESSION_FILE" 2>/dev/null || echo 0)

# Check rate limit
if [[ $CURRENT_COUNT -ge $RATE_LIMIT_RPM ]]; then
    echo "⚠️  RATE LIMIT EXCEEDED: Session $SESSION_ID has $CURRENT_COUNT requests in last ${RATE_LIMIT_WINDOW}s (limit: $RATE_LIMIT_RPM)" >&2
    
    # Return error response
    cat <<EOFR
{
  "jsonrpc": "2.0",
  "id": $(echo "$TOOL_CALL_JSON" | jq -r '.id'),
  "error": {
    "code": 429,
    "message": "Rate limit exceeded. Maximum $RATE_LIMIT_RPM requests per minute.",
    "data": {
      "current_count": $CURRENT_COUNT,
      "limit": $RATE_LIMIT_RPM,
      "window_seconds": $RATE_LIMIT_WINDOW,
      "retry_after": 60
    }
  }
}
EOFR
    exit 1
fi

# Log the request
echo "$TIMESTAMP $TOOL_NAME $(echo "$TOOL_CALL_JSON" | jq -r '.params.arguments.query // "no-query"')" >> "$SESSION_FILE"

# Log to stderr for gateway logs
echo "✅ RATE LIMIT OK: Session $SESSION_ID - Request $((CURRENT_COUNT + 1))/$RATE_LIMIT_RPM for tool '$TOOL_NAME'" >&2

# Pass through the original request
echo "$TOOL_CALL_JSON"
exit 0
