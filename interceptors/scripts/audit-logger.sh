#!/bin/bash
set -euo pipefail

# Read the JSON response from stdin
RESPONSE_JSON=$(cat)

# Extract key information
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%S.%3NZ')
SESSION_ID=$(echo "$RESPONSE_JSON" | jq -r '.meta.sessionId // "unknown"')
TOOL_NAME=$(echo "$RESPONSE_JSON" | jq -r '.result.toolName // "unknown"')
DURATION=$(echo "$RESPONSE_JSON" | jq -r '.result.duration // "0s"')
IS_ERROR=$(echo "$RESPONSE_JSON" | jq -r '.result.isError // false')

# Response content analysis
CONTENT_LENGTH=0
CONTENT_TYPE="text"
if echo "$RESPONSE_JSON" | jq -e '.result.content[0].text' > /dev/null 2>&1; then
    CONTENT_LENGTH=$(echo "$RESPONSE_JSON" | jq -r '.result.content[0].text | length')
    CONTENT_TYPE="text"
elif echo "$RESPONSE_JSON" | jq -e '.result.content[0].blob' > /dev/null 2>&1; then
    CONTENT_LENGTH=$(echo "$RESPONSE_JSON" | jq -r '.result.content[0].blob | length')
    CONTENT_TYPE="blob"
fi

# Security scanning for sensitive data
SENSITIVE_PATTERNS="(?i)(password|secret|token|api[_-]?key|credentials|private[_-]?key)"
HAS_SENSITIVE_DATA=false
if echo "$RESPONSE_JSON" | jq -r '.result.content[0].text // ""' | grep -qP "$SENSITIVE_PATTERNS" 2>/dev/null; then
    HAS_SENSITIVE_DATA=true
fi

# Create audit log directory
AUDIT_DIR="/var/log/mcp"
mkdir -p "$AUDIT_DIR"

# Comprehensive audit log entry
AUDIT_ENTRY=$(cat <<EOFR
{
  "timestamp": "$TIMESTAMP",
  "event_type": "mcp_tool_response",
  "session_id": "$SESSION_ID",
  "tool_name": "$TOOL_NAME",
  "duration": "$DURATION",
  "is_error": $IS_ERROR,
  "response_stats": {
    "content_length": $CONTENT_LENGTH,
    "content_type": "$CONTENT_TYPE",
    "has_sensitive_data": $HAS_SENSITIVE_DATA
  },
  "security": {
    "interceptor": "audit-logger.sh",
    "scan_timestamp": "$TIMESTAMP"
  }
}
EOFR
)

# Write to audit log
echo "$AUDIT_ENTRY" >> "$AUDIT_DIR/audit.jsonl"

# Log summary to stderr
if [[ "$IS_ERROR" == "true" ]]; then
    echo "❌ AUDIT LOG: Session $SESSION_ID - Tool '$TOOL_NAME' failed after $DURATION" >&2
else
    echo "📝 AUDIT LOG: Session $SESSION_ID - Tool '$TOOL_NAME' succeeded ($CONTENT_LENGTH chars, $DURATION)" >&2
fi

# Alert if sensitive data detected
if [[ "$HAS_SENSITIVE_DATA" == "true" ]]; then
    echo "🚨 SECURITY ALERT: Sensitive data detected in response from '$TOOL_NAME' - Session $SESSION_ID" >&2
    
    # Log security incident
    SECURITY_INCIDENT=$(cat <<EOFR
{
  "timestamp": "$TIMESTAMP",
  "event_type": "security_incident",
  "incident_type": "sensitive_data_in_response",
  "session_id": "$SESSION_ID",
  "tool_name": "$TOOL_NAME",
  "severity": "medium",
  "details": {
    "patterns_matched": "$SENSITIVE_PATTERNS",
    "content_length": $CONTENT_LENGTH
  }
}
EOFR
)
    echo "$SECURITY_INCIDENT" >> "$AUDIT_DIR/security-incidents.jsonl"
fi

# Pass through the original response
echo "$RESPONSE_JSON"
exit 0
