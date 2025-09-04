# Getting Started with catalog-service-cagent

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/ajeetraina/catalog-service-cagent.git
   cd catalog-service-cagent
   ```

2. **Run setup script**:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **Access the application**:
   - Frontend: http://localhost:5173
   - Agent Portal: http://localhost:3001
   - API: http://localhost:3000

## Manual Setup

If you prefer manual setup:

1. **Configure environment**:
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

2. **Start services**:
   ```bash
   docker compose up -d
   ```

3. **Test the system**:
   ```bash
   curl -X POST http://localhost:3000/api/products/evaluate \
     -H "Content-Type: application/json" \
     -d '{
       "vendorName": "Test Vendor",
       "productName": "Test Product",
       "description": "A test product for cagent evaluation",
       "price": 99.99,
       "category": "Electronics"
     }'
   ```

## Next Steps

- [Configure your agents](agent-configuration.md)
- [Set up monitoring](deployment.md#monitoring)
- [Customize MCP servers](mcp-integration.md)
