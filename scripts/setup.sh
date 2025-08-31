#!/bin/bash
set -e

echo "🔧 Setting up AI-Enhanced Catalog Service..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi

# Generate secrets
if [ ! -f secrets/.mcp.env ]; then
    echo "🔐 Creating secrets file..."
    mkdir -p secrets
    cp .env.example secrets/.mcp.env
fi

echo "📦 Installing dependencies..."
npm install
cd backend && npm install && cd ..
cd frontend && npm install && cd ..
cd agent-service && npm install && cd ..
cd agent-portal && npm install && cd ..

echo "✅ Setup complete!"
