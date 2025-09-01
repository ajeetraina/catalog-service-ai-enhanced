#!/bin/bash
set -euo pipefail

# Read the JSON response from stdin
RESPONSE_JSON=$(cat)

# Extract content for filtering
ORIGINAL_CONTENT=$(echo "$RESPONSE_JSON" | jq -r '.result.content[0].text // ""')

if [[ -n "$ORIGINAL_CONTENT" ]]; then
    # Patterns to filter/redact
    FILTERED_CONTENT="$ORIGINAL_CONTENT"
    
    # 1. Redact API keys and tokens
    FILTERED_CONTENT=$(echo "$FILTERED_CONTENT" | sed -E 's/\b[Aa][Pp][Ii][_-]?[Kk][Ee][Yy][[:space:]]*[:=][[:space:]]*[^[:space:]]+/API_KEY=[REDACTED]/g')
    FILTERED_CONTENT=$(echo "$FILTERED_CONTENT" | sed -E 's/\b[Tt][Oo][Kk][Ee][Nn][[:space:]]*[:=][[:space:]]*[^[:space:]]+/TOKEN=[REDACTED]/g')
    
    # 2. Redact passwords
    FILTERED_CONTENT=$(echo "$FILTERED_CONTENT" | sed -E 's/\b[Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd][[:space:]]*[:=][[:space:]]*[^[:space:]]+/PASSWORD=[REDACTED]/g')
    
    # 3. Redact email addresses (partial)
    FILTERED_CONTENT=$(echo "$FILTERED_CONTENT" | sed -E 's/([a-zA-Z0-9._%+-])[a-zA-Z0-9._%+-]*@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/\1***@\2/g')
    
    # Check if any filtering occurred
    if [[ "$ORIGINAL_CONTENT" != "$FILTERED_CONTENT" ]]; then
        # Update the response with filtered content
        RESPONSE_JSON=$(echo "$RESPONSE_JSON" | jq --arg filtered "$FILTERED_CONTENT" '.result.content[0].text = $filtered')
        
        # Log filtering action
        echo "🔒 CONTENT FILTER: Sensitive data redacted in response" >&2
        
        # Add filtering metadata
        RESPONSE_JSON=$(echo "$RESPONSE_JSON" | jq '.result.content[0].filtered = true | .result.content[0].filter_timestamp = now | .result.content[0].filter_rules = ["api_keys", "passwords", "emails"]')
    fi
fi

# Pass through the (potentially filtered) response
echo "$RESPONSE_JSON"
exit 0
