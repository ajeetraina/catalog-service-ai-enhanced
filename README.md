# AI-Enhanced Catalog Service

AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization.

## Features

- 🤖 **AI Agents**: Intelligent evaluation and decision-making
- 🔍 **Market Research**: Automated competitor analysis
- 📊 **Smart Analytics**: Customer preference matching
- 🚀 **Modern Stack**: Kafka (KRaft), PostgreSQL, MongoDB
- 🎯 **MCP Gateway**: Secure AI tool orchestration
- 🧠 **Model Runner**: Local AI model execution


## AI Agents System:

The repository includes four specialized AI agents:

- Vendor Intake Agent: Evaluates product submissions with 0-100 scoring
- Market Research Agent: Performs automated competitor analysis
- Customer Match Agent: Analyzes customer preferences
- Catalog Management Agent: Updates and maintains the product catalog

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/ajeetraina/catalog-service-ai-enhanced.git
cd catalog-service-ai-enhanced
```

2. Configure environment:
```bash
cp .env.example .env
# Edit .env with your API keys
```

3. Start services:
```bash
docker compose up -d
```

4. Access applications:
- Frontend: http://localhost:5173
- Agent Portal: http://localhost:3001
- API: http://localhost:3000
- pgAdmin: http://localhost:5050
- Kafka UI: http://localhost:8080

## Architecture

The system uses a microservices architecture with:
- Docker Model Runner for local AI
- MCP Gateway for tool orchestration
- Kafka for event streaming (KRaft mode)
- PostgreSQL for catalog data
- MongoDB for agent history

## AI Agents

1. **Vendor Intake**: Evaluates submissions (0-100 score)
2. **Market Research**: Searches competitor data
3. **Customer Match**: Analyzes preferences
4. **Catalog Management**: Updates product catalog

## Add a Product

```
# Add a few more products
curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Smart Watch Ultra","description":"Advanced fitness tracker with heart rate, GPS","price":299.99,"vendor":"TechCorp"}'

curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Wireless Earbuds Pro","description":"Noise cancelling, 24hr battery","price":199.99,"vendor":"AudioTech"}'

curl -X POST http://localhost:3000/api/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Smart Home Hub","description":"Voice control for 100+ devices","price":149.99,"vendor":"HomeTech"}'
```

## Verify the newly added products

```
 curl http://localhost:3000/api/products
{"products":[{"id":1,"name":"Smart Watch Ultra","description":"Advanced fitness tracker with heart rate, GPS","price":299.99,"vendor":"TechCorp","ai_score":84,"created_at":"2025-08-31T11:51:46.954Z"},{"id":2,"name":"Wireless Earbuds Pro","description":"Noise cancelling, 24hr battery","price":199.99,"vendor":"AudioTech","ai_score":76,"created_at":"2025-08-31T11:51:46.978Z"},{"id":3,"name":"Smart Home Hub","description":"Voice control for 100+ devices","price":149.99,"vendor":"HomeTech","ai_score":77,"created_at":"2025-08-31T11:51:46.991Z"}]}%
```
