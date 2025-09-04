#!/bin/bash

# Agent configuration validator for cagent

if [ $# -eq 0 ]; then
    echo "Usage: $0 <agent-config.yaml>"
    exit 1
fi

AGENT_CONFIG="$1"

if [ ! -f "$AGENT_CONFIG" ]; then
    echo "❌ Agent config file not found: $AGENT_CONFIG"
    exit 1
fi

echo "🔍 Validating cagent configuration: $AGENT_CONFIG"

# Check if cagent binary is available
if [ ! -f "./bin/cagent" ]; then
    echo "❌ cagent binary not found. Run ./setup.sh first."
    exit 1
fi

# Validate configuration
echo "📋 Running cagent validation..."
if ./bin/cagent validate "$AGENT_CONFIG"; then
    echo "✅ Agent configuration is valid!"
else
    echo "❌ Agent configuration has errors!"
    exit 1
fi

# Check for common issues
echo "🔍 Checking for common configuration issues..."

# Check for required API keys
if grep -q "your_.*_key_here" "$AGENT_CONFIG"; then
    echo "⚠️  Warning: Found placeholder API keys in configuration"
fi

# Check model availability
if grep -q "openai/" "$AGENT_CONFIG"; then
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "⚠️  Warning: OpenAI models specified but OPENAI_API_KEY not set"
    fi
fi

if grep -q "claude" "$AGENT_CONFIG"; then
    if [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "⚠️  Warning: Claude models specified but ANTHROPIC_API_KEY not set"
    fi
fi

echo "✅ Validation completed!"
