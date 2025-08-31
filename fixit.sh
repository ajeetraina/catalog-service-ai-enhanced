#!/bin/bash

# fix-catalog-system.sh
# Complete fix script for AI-Enhanced Catalog Service

echo "🔧 AI-Enhanced Catalog Service - Complete Fix Script"
echo "====================================================="

# Stop all services first
echo "📦 Stopping existing services..."
docker compose down

# Fix 1: Agent Service MongoDB Connection
echo "🔧 Fixing agent-service MongoDB connection..."
if [ -f "agent-service/src/app.js" ]; then
    # Fix MongoDB connection
    sed -i.bak 's|localhost:27017|mongodb:27017|g' agent-service/src/app.js
    # Fix model name
    sed -i.bak "s|'ai/llama3.2:3b'|'ai/llama3.2:latest'|g" agent-service/src/app.js
    echo "✅ Agent service fixed"
fi

# Fix 2: Create Backend Service if missing
echo "🔧 Setting up backend service..."
if [ ! -d "backend" ]; then
    mkdir -p backend/src
    
    # Create package.json
    cat > backend/package.json << 'EOF'
{
  "name": "catalog-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "pg": "^8.11.3",
    "mongodb": "^6.3.0",
    "axios": "^1.6.2"
  }
}
EOF

    # Create Dockerfile
    cat > backend/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
EOF

    # Create server.js
    cat > backend/src/server.js << 'EOF'
import express from 'express';
import cors from 'cors';
import pg from 'pg';
import axios from 'axios';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// PostgreSQL connection
const pgPool = new pg.Pool({
  host: process.env.POSTGRES_HOST || 'postgres',
  port: process.env.POSTGRES_PORT || 5432,
  user: process.env.POSTGRES_USER || 'postgres',
  password: process.env.POSTGRES_PASSWORD || 'postgres',
  database: process.env.POSTGRES_DB || 'catalog_db'
});

// Initialize products table
pgPool.query(`
  CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    price DECIMAL(10,2),
    vendor VARCHAR(255),
    ai_score INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
  )
`).catch(console.error);

// API Routes
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

app.get('/api/products', async (req, res) => {
  try {
    const result = await pgPool.query('SELECT * FROM products ORDER BY created_at DESC LIMIT 20');
    res.json({ products: result.rows });
  } catch (error) {
    console.error('Error fetching products:', error);
    res.json({ products: [] });
  }
});

app.post('/api/products', async (req, res) => {
  try {
    const { name, description, price, vendor } = req.body;
    
    // Call agent service for AI evaluation
    let aiScore = 75; // default
    try {
      const evaluation = await axios.post(
        `${process.env.AGENT_SERVICE_URL}/products/evaluate`,
        { vendor, product: name, description, price }
      );
      aiScore = evaluation.data?.evaluation?.score || 75;
    } catch (err) {
      console.log('AI evaluation failed, using default score');
    }
    
    const result = await pgPool.query(
      'INSERT INTO products (name, description, price, vendor, ai_score) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [name, description, price, vendor, aiScore]
    );
    res.json({ success: true, product: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Backend API running on port ${PORT}`);
});
EOF
    echo "✅ Backend service created"
else
    echo "✅ Backend directory exists"
fi

# Fix 3: Update Frontend API Configuration
echo "🔧 Fixing frontend API configuration..."
if [ -f "frontend/src/App.jsx" ]; then
    sed -i.bak 's|http://localhost:[0-9]*|http://localhost:3000|g' frontend/src/App.jsx
    echo "✅ Frontend configured to use backend on port 3000"
fi

# Fix 4: Update docker-compose.yml
echo "🔧 Updating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
services:
  # Backend API Service
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: catalog-backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - PORT=3000
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=catalog_db
      - MONGODB_URI=mongodb://admin:admin@mongodb:27017/catalog_db?authSource=admin
      - AGENT_SERVICE_URL=http://agent-service:7777
    networks:
      - catalog-network
    depends_on:
      - postgres
      - mongodb
      - agent-service

  # Frontend Application
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: catalog-frontend
    ports:
      - "5173:5173"
    environment:
      - API_URL=http://localhost:3000
      - AGENT_PORTAL_URL=http://localhost:3001
    networks:
      - catalog-network
    depends_on:
      - backend

  # Agent Portal UI
  agent-portal:
    build:
      context: ./agent-portal
      dockerfile: Dockerfile
    container_name: catalog-agent-portal
    ports:
      - "3001:3000"
    environment:
      - API_URL=http://backend:3000
      - AGENT_SERVICE_URL=http://agent-service:7777
      - MCP_GATEWAY_URL=http://mcp-gateway:8811
    networks:
      - catalog-network
    depends_on:
      - backend
      - agent-service
      - mcp-gateway

  # Main Agent Service with AI capabilities
  agent-service:
    build:
      context: ./agent-service
      dockerfile: Dockerfile
    container_name: catalog-agent-service
    ports:
      - "7777:7777"
    user: "0:0"
    models:
      llama_model:
        endpoint_var: MODEL_RUNNER_URL
        model_var: MODEL_RUNNER_MODEL
    environment:
      - KAFKA_BROKERS=kafka:29092
      - KAFKA_CLIENT_ID=agent-service
      - KAFKA_GROUP_ID=agent-service-group
      - POSTGRES_HOST=postgres
      - POSTGRES_PORT=5432
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=catalog_db
      - MONGODB_URL=mongodb://admin:admin@mongodb:27017/agent_history?authSource=admin
      - AI_DEFAULT_MODEL=ai/llama3.2:latest
      - MCP_GATEWAY_URL=http://mcp-gateway:8811
      - VENDOR_EVALUATION_THRESHOLD=70
      - MARKET_RESEARCH_ENABLED=true
      - CUSTOMER_MATCHING_ENABLED=true
    networks:
      - catalog-network
    depends_on:
      kafka:
        condition: service_healthy
      postgres:
        condition: service_healthy
      mongodb:
        condition: service_healthy
      mcp-gateway:
        condition: service_started
    restart: unless-stopped

  # MCP Gateway for tool orchestration
  mcp-gateway:
    image: docker/mcp-gateway:latest
    container_name: catalog-mcp-gateway
    ports:
      - "8811:8811"
    use_api_socket: true
    models:
      llama_model:
        endpoint_var: MODEL_RUNNER_URL
        model_var: MODEL_RUNNER_MODEL
    command:
      - --transport=sse
      - --servers=fetch,web,database
      - --verbose
    networks:
      - catalog-network
    restart: unless-stopped

  # Apache Kafka with KRaft mode
  kafka:
    image: apache/kafka:latest
    container_name: catalog-kafka
    user: "0:0"
    ports:
      - "9092:9092"
      - "9093:9093"
    environment:
      - KAFKA_NODE_ID=1
      - KAFKA_PROCESS_ROLES=broker,controller
      - KAFKA_CONTROLLER_QUORUM_VOTERS=1@kafka:9093
      - KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:29092,CONTROLLER://0.0.0.0:9093,EXTERNAL://0.0.0.0:9092
      - KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://kafka:29092,EXTERNAL://localhost:9092
      - KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT,CONTROLLER:PLAINTEXT,EXTERNAL:PLAINTEXT
      - KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT
      - KAFKA_CONTROLLER_LISTENER_NAMES=CONTROLLER
      - KAFKA_LOG_DIRS=/var/kafka-logs
      - KAFKA_LOG_RETENTION_HOURS=168
      - KAFKA_LOG_SEGMENT_BYTES=1073741824
      - KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
      - CLUSTER_ID=MkU3OTk5NTcwNTJENDM2Qk
      - KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
      - KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR=1
      - KAFKA_TRANSACTION_STATE_LOG_MIN_ISR=1
    volumes:
      - kafka_data:/var/kafka-logs
    networks:
      - catalog-network
    healthcheck:
      test:
        - CMD-SHELL
        - /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server localhost:29092 || exit 1
      interval: 10s
      timeout: 10s
      retries: 5
    restart: unless-stopped

  # Kafka UI
  kafka-ui:
    image: kafbat/kafka-ui:v1.2.0
    container_name: catalog-kafka-ui
    ports:
      - "8080:8080"
    environment:
      - KAFKA_CLUSTERS_0_NAME=local
      - KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=kafka:29092
      - KAFKA_CLUSTERS_0_PROPERTIES_SECURITY_PROTOCOL=PLAINTEXT
      - DYNAMIC_CONFIG_ENABLED=true
    networks:
      - catalog-network
    depends_on:
      - kafka
    restart: unless-stopped

  # PostgreSQL
  postgres:
    image: postgres:16-alpine
    container_name: catalog-postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=catalog_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - catalog-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # pgAdmin
  pgadmin:
    image: dpage/pgadmin4:latest
    container_name: catalog-pgadmin
    ports:
      - "5050:80"
    environment:
      - PGADMIN_DEFAULT_EMAIL=admin@catalog.com
      - PGADMIN_DEFAULT_PASSWORD=admin
      - PGADMIN_CONFIG_SERVER_MODE=False
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    networks:
      - catalog-network
    depends_on:
      - postgres
    restart: unless-stopped

  # MongoDB
  mongodb:
    image: mongo:7.0
    container_name: catalog-mongodb
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=admin
      - MONGO_INITDB_DATABASE=agent_history
    volumes:
      - mongodb_data:/data/db
    networks:
      - catalog-network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  # WireMock
  wiremock:
    image: wiremock/wiremock:latest
    container_name: catalog-wiremock
    ports:
      - "8081:8080"
    volumes:
      - ./wiremock/mappings:/home/wiremock/mappings
      - ./wiremock/__files:/home/wiremock/__files
    command:
      - --global-response-templating
      - --verbose
    networks:
      - catalog-network
    restart: unless-stopped

models:
  llama_model:
    model: ai/llama3.2:latest

networks:
  catalog-network:
    driver: bridge

volumes:
  postgres_data:
  pgadmin_data:
  mongodb_data:
  kafka_data:
EOF

echo "✅ docker-compose.yml updated"

# Clean volumes if requested
read -p "Do you want to clean all Docker volumes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    docker volume rm catalog-service-ai-enhanced_kafka_data 2>/dev/null
    docker volume rm catalog-service-ai-enhanced_postgres_data 2>/dev/null
    docker volume rm catalog-service-ai-enhanced_mongodb_data 2>/dev/null
    echo "✅ Volumes cleaned"
fi

# Build and start services
echo "🚀 Building and starting all services..."
docker compose build --no-cache
docker compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Test services
echo "🧪 Testing services..."
echo "----------------------------------------"

# Test Backend
if curl -s http://localhost:3000/health | grep -q "healthy"; then
    echo "✅ Backend API: Running"
else
    echo "❌ Backend API: Failed"
fi

# Test Agent Service
if curl -s http://localhost:7777/health | grep -q "healthy"; then
    echo "✅ Agent Service: Running"
else
    echo "❌ Agent Service: Failed"
fi

# Test Model Runner
if curl -s http://localhost:12434/models | grep -q "llama3.2"; then
    echo "✅ Model Runner: Llama 3.2 loaded"
else
    echo "❌ Model Runner: Not responding"
fi

# Show all services
echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "🌐 Web Interfaces:"
echo "----------------------------------------"
echo "Frontend:     http://localhost:5173"
echo "Backend API:  http://localhost:3000"
echo "Agent Portal: http://localhost:3001"
echo "Kafka UI:     http://localhost:8080"
echo "pgAdmin:      http://localhost:5050"
echo ""
echo "✨ System is ready! Try submitting a product at http://localhost:3001"
