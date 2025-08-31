# AI-Enhanced Catalog Service

AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization.

<img width="1007" height="941" alt="image" src="https://github.com/user-attachments/assets/1337bbdf-414c-40d6-9350-4a2e4f13dc34" />


## Features

- 🤖 **AI Agents**: Intelligent evaluation and decision-making
- 🔍 **Market Research**: Automated competitor analysis
- 📊 **Smart Analytics**: Customer preference matching
- 🚀 **Modern Stack**: Kafka (KRaft), PostgreSQL, MongoDB
- 🎯 **MCP Gateway**: Secure AI tool orchestration
- 🧠 **Model Runner**: Local AI model execution


## AI Agents System:

The repository includes four specialized AI agents:

- **Vendor Intake Agent**: Evaluates product submissions with 0-100 scoring
- **Market Research Agent**: Performs automated competitor analysis
- **Customer Match Agent**: Analyzes customer preferences
- **Catalog Management Agent**: Updates and maintains the product catalog

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

## Submit a Product


```
Vendor:NVIDIA
Product: Jetson Nano Super
Description: Jetson Nano is a tiny computer for AI application.
Price: 249.0
Category: Electronics
```

<img width="882" height="838" alt="image" src="https://github.com/user-attachments/assets/6f56c98a-1d26-4b5e-aef6-364ae504efaf" />

<img width="853" height="443" alt="image" src="https://github.com/user-attachments/assets/4157c0d1-791d-4f67-8272-bd9918b0bd52" />



## Kafka UI

<img width="1307" height="928" alt="image" src="https://github.com/user-attachments/assets/593cea88-af9d-45c7-b2f5-1e87aa022400" />

