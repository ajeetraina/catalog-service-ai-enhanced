# AI-Enhanced Catalog Service

AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization.

## Features

- 🤖 **AI Agents**: Intelligent evaluation and decision-making
- 🔍 **Market Research**: Automated competitor analysis
- 📊 **Smart Analytics**: Customer preference matching
- 🚀 **Modern Stack**: Kafka (KRaft), PostgreSQL, MongoDB
- 🎯 **MCP Gateway**: Secure AI tool orchestration
- 🧠 **Model Runner**: Local AI model execution

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

## Development

```bash
# Install dependencies
npm install

# Run backend
npm run dev

# Run tests
npm test
```

## License

MIT
