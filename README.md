# AI-Powered Catalog Management System

<img width="1014" height="724" alt="image" src="https://github.com/user-attachments/assets/33b6b9dc-803e-4524-ab27-eeab6d1acf57" />


AI-powered catalog management system with intelligent agents for product evaluation, market research, and inventory optimization. 
This repo helps you learn how Agentic AI can shorten the process of creating and managing Product catalog.


## Tech Stack

- Frontend: React/Next.js (:5173)
- Agent Portal: Custom UI (:3001)
- AI Layer: Agent Service (:7777) + LLM (ai/llama3.2:latest)
- Security: MCP Gateway (:8811) + Interceptors (:8080, :8081)
- Backend: Node.js API (:3000)
- Messaging: Apache Kafka (:9092)
- Databases: PostgreSQL (:5432), MongoDB (:27017)
- Storage: AWS S3 (Object Storage)
- Monitoring: Prometheus (:9090), Grafana (:3002)
- Testing: WireMock (:8083), pgAdmin (:5050)


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

## 🛡️ Security Integration Highlights:

- BEFORE Interceptors: Security validation, rate limiting, threat detection
- MCP Gateway: Tool orchestration with SSE transport
- AFTER Interceptors: PII detection, audit logging, compliance scoring
- Enterprise Protection: SQL injection blocking, risk assessment

## 📈 Monitoring & Compliance:

- Real-time Metrics: Prometheus collecting security and performance data
- Visual Dashboards: Grafana for operational visibility
- Audit Trails: Complete compliance logging for GDPR/PCI
- Health Monitoring: All services with health endpoints

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
docker compose -f docker-compose.interceptors.yaml up -d
```

4. Access applications:
- Frontend: http://localhost:5173
- Agent Portal: http://localhost:3001
- API: http://localhost:3000
- pgAdmin: http://localhost:5050
- Kafka UI: http://localhost:8080

## Testing the interceptor


### 🚨 SQL Injection Test:

```
Vendor: Evil Corp
Product: Malicious Product
Description: Contact us for product '; DROP TABLE products; -- with special pricing
Price: 99.99
Category: Hacking
```

<img width="870" height="756" alt="image" src="https://github.com/user-attachments/assets/ec065466-5c95-4b99-a07b-7c39043f4309" />

### 🔐 PII Detection Test:

```
Vendor: John Doe
Product: Personal Device
Description: Contact john.doe@email.com, phone: 555-123-4567, SSN: 123-45-6789, credit card: 4532-1234-5678-9012
Price: 299.99
Category: Personal
```

<img width="859" height="824" alt="image" src="https://github.com/user-attachments/assets/cc7358d2-2a1d-4e62-8448-a182653f6dad" />

### 🔑 Blocked Patterns Test:

```
Vendor: Secret Corp
Product: API Product
Description: This product requires password=admin123, secret_key=topsecret, and api_key=sk-12345 for access
Price: 199.99
Category: Security
```
<img width="916" height="822" alt="image" src="https://github.com/user-attachments/assets/6c89504f-78f7-4d17-be9d-08f6ba5fd901" />


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

## Verify Service Health

```
curl http://localhost:3000/health      # Main API
{"status":"healthy"}%
```


```
curl http://localhost:8811/health      # MCP Gateway
```


```
curl http://localhost:8080/health      # Before Interceptor
{"status":"healthy","security_mode":"strict","rate_limit_rpm":60,"timestamp":"2025-09-01T18:33:30.281076"}%
```

```
curl http://localhost:8081/health      # After Interceptor
{"status":"healthy","audit_mode":"full","compliance_rules":["pii_detection","sensitive_data"],"timestamp":"2025-09-01T18:34:06.096743"}%
```

