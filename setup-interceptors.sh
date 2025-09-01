#!/bin/bash
# Setup interceptors for catalog service

echo "🔧 Setting up MCP Interceptors..."

# Create log directories
sudo mkdir -p /var/log/mcp
sudo chmod 755 /var/log/mcp
sudo chown $USER:$USER /var/log/mcp

# Create session tracking directory
mkdir -p /tmp/mcp-sessions
chmod 755 /tmp/mcp-sessions

# Copy environment file
if [ ! -f .mcp.env ]; then
    cp .mcp.env.interceptors .mcp.env
    echo "✅ Created .mcp.env from template"
else
    echo "ℹ️  .mcp.env already exists"
fi

# Make scripts executable
chmod +x interceptors/scripts/*.sh
chmod +x test-interceptors.sh

echo "✅ Interceptor setup complete!"
echo ""
echo "Next steps:"
echo "1. Review .mcp.env and add your API keys"
echo "2. Run: docker compose -f docker-compose.interceptors.yml up -d"
echo "3. Test: ./test-interceptors.sh"
