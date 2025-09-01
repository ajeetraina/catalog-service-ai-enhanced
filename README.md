# AI-Powered Catalog Management System

AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization.


## Features

-  **AI Agents**: Intelligent evaluation and decision-making
-  **Market Research**: Automated competitor analysis
-  **Smart Analytics**: Customer preference matching
-  **Modern Stack**: Kafka (KRaft), PostgreSQL, MongoDB
-  **MCP Gateway**: Secure AI tool orchestration
-  **Model Runner**: Local AI model execution


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


## Checking the logs

```
catalog-agent-service  | 📝 New product evaluation request: {
catalog-agent-service  |   "vendorName": "NVIDIA",
catalog-agent-service  |   "productName": "Jetson Nano Super",
catalog-agent-service  |   "description": "Jetson Nano is a tiny computer for AI application.",
catalog-agent-service  |   "price": "249",
catalog-agent-service  |   "category": "Electronics"
catalog-agent-service  | }
catalog-agent-service  | 🤖 Calling Docker Model Runner...
catalog-agent-service  | 🔗 API URL: http://model-runner.docker.internal/engines/v1/chat/completions
catalog-agent-service  | 🧠 Model: ai/llama3.2:latest
catalog-agent-service  | 
catalog-agent-service  | 📝 New product evaluation request: {
catalog-agent-service  |   "vendorName": "NVIDIA",e Watch
catalog-agent-service  |   "productName": "Jetson Nano Super",
catalog-agent-service  |   "description": "Jetson Nano is a tiny computer for AI application.",
catalog-agent-service  |   "price": "249",
catalog-agent-service  |   "category": "Electronics"
catalog-agent-service  | }
catalog-agent-service  | 🤖 Calling Docker Model Runner...
catalog-agent-service  | 🔗 API URL: http://model-runner.docker.internal/engines/v1/chat/completions
catalog-agent-service  | 🧠 Model: ai/llama3.2:latest
catalog-kafka-ui       | 2025-08-31 18:47:07,123 DEBUG [parallel-7] i.k.u.s.ClustersStatisticsScheduler: Start getting metrics for kafkaCluster: local
catalog-kafka-ui       | 2025-08-31 18:47:07,170 DEBUG [parallel-4] i.k.u.s.ClustersStatisticsScheduler: Metrics updated for cluster: local
catalog-agent-service  | ✅ Docker Model Runner response received
catalog-agent-service  | 📊 Response status: 200
catalog-agent-service  | ⚠️ AI response not JSON, parsing as text...
catalog-agent-service  | ✅ Docker Model Runner response received
catalog-agent-service  | 📊 Response status: 200
catalog-agent-service  | ⚠️ AI response not JSON, parsing as text...
catalog-agent-service  | 🎯 AI Evaluation Result:
catalog-agent-service  |    Score: 87/100
catalog-agent-service  |    Decision: APPROVED
catalog-agent-service  |    Processing Time: 6169ms
catalog-agent-service  | 🎯 AI Evaluation Result:
catalog-agent-service  |    Score: 87/100
catalog-agent-service  |    Decision: APPROVED
catalog-agent-service  |    Processing Time: 6169ms
catalog-agent-service  | 💾 Evaluation stored in MongoDB
catalog-agent-service  | 💾 Evaluation stored in MongoDB
catalog-agent-service  | 📡 Evaluation published to Kafka
catalog-agent-service  | 📡 Evaluation published to Kafka
```

