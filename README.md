# AI-Powered Multi-Agent Catalog Management System

AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization. 
This is a multi-agent microservices architecture that uses AI to automatically evaluate product submissions.

This repo helps you learn how Agentic AI can shorten the process of creating and managing Product catalog.

Core Components:

- Frontend (React) - Product submission interface
- Backend API - Node.js REST API
- Agent Service - Core AI evaluation engine
- Agent Portal - Admin interface for agent management
- MCP Gateway - Tool orchestration layer
- Docker Model Runner - Local LLM execution
- Databases: PostgreSQL (catalog) + MongoDB (agent history)
- Kafka - Event streaming (KRaft mode)


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

## How the AI Evaluation Works

### 1. The Four AI Agents:

```
const agents = {
  vendorIntake: {
    name: 'Vendor Intake Agent',
    role: 'Evaluates vendor submissions using Docker Model Runner',
    threshold: 70,  // Your rejection threshold
    model: 'ai/llama3.2:latest'
  },
  marketResearch: { /* Competitor analysis */ },
  customerMatch: { /* Customer preference matching */ },
  catalog: { /* Catalog management */ }
}
```

### 2. Evaluation Process Flow:

When you submit a product, here's exactly what happens:

Frontend → Backend → Agent Service (/products/evaluate)
AI Prompt Generation:

```
const evaluationPrompt = `You are an expert product evaluator...

Product Details:
- Vendor: ${product.vendorName}
- Product Name: ${product.productName}  
- Description: ${product.description}
- Price: $${product.price}
- Category: ${product.category}

Evaluation Criteria (100 points total):
- Product innovation and quality (25 points)
- Market demand and competitiveness (25 points)  
- Description clarity and completeness (20 points)
- Price appropriateness (15 points)
- Vendor credibility (15 points)

Minimum passing score: 70/100`
```

### 3 Docker Model Runner Call:

- Uses Llama 3.2 model locally
- Endpoint: http://model-runner.docker.internal/engines/v1/chat/completions
- 60-second timeout for processing


### 4. Response Processing

```
{
  "score": 87,           // Your NVIDIA example got 87/100
  "decision": "APPROVED", // Because 87 > 70 threshold
  "reasoning": "Detailed AI analysis...",
  "category_match": "Electronics - Perfect match",
  "market_potential": "High"
}
```

### 5. Configuration & Thresholds:

- Passing Score: 70/100 (configurable via VENDOR_EVALUATION_THRESHOLD)
- AI Model: Llama 3.2 (local via Docker Model Runner)
- Processing Timeout: 60 seconds
- Scoring Breakdown:
  - Innovation: 25 pts
  - Market demand: 25 pts
  - Description clarity: 20 pts
  - Pricing: 15 pts
  - Vendor credibility: 15 pts

### 6. 🔄 Data Flow & Storage:

- Evaluation Results → MongoDB (agent_history database)
- Approved Products → PostgreSQL (catalog_db)
- Event Stream → Kafka (product-evaluations topic)
- Admin Monitoring → Agent Portal UI

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

