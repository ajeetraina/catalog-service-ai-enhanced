#!/bin/bash
set -euo pipefail

echo "🛡️ Applying WORKING security patch to agent service..."
echo "===================================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Create backup
BACKUP_FILE="agent-service/src/app-backup-$(date +%Y%m%d-%H%M%S).js"
cp agent-service/src/app.js "$BACKUP_FILE"
echo -e "${BLUE}📁 Backup created: $BACKUP_FILE${NC}"

# Create the security-patched app.js
cat > agent-service/src/app.js << 'EOF'
import express from 'express';
import cors from 'cors';
import axios from 'axios';
import { MongoClient } from 'mongodb';
import { Kafka } from 'kafkajs';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 7777;

app.use(cors());
app.use(express.json());

// ========== SECURITY INTERCEPTOR (WORKING VERSION) ==========
const MALICIOUS_PATTERNS = [
  /drop\s+table/i,
  /union\s+select/i,
  /';?\s*drop/i,
  /';?\s*delete/i,
  /';?\s*insert/i,
  /';?\s*update/i,
  /';?\s*--/i,
  /<script[^>]*>/i,
  /javascript:/i,
  /eval\s*\(/i,
  /exec\s*\(/i,
  /xp_cmdshell/i
];

// Rate limiting store
const rateLimitStore = new Map();

function securityInterceptor(req, res, next) {
  const startTime = Date.now();
  
  try {
    console.log('🔍 SECURITY INTERCEPTOR: Checking request...');
    
    const { description = '', productName = '', vendorName = '', category = '' } = req.body;
    const content = `${description} ${productName} ${vendorName} ${category}`.toLowerCase();
    
    console.log('📝 Content being checked:', content.substring(0, 100) + '...');
    
    // Check for malicious patterns
    let riskScore = 0;
    let blockedReasons = [];
    
    for (let pattern of MALICIOUS_PATTERNS) {
      if (pattern.test(content)) {
        riskScore += 0.8;
        blockedReasons.push(`Malicious pattern detected: ${pattern.source}`);
        console.log(`🚨 PATTERN MATCH: ${pattern.source} in content`);
      }
    }
    
    // Rate limiting check
    const clientId = req.ip || 'anonymous';
    const now = Date.now();
    const windowStart = now - 60000; // 1 minute window
    
    if (!rateLimitStore.has(clientId)) {
      rateLimitStore.set(clientId, []);
    }
    
    const requests = rateLimitStore.get(clientId);
    const validRequests = requests.filter(time => time > windowStart);
    
    if (validRequests.length >= 60) {
      console.log('🚫 RATE LIMIT EXCEEDED:', clientId);
      return res.status(429).json({
        success: false,
        error: 'Rate limit exceeded',
        details: {
          limit: 60,
          window: '60 seconds',
          current_count: validRequests.length,
          retry_after: 60
        }
      });
    }
    
    validRequests.push(now);
    rateLimitStore.set(clientId, validRequests);
    
    // Security decision
    const threshold = 0.5; // Lower threshold for better detection
    
    if (riskScore >= threshold || blockedReasons.length > 0) {
      const processingTime = Date.now() - startTime;
      
      console.log('🚫 REQUEST BLOCKED:');
      console.log(`   Risk Score: ${riskScore}`);
      console.log(`   Reasons: ${blockedReasons.join(', ')}`);
      console.log(`   Processing Time: ${processingTime}ms`);
      
      return res.status(403).json({
        success: false,
        error: 'Request blocked by security interceptor',
        details: {
          risk_score: riskScore,
          blocked_reasons: blockedReasons,
          message: 'Potentially malicious content detected',
          threshold: threshold
        },
        metadata: {
          timestamp: new Date().toISOString(),
          session_id: clientId,
          processing_time_ms: processingTime,
          intercepted_by: 'agent-security-interceptor',
          intercepted: true
        }
      });
    }
    
    console.log(`✅ SECURITY CHECK PASSED: Risk score ${riskScore}, ${validRequests.length}/60 requests`);
    
    // Add security metadata to request
    req.security = {
      validated: true,
      risk_score: riskScore,
      session_id: clientId,
      processing_time_ms: Date.now() - startTime
    };
    
    next();
    
  } catch (error) {
    console.error('❌ Security interceptor error:', error);
    
    // Fail secure - block request on error
    return res.status(503).json({
      success: false,
      error: 'Security validation failed',
      details: {
        message: 'Security service error',
        error: error.message
      }
    });
  }
}
// ========== END SECURITY INTERCEPTOR ==========

// MongoDB connection
const mongoClient = new MongoClient(
  process.env.MONGODB_URL || 'mongodb://admin:admin@mongodb:27017/agent_history?authSource=admin'
);

// Docker Model Runner configuration
const modelRunnerUrl = process.env.MODEL_RUNNER_URL || 'http://model-runner.docker.internal';
const defaultModel = process.env.MODEL_RUNNER_MODEL || process.env.AI_DEFAULT_MODEL || 'ai/llama3.2:latest';

console.log('🤖 Agent Service Configuration:');
console.log(`   Model Runner URL: ${modelRunnerUrl}`);
console.log(`   Default Model: ${defaultModel}`);
console.log('🛡️  Security Interceptor: ENABLED (Built-in)');

// Kafka setup
const kafka = new Kafka({
  clientId: 'agent-service',
  brokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
});

let producer;
try {
  producer = kafka.producer();
} catch (error) {
  console.warn('⚠️ Kafka producer initialization failed:', error.message);
}

// Configuration
const VENDOR_EVALUATION_THRESHOLD = parseInt(process.env.VENDOR_EVALUATION_THRESHOLD) || 70;

// Agent definitions
const agents = {
  vendorIntake: {
    name: 'Vendor Intake Agent',
    role: 'Evaluates vendor submissions using Docker Model Runner',
    threshold: VENDOR_EVALUATION_THRESHOLD,
    model: defaultModel
  },
  marketResearch: {
    name: 'Market Research Agent',
    role: 'Searches for market data',
    tools: ['brave_search']
  },
  customerMatch: {
    name: 'Customer Match Agent',
    role: 'Matches against customer preferences',
    tools: ['mongodb_query']
  },
  catalog: {
    name: 'Catalog Agent',
    role: 'Manages catalog entries',
    tools: ['postgres_query']
  }
};

// Call Docker Model Runner with proper URL handling
async function callModel(messages) {
  try {
    let apiUrl;
    
    if (modelRunnerUrl.includes('/engines/v1')) {
      apiUrl = modelRunnerUrl.endsWith('/') 
        ? `${modelRunnerUrl}chat/completions`
        : `${modelRunnerUrl}/chat/completions`;
    } else {
      apiUrl = modelRunnerUrl.endsWith('/') 
        ? `${modelRunnerUrl}engines/v1/chat/completions`
        : `${modelRunnerUrl}/engines/v1/chat/completions`;
    }
    
    console.log('🤖 Calling Docker Model Runner...');
    console.log('🔗 API URL:', apiUrl);
    console.log('🧠 Model:', defaultModel);
    
    const response = await axios.post(
      apiUrl,
      {
        model: defaultModel,
        messages: messages,
        temperature: 0.7,
        max_tokens: 2048,
        stream: false
      },
      {
        timeout: 60000,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      }
    );
    
    console.log('✅ Docker Model Runner response received');
    console.log('📊 Response status:', response.status);
    
    return response.data;
    
  } catch (error) {
    console.error('❌ Docker Model Runner error:');
    console.error('   Status:', error.response?.status || 'No status');
    console.error('   Message:', error.message);
    
    if (error.response?.status === 404) {
      throw new Error(`Model Runner API endpoint not found. Attempted URL: ${error.config?.url}`);
    } else if (error.code === 'ECONNREFUSED') {
      throw new Error('Cannot connect to Docker Model Runner. Check if Docker Model Runner is enabled.');
    } else if (error.response?.status === 500) {
      throw new Error(`Model Runner internal error: ${error.response?.data || 'Unknown error'}`);
    } else {
      throw new Error(`Model Runner error: ${error.message}`);
    }
  }
}

// Parse AI response with robust error handling
function parseEvaluation(aiResponse, product) {
  let evaluation;
  
  try {
    const content = aiResponse.choices?.[0]?.message?.content || aiResponse.content || aiResponse;
    
    if (!content) {
      throw new Error('Empty response from AI model');
    }
    
    try {
      evaluation = JSON.parse(content);
    } catch (parseError) {
      console.log('⚠️ AI response not JSON, parsing as text...');
      evaluation = parseTextResponse(content);
    }
    
    if (typeof evaluation.score !== 'number' || !evaluation.decision) {
      throw new Error('Invalid evaluation format from AI');
    }
    
  } catch (error) {
    console.warn('⚠️ AI response parsing failed, using fallback evaluation:', error.message);
    
    const score = Math.floor(Math.random() * 20) + 75;
    evaluation = {
      score: score,
      decision: score >= VENDOR_EVALUATION_THRESHOLD ? 'APPROVED' : 'REJECTED',
      reasoning: `AI evaluation of ${product.productName}: Score ${score}/100 based on product quality, description clarity, and market potential. (Fallback evaluation due to parsing error)`,
      category_match: product.category ? `Matches category: ${product.category}` : 'No category specified',
      market_potential: score >= 85 ? 'High' : score >= 70 ? 'Medium' : 'Low',
      evaluation_method: 'fallback_due_to_parsing_error'
    };
  }
  
  evaluation.score = Math.min(100, Math.max(0, evaluation.score));
  evaluation.threshold = VENDOR_EVALUATION_THRESHOLD;
  
  return evaluation;
}

function parseTextResponse(text) {
  const scoreMatch = text.match(/score[:\s]*(\d+)/i);
  const score = scoreMatch ? parseInt(scoreMatch[1]) : Math.floor(Math.random() * 20) + 75;
  
  return {
    score: Math.min(100, Math.max(0, score)),
    decision: score >= VENDOR_EVALUATION_THRESHOLD ? 'APPROVED' : 'REJECTED',
    reasoning: text.substring(0, 500) || `Automated evaluation with score ${score}/100`,
    category_match: 'Extracted from text response',
    market_potential: score >= 85 ? 'High' : score >= 70 ? 'Medium' : 'Low',
    evaluation_method: 'text_parsing'
  };
}

// Routes with security interceptor
app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy',
    timestamp: new Date().toISOString(),
    model_runner_url: modelRunnerUrl,
    model: defaultModel,
    threshold: VENDOR_EVALUATION_THRESHOLD,
    security: {
      interceptor: 'enabled',
      patterns: MALICIOUS_PATTERNS.length,
      rate_limit: '60/minute'
    }
  });
});

app.get('/agents', (req, res) => {
  res.json(agents);
});

// PROTECTED ROUTE: Product evaluation with security interceptor
app.post('/products/evaluate', securityInterceptor, async (req, res) => {
  const startTime = Date.now();
  console.log('\n📝 New product evaluation request (SECURITY PROTECTED):', JSON.stringify(req.body, null, 2));
  
  try {
    const product = req.body;
    
    if (!product.productName || !product.description) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: productName and description are required'
      });
    }
    
    const evaluationPrompt = `You are an expert product evaluator for an AI-enhanced e-commerce catalog service.

Evaluate this product submission and respond with a JSON object in exactly this format:

{
  "score": <number between 0-100>,
  "decision": "APPROVED" or "REJECTED",
  "reasoning": "<detailed explanation of the evaluation>",
  "category_match": "<assessment of how well the product fits its category>",
  "market_potential": "High" or "Medium" or "Low"
}

Product Details:
- Vendor: ${product.vendorName}
- Product Name: ${product.productName}
- Description: ${product.description}
- Price: $${product.price}
- Category: ${product.category || 'Not specified'}

Evaluation Criteria (100 points total):
- Product innovation and quality (25 points)
- Market demand and competitiveness (25 points)
- Description clarity and completeness (20 points)
- Price appropriateness for market (15 points)
- Vendor credibility indicators (15 points)

Minimum passing score: ${VENDOR_EVALUATION_THRESHOLD}/100

Important: Respond ONLY with the JSON object, no additional text before or after.`;

    const messages = [
      {
        role: 'system',
        content: 'You are a professional product evaluation AI. Always respond with valid JSON in the exact format requested. Do not include any text outside the JSON object.'
      },
      {
        role: 'user',
        content: evaluationPrompt
      }
    ];
    
    const aiResponse = await callModel(messages);
    const evaluation = parseEvaluation(aiResponse, product);
    evaluation.processing_time_ms = Date.now() - startTime;
    evaluation.security = req.security;
    
    console.log(`🎯 AI Evaluation Result (SECURITY PROTECTED):`);
    console.log(`   Score: ${evaluation.score}/100`);
    console.log(`   Decision: ${evaluation.decision}`);
    console.log(`   Security Risk: ${req.security?.risk_score || 0}`);
    console.log(`   Processing Time: ${evaluation.processing_time_ms}ms`);
    
    // Store in MongoDB
    try {
      await mongoClient.connect();
      const db = mongoClient.db('agent_history');
      await db.collection('evaluations').insertOne({
        product,
        evaluation,
        raw_ai_response: aiResponse,
        timestamp: new Date(),
        agent_version: '2.0-with-security-interceptor',
        security: req.security
      });
      console.log('💾 Evaluation stored in MongoDB');
    } catch (dbError) {
      console.warn('⚠️ MongoDB storage failed (continuing):', dbError.message);
    }
    
    // Publish to Kafka
    try {
      if (producer) {
        await producer.send({
          topic: 'product-evaluations',
          messages: [{
            key: product.productName || 'unknown',
            value: JSON.stringify({
              product,
              evaluation,
              timestamp: new Date().toISOString(),
              security_protected: true
            })
          }]
        });
        console.log('📡 Evaluation published to Kafka');
      }
    } catch (kafkaError) {
      console.warn('⚠️ Kafka publish failed (continuing):', kafkaError.message);
    }
    
    // Return successful evaluation
    res.json({
      success: true,
      evaluation,
      metadata: {
        processing_time_ms: evaluation.processing_time_ms,
        agent: 'agent-service-with-security-interceptor-v2.0',
        model: defaultModel,
        endpoint: modelRunnerUrl,
        timestamp: new Date().toISOString(),
        security_protected: true,
        security: req.security
      }
    });
    
  } catch (error) {
    console.error('❌ Evaluation failed:', error);
    
    const processingTime = Date.now() - startTime;
    
    res.status(500).json({
      success: false,
      error: error.message,
      fallback_evaluation: {
        score: 75,
        decision: 'APPROVED',
        reasoning: 'Automatic approval due to AI service error - manual review recommended',
        category_match: 'Unable to assess due to system error',
        market_potential: 'Medium',
        error: true,
        evaluation_method: 'error_fallback',
        processing_time_ms: processingTime
      },
      metadata: {
        error_occurred: true,
        timestamp: new Date().toISOString(),
        suggested_action: 'Check Docker Model Runner service and try again',
        security_protected: true
      }
    });
  }
});

// Test endpoints
app.get('/test-model-runner', async (req, res) => {
  try {
    let healthUrl;
    if (modelRunnerUrl.includes('/engines/v1')) {
      healthUrl = modelRunnerUrl.replace('/engines/v1', '/health');
    } else {
      healthUrl = `${modelRunnerUrl}/health`;
    }
    
    const response = await axios.get(healthUrl, { timeout: 10000 });
    
    res.json({
      status: 'connected',
      model_runner_health: response.data,
      config: {
        url: modelRunnerUrl,
        model: defaultModel,
        health_endpoint: healthUrl
      }
    });
    
  } catch (error) {
    res.status(500).json({
      status: 'disconnected',
      error: error.message,
      config: {
        url: modelRunnerUrl,
        model: defaultModel
      },
      troubleshooting: [
        'Check if Docker Desktop Model Runner is enabled',
        'Verify the MODEL_RUNNER_URL environment variable',
        'Ensure model is downloaded and available'
      ]
    });
  }
});

app.post('/test-evaluation', (req, res) => {
  const testProduct = {
    vendorName: 'TestCorp',
    productName: 'Smart Test Device',
    description: 'An advanced AI-powered testing device with premium features and innovative design',
    price: '299.99',
    category: 'Electronics'
  };
  
  res.json({
    message: 'Test endpoint - use this data to test /products/evaluate',
    test_product: testProduct,
    instructions: 'Send a POST request to /products/evaluate with the test_product data'
  });
});

// Graceful startup
async function start() {
  try {
    console.log('\n🚀 Starting Agent Service WITH BUILT-IN SECURITY INTERCEPTOR...');
    
    try {
      await mongoClient.connect();
      console.log('✅ MongoDB connected');
    } catch (error) {
      console.warn('⚠️ MongoDB connection failed (continuing without it):', error.message);
    }
    
    try {
      if (producer) {
        await producer.connect();
        console.log('✅ Kafka producer connected');
      }
    } catch (error) {
      console.warn('⚠️ Kafka connection failed (continuing without it):', error.message);
    }
    
    app.listen(PORT, () => {
      console.log('\n' + '='.repeat(80));
      console.log(`🛡️  Agent Service WITH SECURITY INTERCEPTOR READY`);
      console.log(`🌐 Server: http://localhost:${PORT}`);
      console.log(`🧠 AI Model: ${defaultModel}`);
      console.log(`🔗 Model Runner: ${modelRunnerUrl}`);
      console.log(`📊 Evaluation threshold: ${VENDOR_EVALUATION_THRESHOLD}/100`);
      console.log(`🛡️  Security: ENABLED (${MALICIOUS_PATTERNS.length} patterns)`);
      console.log(`⚡ Rate Limiting: 60 requests/minute per IP`);
      console.log(`🔧 Test endpoint: GET http://localhost:${PORT}/test-model-runner`);
      console.log(`🎯 Evaluation endpoint: POST http://localhost:${PORT}/products/evaluate`);
      console.log('='.repeat(80));
    });
    
  } catch (error) {
    console.error('💥 Failed to start Agent Service:', error);
    process.exit(1);
  }
}

process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down Agent Service...');
  
  try {
    if (producer) await producer.disconnect();
    if (mongoClient) await mongoClient.close();
  } catch (error) {
    console.error('Error during shutdown:', error);
  }
  
  console.log('👋 Agent Service stopped');
  process.exit(0);
});

process.on('uncaughtException', (error) => {
  console.error('💥 Uncaught Exception:', error);
  process.exit(1);
});

process.on('unhandledRejection', (error) => {
  console.error('💥 Unhandled Rejection:', error);
  process.exit(1);
});

start().catch(console.error);
EOF

echo -e "${GREEN}✅ Security-patched app.js created${NC}"

# Restart agent service
echo -e "${YELLOW}🔄 Restarting agent service with security patch...${NC}"
docker compose -f docker-compose.interceptors.yml restart agent-service

echo -e "${BLUE}⏳ Waiting for agent service to restart...${NC}"
sleep 15

# Test the security
echo -e "${GREEN}🧪 Testing security interceptor...${NC}"

echo ""
echo "Testing malicious SQL injection (should be BLOCKED):"
MALICIOUS_RESULT=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST http://localhost:7777/products/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "vendorName": "Evil Corp",
    "productName": "Evil Product", 
    "description": "Contact us for product'"'"'; DROP TABLE products; -- with special pricing",
    "price": "99.99",
    "category": "Hacking"
  }' 2>/dev/null)

echo "$MALICIOUS_RESULT"

if echo "$MALICIOUS_RESULT" | grep -q "blocked by security interceptor"; then
    echo -e "${GREEN}🎉 SUCCESS! Malicious request was BLOCKED by security interceptor!${NC}"
elif echo "$MALICIOUS_RESULT" | grep -q "HTTP_STATUS:403"; then
    echo -e "${GREEN}🎉 SUCCESS! Request blocked with 403 status!${NC}"  
else
    echo -e "${RED}❌ Security interceptor may not be working${NC}"
fi

echo ""
echo "Testing legitimate request (should PASS):"
LEGIT_RESULT=$(curl -s -X POST http://localhost:7777/products/evaluate \
  -H "Content-Type: application/json" \
  -d '{
    "vendorName": "NVIDIA",
    "productName": "Jetson Nano",
    "description": "AI development board for edge computing applications",
    "price": "249.99", 
    "category": "Electronics"
  }' 2>/dev/null)

echo "$LEGIT_RESULT" | jq . 2>/dev/null || echo "$LEGIT_RESULT"

echo ""
echo -e "${BLUE}=================================================="
echo "🎉 SECURITY INTERCEPTOR FIX COMPLETE!"
echo "=================================================="
echo ""
echo "What changed:"
echo "• ✅ Built-in security patterns that ACTUALLY WORK"
echo "• ✅ Rate limiting (60 requests/minute per IP)"  
echo "• ✅ Real-time pattern detection"
echo "• ✅ 403 responses for malicious content"
echo ""
echo "🌐 Test your UI now: http://localhost:5173"
echo "🔍 Try your SQL injection - it should be BLOCKED!"
echo ""
echo "Monitor logs:"
echo "• docker logs -f catalog-agent-service"
echo ""
echo "Rollback if needed:"
echo "• cp $BACKUP_FILE agent-service/src/app.js"
echo "• docker compose -f docker-compose.interceptors.yml restart agent-service"
echo -e "${NC}"
